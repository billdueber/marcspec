require 'marcspec/map'
require 'pp'




module MARCSpec

  # A KVMap is, when push comes to shove, just a hash with a name, and the 
  # option of adding a default value for each lookup.
  
  class KVMap < Map
    
    # Basic lookup which takes a lookup key and an optional default value,
    # which will be returned iff the map doesn't have
    # the passed key
    #
    # @example
    #   kvmap = MARCSpec::KVMap.new("sample_map", {1=>'one'})
    #   kvmap[1]  #=> 'one'
    #   kvmap[2]  #=> nil
    #   kvmap[2, 'Not Found'] #=> 'Not Found'
    #
    # @param [Object] key The key to look up
    # @param [Object] default The value to return if the lookup fails
    # @return [Object] The value associated with the passed key, or the
    # default value

    def [] key, default=nil
      if @map.has_key? key
        @map[key]
      else
        if default == :passthrough
          return key
        else
          return default
        end
      end
    end    
    
    def []= key, value
      @map[key] = value
    end
    
    alias_method :add, :[]=
    
    def asPPString
      s = StringIO.new
      s.print "{\n :maptype=>:kv,\n :mapname=>"
      PP.singleline_pp(@mapname, s)
      s.print ",\n :map => "
      PP.pp(@map, s)
      s.puts "\n}"
      return s.string
    end
    
        
    def self.from_solrmarc_file filename
      mapname = File.basename(filename).sub(/\..+?$/, '')
      map = {}
      File.open(filename) do |smf|
        smf.each_line do |l|
          l.chomp!
          next unless l =~ /\S/
          l.strip!
          next if l =~ /^#/
          unless l =~ /^(.+?)\s*=\s*(.+)$/
            $LOG.warn "KVMap import skipping weird line in #{filename}\n  #{l}"
            next
          end
          map[$1] = $2
        end
      end
      return self.new(mapname, map)
    end
    
    
  end
end
