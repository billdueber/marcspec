module MARCSpec
  class SpecSet
    attr_accessor :tmaps, :solrfieldspecs
    
    def initialize
      @tmaps = {}
      @fieldspecs = []
    end
    
    def add_map map
      self.tmaps[map.mapname] = map
    end
    
    def add_spec solrfieldspec
      self.solrfieldspecs << solrfieldspec
    end
    
    alias_method :<<, :add_spec
    
    
    
    
  end
end