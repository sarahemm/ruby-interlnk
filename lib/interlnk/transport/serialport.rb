# SerialPort - transport support for real serial ports

require 'rubyserial'
require 'pp'

module Interlnk
  class Transport
    class SerialPort     
      def initialize(connection_info:)
        @port = connection_info[:port]
        @sock = Serial.new(@port, 9600)
        # flush anything out of the buffer to start
        while(true) do
          data = @sock.read(255)
          break if data == nil or data == ''
        end
      end

      def baud=(new_baud)
        @sock = Serial.new(@port, new_baud)
      end

      def write(bytes)
        @sock.write bytes
      end

      def read(bytes)
        data = ''
        while(data.length < bytes) do
          new_data = @sock.read(bytes)
          data += new_data unless new_data == ''
        end
        
        data
      end
    end
  end
end
