# Packet - Parent class for everything in the packet subdirectory

module Interlnk
  class Packet
    class Request
      def bytes
        raw.unpack('C*')
      end
    end
  end
end
