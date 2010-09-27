module MARCSpec
  
  # A Map is just a named lookup table. The access
  # (via []) takes, in adition to a key, an optional
  # default value to return (e.g., val = map[key, defaultIfNotFound])
  #
  # We don't have the default be a part of the map because it might be used
  # in several different contexts.
  #
  # NOTE: THIS IS AN ABSTRACT SUPERCLASS. DO NOT INSTANTIATE IT DIRECTLY
  
  class Map
    include Logback::Simple
    
    attr_accessor :mapname, :map
    
    # Create a new map. The passed map is either a standard hash (KVMap) or a list of duples
    # (for a MultiValueMap)
    #
    # @param [String] mapname The name of this map; can be used to find it later on.
    # @param [Hash, Array] map Either a normal key-value hash (for a KV Map) or an array of duples (2-value arrays) for a MultiValueMap.
    def initialize(mapname, map)
      @mapname = mapname
      @map = map
    end

    # Load a map from a file, determining what kind it is along the way.
    #
    # The file is valid ruby code; see the subclasses KVMap and MutlValueMap for examples.
    #
    # @param [String] filename The name of the map file to be eval'd 
    # @return MARC2Solr::Map An instance of a subclass of MARC2Solr::Map
    
    def self.fromFile filename
      begin
        str = File.open(filename).read
      rescue Exception => e
        log.fatal "Problem opening #{filename}: #{e.message}"
        raise e
      end
      
      begin 
        rawmap = eval(str)
      rescue Exception => e
        log.fatal "Problem evaluating (with 'eval') file #{filename}: #{e.message}"
        raise e
      end
      
      # Derive a name if there isn't one
      unless rawmap[:mapname]
        name = File.basename(filename)
        name.gsub! /\..*$/, '' # remove the extension
        rawmap[:mapname] = name
      end
      
      case rawmap[:maptype]
      when :kv
        return KVMap.new(rawmap[:mapname], rawmap[:map])
      when :multi
        return MultiValueMap.new(rawmap[:mapname], rawmap[:map])
      else
        log.fatal "Map file #{filename} doesn't seem to be either a KV map or a MuliValueMap according to :maptype (#{rawmap[:maptype]})"
        raise ArgumentError, "File #{filename} doesn't evaluate to a valid map"
      end
      
    end
      

    # Check for map equality
    def == other
      return ((other.mapname == @mapname) and (other.map == @map))
    end
    
    # Generic pretty_print; used mostly for translating from solrmarc
    def pretty_print pp
      pp.pp eval(self.asPPString)
    end
    
    # Produce a map from the data structure produced by asPPString
    # @param [Hash] rawmap A hash with two keys; :mapname and :map
    def self.fromHash rawmap
      return self.new(rawmap[:mapname], rawmap[:map])
    end
    
    # Take the output of pretty_print and eval it to get rawmap; pass it
    # tp fromHash to get the map object
    def self.fromPPString str
      rawmap = eval(str)
      return self.fromHash rawmap
    end
    
  end
end    