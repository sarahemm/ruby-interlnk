# Client - user-facing interface with the library, uses Protocol to execute commands

require 'pp'

module Interlnk
  class Client
    class NoSuchDriveException < StandardError
    end

    class Drive
      attr_reader :drive_number

      def initialize(protocol: nil, drive_number: nil)
        @protocol = protocol
        @drive_number = drive_number
        @info = @protocol.get_drive_info(drive_number)
      end

      def drive_letter
        (@drive_number + 65).chr
      end

      def size
        # we return the size in text, since that's how we get it
        @info.size
      end

      def volume_label
        @info.volume_label
      end

      def bpb
        @protocol.get_bpb(@drive_number)
      end

      def interio
        InterIO.new protocol: @protocol, unit_nbr: @drive_number
      end

      def ready?
        # TODO: we should probably do a real media check to see if it's ready
        @info.size != ''
      end
    end

    def initialize(transport:, channel:, connection_info: nil)
      @transport = transport.new(connection_info: connection_info)
      @channel = channel.new(transport: @transport)
      @protocol = Protocol.new(channel: @channel)
    end

    def drives
      drives = {}
      @protocol.init_info.drive_map.each do |drive_number|
        drive = Drive.new(protocol: @protocol, drive_number: drive_number)
        drives[drive.drive_letter] = drive
      end

      drives
    end

    def idle
      # exchange one set of idle packets
      # this keeps our connection from timing out
      @protocol.idle
    end
  end
end
