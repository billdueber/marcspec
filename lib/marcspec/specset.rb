require 'jruby_streaming_update_solr_server'


    

module MARCSpec

  # Create a mock solr document based on a normal hash for mocking.
  # All we really need is a compatible add method
  class MockSolrDoc < Hash
    def add key, value
      if self.has_key? key
        self[key] << value
      else
        self[key] = [value]
      end
      self[key].flatten!      
    end

    def additive_merge! hashlike
      hashlike.each  do |k, v|
        self.add(k, v)
      end
    end
    
  end

  class SpecSet
    attr_accessor :tmaps, :solrfieldspecs
    
    def initialize
      @tmaps = {}
      @solrfieldspecs = []
    end
    
    def map name
      return self.tmaps[name]
    end
    
    def loadMapsFromDir dir
      unless File.exist? dir
        raise ArgumentError, "Cannot load maps from #{dir}: does not exist"
      end
      Dir.glob("#{dir}/*.rb").each do |tmapfile|
        self.add_map(MARCSpec::Map.fromFile(tmapfile))
      end
    end
    
  
    
    def add_map map
      self.tmaps[map.mapname] = map
    end
    
    
    def buildSpecsFromList speclist
      speclist.each do |spechash|
        if spechash[:module]
          solrspec = MARCSpec::CustomSolrSpec.fromHash(spechash)
        else
          solrspec = MARCSpec::SolrFieldSpec.fromHash(spechash)
        end
        if spechash[:mapname]
          map = self.map(spechash[:mapname])
          unless map
            $LOG.error "  Cannot find map #{spechash[:mapname]} for field #{spechash[:solrField]}"
          else
            $LOG.debug "  Found map #{spechash[:mapname]} for field #{spechash[:solrField]}"
            solrspec.map = map
          end
        end
        self.add_spec solrspec
        $LOG.debug "Added spec #{solrspec.solrField}"
      end
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
        if sfs.arity == 1
          hashlike.add(sfs.solrField,sfs.marc_values(r, hashlike))
        else 
          vals = sfs.marc_values(r, hashlike)
          (0..(sfs.arity - 1)).each do |i|
            hashlike.add(sfs.solrField[i], vals[i])
          end
        end
      end
    end

    def doc_from_marc r
      doc = SolrInputDocument.new
      fill_hashlike_from_marc r, doc
      return doc
    end      
    
    def hash_from_marc r
      h = MARCSpec::MockSolrDoc.new
      fill_hashlike_from_marc r, h
      return h
    end
  end
end