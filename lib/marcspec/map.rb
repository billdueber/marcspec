module MARCSpec
  
  # A Map is just a named lookup table. The access
  # (via []) takes, in adition to a key, an optional
  # default value to return 
  
  class Map
    attr_accessor :mapname, :map
    
    # Create a new map. The passed map is either
    # a standard hash or a list of duples
    #
    # @param
    def initialize(mapname, map)
      @mapname = mapname
      @map = map
    end

    def self.fromFile filename
      begin
        str = File.open(filename).read
      rescue Exception => e
        $LOG.error "Problem opening #{filename}: #{e.message}"
        raise e
      end
      
      begin 
        rawmap = eval(str)
      rescue Exception => e
        $LOG.error "Problem evaluating (with 'eval') file #{filename}: #{e.message}"
        raise e
      end
      
      case rawmap[:maptype]
      when :kv
        return KVMap.new(rawmap[:mapname], rawmap[:map])
      when :multi
        return MultiValueMap.new(rawmap[:mapname], rawmap[:map])
      else
        $LOG.error "Map file #{filename} doesn't seem to be either a KV map or a MuliValueMap according to :maptype (#{rawmap[:maptype]})"
        raise ArgumentError, "File #{filename} doesn't evaluate to a valid map"
      end
      
    end
      

    def == other
      return ((other.mapname == self.mapname) and (other.map = self.map))
    end
    
    def pretty_print pp
      pp.pp eval(self.asPPString)
    end
    
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