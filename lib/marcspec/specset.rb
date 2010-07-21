module MARCSpec
  class SpecSet
    attr_accessor :tmaps, :fieldspecs
    
    def initialize
      @tmaps = {}
      @fieldspecs = []
    end
    
    def add_map mapname, map
      self.tmaps[mapname] = map
    end
    
    def add_spec solrfieldspec
      self.fieldspecs << solrfieldspec
    end
    
    alias_method :<<, :add_spec
    
    
    
    
  end
end