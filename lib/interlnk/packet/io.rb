# IO Packet - Handle block I/O reads (and someday writes)

module Interlnk
  class Packet
    class IoRequest < Request
      attr_accessor :unit_nbr, :start_sector, :nbr_sectors
      
      def initialize(unit_nbr: nil, start_sector: nil, nbr_sectors: nil)
        @unit_nbr = unit_nbr
        @media_id = 0xF8
        @start_sector = start_sector
        @nbr_sectors = nbr_sectors
      end

      def raw
        [
          @io_type, @unit_nbr, @media_id, @nbr_sectors, @start_sector, 0
        ].pack('CCCvvV')
      end
    end

    class ReadRequest < IoRequest
      def initialize(unit_nbr: nil, start_sector: nil, nbr_sectors: nil)
        super unit_nbr: unit_nbr, start_sector: start_sector, nbr_sectors: nbr_sectors
        @io_type = 0x04
      end
    end

    class IoAnswer
      attr_accessor :driver_status, :sectors_transferred
      
      def initialize(data)
        (
          @driver_status, @sectors_transferred
        ) = data.unpack('vv')
      end
    end
  end
end

