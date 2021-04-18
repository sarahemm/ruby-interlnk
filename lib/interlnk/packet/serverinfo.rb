# ServerInfo Packet - Exchange software information (similar to Init packets but different info)

module Interlnk
  class Packet
    class ServerInfoRequest < Request
      attr_accessor :os_type, :developer, :product
      attr_accessor :version, :device_driver
      attr_accessor :want_supported, :max_ser_block
      attr_accessor :client_id, :last_server_id

      def initialize
        @os_type = 0
        @developer = 0
        @product = 0
        @version = 0x100
        @device_driver = 1
        @want_supported = 0
        @checksum = 0
        @crc = 1
        @max_ser_block = 8192
        @client_id = rand(0xFFFF)
        @last_server_id = 0
      end

      def raw
        [
          @os_type, @developer, @product, @version,
          @device_driver, @want_supported, @checksum, @crc,
          @max_ser_block, '', @client_id, @last_server_id
        ].pack('vvvvCCCCva12VV')
      end
    end

    class ServerInfoAnswer
      attr_accessor :os_type, :developer, :product
      attr_accessor :version, :device_server
      attr_accessor :want_supported, :max_ser_block
      attr_accessor :last_client_id, :server_id

      def initialize(data)
        (
          @os_type, @developer, @product, version,
          @device_server, @checksum, @crc,
          @max_ser_block, reserved, @last_client_id, @server_id
        ) = data.unpack('vvvvCCCva12VV')
        @version = "#{(version & 0xFF00) >> 8}.#{version & 0xFF}"
      end
    end
  end
end

