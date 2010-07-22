module MARCSpec
  class Map
    attr_accessor :mapname, :map
    def initialize(mapname, map)
      @mapname = mapname
      @map = map
    end

    def == other
      return ((other.mapname == self.mapname) and (other.map = self.map))
    end
    
    def pretty_print pp
      pp.pp eval(self.asPPString)
    end
    
    # Take the output of pretty_print and eval it to get rawmap; pass it
    # here to get the map object
    def self.fromPPString str
      rawmap = eval(str)
      return self.new(rawmap[:mapname], rawmap[:map])
    end
    
  end
end    