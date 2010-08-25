require 'marcspec/map'
require 'pp'




module MARCSpec

  # A KVMap is, when push comes to shove, just a hash with a name, and the 
  # option of adding a default value for each lookup.
  #
  # The map portion of a kvmap is simply a hash.
  
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
    
    # Set an element in the map, just like for a regular hash
    def []= key, value
      @map[key] = value
    end
    
    alias_method :add, :[]=
    
    
    # Produce a configuration file that will round-trip to this object.
    #
    # @return [String] A string representation of valid ruby code that can be turned back into 
    # this object using MARCSpec::Map#fromFile
    def asPPString
      s = StringIO.new
      s.print "{\n :maptype=>:kv,\n :mapname=>"
      PP.singleline_pp(@mapname, s)
      s.print ",\n :map => "
      PP.pp(@map, s)
      s.puts "\n}"
      return s.string
    end
    
    
    # Translate from a solrmarc map file that has *already been determined* to be a KV map
    #
    # Uses the underlying java Properties class to avoid having to rewrite all the esacping 
    # logic.
    #
    # @param [String] filename The path to the solrmarc kv map file
    # @return [MARCSpec::KVMap] a KVMap
    
    def self.from_solrmarc_file filename
      mapname = File.basename(filename).sub(/\..+?$/, '')
      map = {}
      File.open(filename) do |smf|
        prop = Java::java.util.Properties.new
        prop.load(smf.to_inputstream)
        prop.each do |k,v|
          map[k] = v
        end
      end
      return self.new(mapname, map)
    end
            
    
    
  end
end
