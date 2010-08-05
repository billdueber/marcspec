require 'jruby_streaming_update_solr_server'
module MARCSpec
  class SpecSet
    attr_accessor :tmaps, :solrfieldspecs
    
    def initialize
      @tmaps = {}
      @solrfieldspecs = []
    end
    
    def map name
      return self.tmaps[name]
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
    
    def fill_hashlike_from_marc r, hashlike
      @solrfieldspecs.each do |sfs|
        vals = sfs.marc_values(r)
        hashlike[sfs.solrField] = vals
       end  
    end

    def doc_from_marc r
      doc = SolrInputDocument.new
      fill_hashlike_from_marc r, doc
      return doc
    end      
    
    def hash_from_marc r
      h = {}
      fill_hashlike_from_marc r, h
      return h
    end
  end
end