# InterIO - Sits on top of protocol and provides a ruby IO compatible I/O layer

class Array
  def find_duplicates
    # https://stackoverflow.com/questions/15284182/ruby-how-to-find-non-unique-elements-in-array-and-print-each-with-number-of-occ
    self.uniq.
      map { | e | [self.count(e), e] }.
      select { | c, _ | c > 1 }.
      sort.reverse.
      map { | c, e | e }
  end
end

module Interlnk
  class InterIO < IO
    attr_reader :cached_sectors
    
    def initialize(protocol:, unit_nbr:)
      @protocol = protocol
      @unit_nbr = unit_nbr

      # TODO: support non-512-byte sectors
      @sector_size = 512
      @cur_location = 0

      @sector_cache_size = 64
      # keeps the actual cached sector data
      @sector_cache = {}
      # keeps a list of cached sectors, used to remove
      # the oldest from the cache when we need to cache
      # something new
      @cached_sectors = []
      #@refresh_cache
    end

    def seek(offset)
      @cur_location = offset
      #refresh_cache
    end

    def read(length)
      #STDERR.puts "InterIO: Fetching #{length} bytes starting at #{@cur_location}"

      start_byte = @cur_location
      end_byte = @cur_location + length
      start_sector = (start_byte / @sector_size).to_i
      end_sector = ((end_byte-1) / @sector_size).to_i
      #STDERR.puts "SS: #{start_sector} ES: #{end_sector} SL: #{end_sector-start_sector+1}"
      if(end_sector-start_sector > @sector_cache_size) then
        STDERR.puts "Single reads spanning more than the entire sector cache size are not yet supported."
        Kernel.exit 1
      end
      cache_sectors start_sector..end_sector
      
      buf = ""
      (0..length-1).each do |byte_nbr|
        sector_nbr = (@cur_location / @sector_size).to_i
        byte_within_sector = @cur_location - (sector_nbr * @sector_size)
        if(!@sector_cache.include? sector_nbr) then
          STDERR.puts "Uncached sector fetch attempted, aborting."
          Kernel.exit 1
        end
        buf += @sector_cache[sector_nbr][byte_within_sector]
        @cur_location += 1
        #refresh_cache
      end

      buf
    end

    private

    def cache_cleanup
      if(@cached_sectors.find_duplicates != []) then
        puts "InterIO: Double-cached sectors found! #{@cached_sectors.find_duplicates.join(', ')}"
      end
      if(@cached_sectors.length > @sector_cache_size) then
        # discard the oldest cached sector
        @sector_cache.delete @cached_sectors.shift
      end
    end

    def cache_sectors(sector_range)
      all_sectors_cached = true
      some_sectors_cached = false
      sector_range.each do |sector_nbr|
        if(!@cached_sectors.include? sector_nbr) then
          all_sectors_cached = false
          #STDERR.puts "InterIO: Sector #{sector_nbr} IS NOT already cached."
        else
          some_sectors_cached = true
          #STDERR.puts "InterIO: Sector #{sector_nbr} IS already cached."
        end
      end
      return if all_sectors_cached

      if(some_sectors_cached) then
        # cache any chunks that aren't yet cached, individually
        STDERR.puts "InterIO: Partial-caching sector range #{sector_range.to_s}"
        sector_range.each do |sector_nbr|
          next if @cached_sectors.include? sector_nbr
          sector_data = @protocol.get_sectors(unit_nbr: @unit_nbr, start_sector: sector_nbr, nbr_sectors: 1)
          @sector_cache[sector_nbr] = sector_data
          @cached_sectors << sector_nbr
        end
      else
        # cache the whole thing in one big request
        STDERR.puts "InterIO: Chunk-caching sector range #{sector_range.to_s}"
        sector_data = @protocol.get_sectors(unit_nbr: @unit_nbr, start_sector: sector_range.first, nbr_sectors: sector_range.last - sector_range.first + 1)
        sector_nbr = sector_range.first
        sector_data.chars.each_slice(512) do |sector_chunk|
          @sector_cache[sector_nbr] = sector_chunk
          @cached_sectors << sector_nbr
          sector_nbr += 1
        end
      end

      cache_cleanup
    end
  end
end
