# BPB Packet - Request and provide BIOS Parameter Blocks

module Interlnk
  class Packet
    class BpbRequest < Request
      attr_accessor :unit_nbr, :media_id
      
      def initialize(unit_nbr: nil)
        @unit_nbr = unit_nbr
        @media_id = 0xF8
      end

      def raw
        [
          0x03, @unit_nbr, @media_id
        ].pack('CCC')
      end
    end

    class BpbAnswer
      attr_accessor :driver_status, :bpb
      
      def initialize(data)
        (
          @driver_status, @bpb
        ) = data.unpack('va*')
      end
    end
  end
end

