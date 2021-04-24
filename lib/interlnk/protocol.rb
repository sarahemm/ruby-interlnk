# Protocol - higher-level client protocol (using Channel for the actual comms)

require 'pp'

module Interlnk
  class Protocol
    attr_reader :server_info, :init_info

    def initialize(channel:)
      @channel = channel
      @channel.connect
      @channel.baud = 115200
      @server_info = get_server_info
      @init_info = do_init
    end

    def debug=(debug_state)
      @channel.debug = debug_state
    end

    def get_server_info
      sir = Packet::ServerInfoRequest.new
      @channel.send_packet([0x00, 0x00]) # packet type: server_info_request
      @channel.send_packet(sir.bytes)

      # now we need to get ready to receive the SIR data
      @channel.channel_turnaround_to_recv

      @channel.receive_packet(type: Packet::ServerInfoAnswer)
    end

    def do_init
      @channel.channel_turnaround_to_send
      initr = Packet::InitRequest.new
      @channel.send_packet initr.bytes

      @channel.channel_turnaround_to_recv
      # TODO: do something with the mappings received
      @channel.receive_packet(type: Packet::InitAnswer)
    end

    def get_drive_info(drive_nbr)
      @channel.channel_turnaround_to_send
      # TODO: convert this to a proper request packet type
      @channel.send_packet([0x1C, drive_nbr]) # packet type: drive_info_request
      @channel.channel_turnaround_to_recv
      @channel.receive_packet(type: Packet::DriveInfoAnswer)
    end

    def get_bpb(drive_nbr)
      @channel.channel_turnaround_to_send
      bpbr = Packet::BpbRequest.new(unit_nbr: drive_nbr)
      @channel.send_packet bpbr.bytes
      @channel.channel_turnaround_to_recv
      @channel.receive_packet(type: Packet::BpbAnswer).bpb
    end

    def get_sectors(unit_nbr: nil, start_sector: nil, nbr_sectors: nil)
      @channel.channel_turnaround_to_send
      readr = Packet::ReadRequest.new(unit_nbr: unit_nbr, start_sector: start_sector, nbr_sectors: nbr_sectors)
      @channel.send_packet readr.bytes
      @channel.channel_turnaround_to_recv
      # TODO: look at the answering status to make sure it worked
      @channel.receive_packet(type: Packet::IoAnswer)

      @channel.request_more_data
      # get the actual sector data
      @channel.receive_packet
    end

    def idle
      @channel.perform_idle
    end
  end
end
