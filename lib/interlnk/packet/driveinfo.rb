# DriveInfo Packet - Request and provide info on available drives

module Interlnk
  class Packet
    class DriveInfoAnswer
      attr_accessor :size, :volume_label
      
      def initialize(data)
        (
          @size, @volume_label, @write_protected
        ) = data.unpack('Z10Z12C')
      end

      def write_protected?
        @write_protected != 0
      end
    end
  end
end

