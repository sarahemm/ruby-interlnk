# TCPTransport - transport support for TCP connections

require 'socket'

module Interlnk
  class Transport
    class Tcp      
      def initialize(connection_info:)
        @sock = TCPSocket.new connection_info[:host], connection_info[:port]
      end

      def baud=(new_baud)
        # no concept of baud for this transport, so nothing to do!
      end

      def write(bytes)
        @sock.write bytes
      end

      def read(bytes)
        @sock.read bytes
      end
    end
  end
end
