module MARCSpec
  class KVMap   
    def initialize(map, default=nil)
      @default = default
      @map = map
      unless (@default.nil?)
        @map.default = @default
      end
    end
    
    def [] key
      @map[key]
    end
  end
end
