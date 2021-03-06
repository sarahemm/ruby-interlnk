# SerialChannel - low level communications routines for serial channels, used by Protocol

class Fixnum
  def invert_bits(width:)
    # TODO: figure out doing this with math instead of strings
    self.to_s(2).rjust(width, '0').gsub(/[01]/, {'0' => '1', '1' => '0'}).to_i(2)
  end
end

module Interlnk
  class Channel
    class Serial
      attr_accessor :debug

      SPEED_INDEXES = {
        1200   => 0,
        2400   => 1,
        4800   => 2,
        9600   => 3,
        19200  => 4,
        38400  => 5,
        57600  => 6,
        115200 => 7
      }
    
      class ProtocolException < StandardError
      end

      def initialize(transport:)
        @transport = transport
        @debug = false
        @next_seqnbr = 0
    
        @next_needs_seqflags = true
      end
    
      def connect
        # do the initial sync handshake
        send_and_expect send: 0xaa, expect: 0x00
        send_and_expect send: 0x55, expect: 0xff
        send_and_expect send: 0x5a, expect: 0x11
      end
    
      def baud=(baud)
        # set the baud rate
        send_and_expect send: 0xff, expect: 0x00
        send_and_expect send: SPEED_INDEXES[baud], expect: SPEED_INDEXES[baud] << 4
        
        # TODO: I believe if this was real serial we'd change baud rates now
        # but it's possible we have to change between the send and expect in the above
    
        # send shifted baud rate again, expect inverse
        send_and_expect send: SPEED_INDEXES[baud]<<4, expect: (SPEED_INDEXES[baud]<<4).invert_bits(width: 8)
    
        # send/receive a bunch of pre-defined bytes 
        # presumably to make sure the new baud rate is working?
        verify_send_seq = [0xff, 0x00, 0x5a, 0x55, 0xaa, 0xf0, 0x0f, 0xe7, 0x7e, 0xc3, 0x3c, 0x81, 0x18, 0x00, 0xff]
        verify_recv_seq = [0x00, 0xff, 0xa5, 0xaa, 0x55, 0xf0, 0x0f, 0xff, 0x00, 0x18, 0x81, 0x3c, 0xc3, 0x7e, 0xe7]
    
        verify_send_seq.each_index do |idx|
          send_and_expect send: verify_send_seq[idx], expect: verify_recv_seq[idx]
        end
      end
    
      def send_packet(data)
        puts "Sending #{data.length} byte packet (#{@next_needs_seqflags ? "with" : "no"} seq/flags)." if @debug
        seq_flags = send_flags_seq(packet_length: data.length) if @next_needs_seqflags
        @next_needs_seqflags = true
    
        crc = Crc.new
    
        # send length
        # TODO: support 'word-length' packets, not just 'byte-length'
        printf "SL> 0x%02X\n", data.length if @debug
        crc << data.length
        @transport.write [data.length].pack('C')
    
        # send the packet data itself
        print "SD> " if @debug
        data.each do |datum|
          printf "0x%02X ", datum if @debug
          crc << datum
        end
        print "\n" if @debug
        @transport.write data.pack('C*')
    
        # send the CRC
        crc_low = crc.result & 0x00FF
        crc_high = (crc.result & 0xFF00) >> 8
        printf "SC> 0x%02X 0x%02X\n", crc_high, crc_low if @debug
        @transport.write [crc_high, crc_low].pack('CC')
        
        if(seq_flags) then
          expect(seq_flags)
        else
          expect(@last_seq_flags)
        end
      end
      
      def channel_turnaround_to_recv
        @next_needs_seqflags = true
        this_seqnbr = next_seqnbr
        ack = (@last_seq_flags & 0xFC) | this_seqnbr
        send_and_expect send: this_seqnbr, expect: ack
    
        # TODO: 0x80 probably shouldn't be hardcoded for the length flag
        send calculate_ack_for(this_seqnbr | 0x80)
        
        @last_seq_flags = ack
      end
    
      def channel_turnaround_to_send
        # we don't need to do seq/flags right after this turnaround
        @next_needs_seqflags = false
    
        this_seqnbr = next_seqnbr
        ack = (@last_seq_flags & 0xFC) | this_seqnbr
        send ack
    
        what = @transport.read(1).unpack('C')[0] # TODO: validate this, don't just ignore it
        printf "CT< 0x%02X\n", what if @debug
        @last_seq_flags = ack
      end
    
      def receive_packet(type: nil)
        packet_length = @transport.read(1).unpack('C')[0]
        packet_length_bytes = [packet_length]
        length_type = :byte
        if(packet_length == 0) then
          # packet is larger than 255 bytes, get the MSB now
          # TODO: first length byte of 00 isn't the right way
          #       to identify this, but it works for now
          length_type = :word
          packet_length_msb = @transport.read(1).unpack('C')[0]
          packet_length_bytes << packet_length_msb
          packet_length = packet_length | (packet_length_msb << 8)
        end
        puts "\nReceiving #{packet_length} byte packet." if @debug
        printf "RL< 0x%02X\n", packet_length if @debug
        packet_data = @transport.read(packet_length+2)
        crc = Crc.new()
        packet_length_bytes.each { |byte| crc << byte }
        print "RD< " if @debug
        packet_data.each_byte do |datum|
          printf "0x%02X ", datum if @debug
          crc << datum
        end
    
        print "\n" if @debug
        # TODO: retry, don't just give up
        raise ProtocolException, "Bad CRC, aborting." unless crc.residue_ok?
        puts "CRC OK" if @debug
    
        ack_byte = @last_seq_flags
        ack_byte &= ~0x80 if length_type == :word
        send_and_expect send: ack_byte, expect: @next_seqnbr
    
        # trim off the CRC
        packet_data = packet_data[0..-3]
        if(type)
          return type.new packet_data
        else
          return packet_data
        end
      end

      def request_more_data
        # TODO: I don't fully understand how this works
        #       It seems that for read_data we send another
        #       ack after the ack-ack from the status answer
        #       to get the server to send the data part?
        send calculate_ack_for(@next_seqnbr)
        @last_seq_flags = next_seqnbr | 0x80
      end

      def perform_idle
        idle_byte = 0xFC | (@next_seqnbr ^ 0x01)
        send_and_expect send: idle_byte, expect: idle_byte
      end

      #private

      def calculate_ack_for(input)
        # this is weird but it's just how ack bytes work for seq/flags
        input ^ 0xFF & 0xFB
      end

      def send_flags_seq(packet_length:)
        length_flag = 0x80
        if(packet_length > 0xFF) then
          raise ProtocolException, "Word-length packets are not yet supported."  
        end
        seqnbr = next_seqnbr
        seq_flags = seqnbr | length_flag
        # TODO: support other flags
    
        ack_byte = calculate_ack_for(seq_flags)
        send_and_expect send: seq_flags, expect: ack_byte
    
        @last_seq_flags = seq_flags
        seq_flags
      end

      def next_seqnbr
        this_seqnbr = @next_seqnbr
        @next_seqnbr = @next_seqnbr += 1
        # roll sequence number around after 3 since it's only 2 bits wide
        @next_seqnbr = 0 if @next_seqnbr >= 4
    
        this_seqnbr
      end
      
      def send_and_expect(send:, expect:)
        send(send)
        expect(expect)
      end
    
      def expect_and_send(expect:, send:)
        expect(expect)
        send(send)
      end
    
      def send(send)
        puts "SE> 0x#{send.to_s(16).rjust(2, '0')} (seq bits #{(send & 0x03).to_s(2).rjust(2, '0')})" if @debug
        @transport.write [send].pack('C')
      end
    
      def expect(expect)
        response = @transport.read(1).unpack('C')[0]
        puts "SE< 0x#{response.to_s(16).rjust(2, '0')} (seq bits #{(response & 0x03).to_s(2).rjust(2, '0')})" if @debug
        if(response != expect) then
          raise ProtocolException, "Expected 0x#{expect.to_s(16).rjust(2, '0')}, got 0x#{response.to_s(16).rjust(2, '0')}"
        end
      end
    end
  end
end
