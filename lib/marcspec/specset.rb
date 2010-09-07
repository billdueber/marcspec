require 'jruby_streaming_update_solr_server'
require 'marc4j4r'
require 'benchmark'
    

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
    attr_accessor :tmaps, :solrfieldspecs, :benchmarks
    
    # Just get a new, blank object
    def initialize
      @tmaps = {}
      @solrfieldspecs = []
      @benchmarks = {}
    end
    
    # Return the map associated with the given mapname
    # @param [String] mapname The name of the map
    # @return [MARCSpec::Map, nil] The map, or nil if not found
    def map mapname
      return self.tmaps[mapname]
    end
    
    # Load all the maps in a given direcotry
    # @param [String] dir The directory name/path. Uses MARCSpec::Map#fromFile to do the actually loading;
    # that will throw an error if something goes wrong.
    def loadMapsFromDir dir
      unless File.exist? dir
        raise ArgumentError, "Cannot load maps from #{dir}: does not exist"
      end
      Dir.glob("#{dir}/*.rb").each do |tmapfile|
        self.add_map(MARCSpec::Map.fromFile(tmapfile))
      end
    end
    
  
    # Add a map to the maps list. Will index it under its #mapname, overwriting anything already there.
    # @param [MARCSpec::Map] map The map to add
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
      @benchmarks[solrfieldspec.solrField] = Benchmark::Tms.new(0,0,0,0, 0, solrfieldspec.solrField)      
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

    def fill_hashlike_from_marc_benchmark r, hashlike
      @solrfieldspecs.each do |sfs|
        @benchmarks[sfs.solrField] += Benchmark.measure do
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
    end


    def doc_from_marc r, timeit = false
      doc = SolrInputDocument.new
      if timeit
        fill_hashlike_from_marc_benchmark r, doc
      else 
        fill_hashlike_from_marc r, doc
      end
      return doc
    end      
    
    def hash_from_marc r, timeit = false
      h = MARCSpec::MockSolrDoc.new
      if timeit
         fill_hashlike_from_marc_benchmark r, h
       else 
         fill_hashlike_from_marc r, h
       end
      return h
    end
  end
end