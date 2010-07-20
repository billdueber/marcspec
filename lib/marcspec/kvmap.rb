module MARCSpec
  class KVMap 
    def initialize(map)
      @map = map
    end
    
    def [] key, default=nil
      if @map.has_key? key
        @map[key]
      else
        default
      end
    end
  end
end
