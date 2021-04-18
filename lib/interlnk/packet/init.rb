# Init packet - Exchange basic client/server information

module Interlnk
  class Packet
    class InitRequest < Request
      attr_accessor :version, :dos_version, :max_devices
      attr_accessor :first_unit, :prn_map, :drive_map

      def initialize(max_drives: 26)
        @version = '1.00'
        @dos_version = '6.22'
        @max_devices = max_drives
        # our available units start at 0
        # this makes drive letters on our side start at A:
        @first_unit = 0 
        # 0xFE (probably -1?) means "nothing in this unit"
        @prn_map = [0xFE, 0xFE, 0xFE]
        # map of which slots are available on our side
        @drive_map = [].fill(0xFE, 0, max_drives)
        # TODO: we don't reserve any unit numbers right now
        # which means that A: and C: on the remote end are
        # A: and B: on our end for example, should fix this
      end

      def raw
        (major_version, minor_version) = @version.split('.')
        (dos_major_version, dos_minor_version) = @dos_version.split('.')
        
        [
          1, # packet type 1 = INIT
          major_version.to_i, minor_version.to_i,
          dos_minor_version.to_i, dos_major_version.to_i,
          @max_devices, @first_unit, @prn_map, @drive_map
        ].flatten.pack("CCCCCCCC3C#{@max_devices}")
      end
    end

    class InitAnswer
      attr_accessor :version, :dos_version, :prn_map, :drive_map
      
      def initialize(data)
        (
          major_version, minor_version,
          dos_minor_version, dos_major_version,
          nbr_devices, @prn_map, drive_map,
          attributes, multitasking_flag
        ) = data.unpack('CCCCCa3a26a52C')
        @version = "#{major_version}.#{minor_version}"
        @dos_version = "#{dos_major_version}.#{dos_minor_version}"
        @drive_map = []
        idx = 0
        drive_map.each_byte do |map|
          @drive_map[idx] = map unless map == 0xFE
          idx += 1
        end
      end
    end
  end
end
