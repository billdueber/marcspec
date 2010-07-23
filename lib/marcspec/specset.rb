module MARCSpec
  class SpecSet
    attr_accessor :tmaps, :solrfieldspecs
    
    def initialize
      @tmaps = {}
      @solrfieldspecs = []
    end
    
    def add_map map
      self.tmaps[map.mapname] = map
    end
    
    def add_spec solrfieldspec
      self.solrfieldspecs << solrfieldspec
    end
    
    alias_method :<<, :add_spec

    def each
      @solrfieldspecs.each do |fs|
        yield fs
      end
    end

    def doc_from_marc r
      doc = SolrInputDocument.new
      @solrfieldspecs.each do |fs|
        doc[fs.field] = fs.marc_values(r)
      end
      return doc
    end      
    
    def hash_from_marc r
      h = {}
      @fieldspecs.each do |fs|
       h[fs.field] = fs.marc_values(r)
      end
      return h
    end
  end
end