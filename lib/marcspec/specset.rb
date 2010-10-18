require 'jruby_streaming_update_solr_server'
require 'marc4j4r'
require 'benchmark'
require 'jlogger'
    

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
  
  
  # A collection of the solr field specifications and maps necessary to turn a MARC record
  # into a set of key=>value pairs suitable for sending to Solr
  
  class SpecSet
    include JLogger::Simple
    
    attr_accessor :tmaps, :solrfieldspecs, :benchmarks
    
    # Generic new
    def initialize
      @tmaps = {}
      @solrfieldspecs = []
      @benchmarks = {}
    end
    
    # Get the map object associated with the given name
    # @param [String] name The name of the map you want
    # @return [MARCSpec::Map, nil] Either the map or nil (if not found)
    
    def map name
      return self.tmaps[name]
    end
    
    # Get all the *.rb files in a directory, assume they're maps, and create entries for
    # them in self
    #
    # Simple wrapper around MARCSpec::Map#fromFile. Note that if a mapname is not found
    # in the map structure, the name of the file (without the trailing '.rb') will be used.
    #
    # @param [String] dir The directory to look in. Not recursive.
    
    def loadMapsFromDir dir
      unless File.exist? dir
        raise ArgumentError, "Cannot load maps from #{dir}: does not exist"
      end
      Dir.glob("#{dir}/*.rb").each do |tmapfile|
        self.add_map(MARCSpec::Map.fromFile(tmapfile))
      end
    end
    
  
    # Add a map to self, using its name (map#mapname) as a key
    # @param [MARCSpec::Map] map the map to add.
    def add_map map
      self.tmaps[map.mapname] = map
    end
    
    # Build up a specset from the configuration in the given DSL file
    # Note that this assumes that the maps have already been loaded!!
    #
    # @param [String, IO] f The name of the file, or an open IO object
    # @return [MARCSpec::SpecSet] the new object
    
    
    def buildSpecsFromDSLFile f
      f = File.open(f) if f.is_a? String

      unless f
        log.error("Can't open file #{file}; unable to configure") 
        Process.exit(1)
      end
      self.instance_eval(f.read)
      self.check_and_fill_maps
    end
    
    def check_and_fill_maps
      @solrfieldspecs.each do |sfs|
        if sfs._mapname
          map = self.map(sfs._mapname)
          if map
            log.debug "  Found map #{map.mapname} for solr field #{sfs.solrField}"
            sfs.map = map
          else
            log.error "  Cannot find map #{sfs._mapname} for solr field #{sfs.solrField}"
            Process.exit(1)
          end
        end
      end
    end
      
    
    # Build a specset from the result of eval'ing an old-style pp hash. 
    # @deprecated Use the DSL
    
    def buildSpecsFromList speclist
      speclist.each do |spechash|
        if spechash[:module]
          solrspec = MARCSpec::CustomSolrSpec.fromHash(spechash)
        elsif spechash[:constantValue]
          solrspec = MARCSpec::ConstantSolrSpec.fromHash(spechash)
        else
          solrspec = MARCSpec::SolrFieldSpec.fromHash(spechash)
        end
        if spechash[:mapname]
          map = self.map(spechash[:mapname])
          unless map
            log.error "Cannot find map #{spechash[:mapname]} for field #{spechash[:solrField]}"
            Process.exit(1)
          else
            log.debug "  Found map #{spechash[:mapname]} for field #{spechash[:solrField]}"
            solrspec.map = map
          end
        end
        self.add_spec solrspec
        log.debug "Added spec #{solrspec.solrField}"
      end
    end
      
    
    # Add a spec, making sure there's a slot in the benchmarking stats to keep track of it
    #
    # @param [MARCSpec::SolrFieldSpec] solrfieldspec The spec to add

    def add_spec solrfieldspec
      self.solrfieldspecs << solrfieldspec
      @benchmarks[solrfieldspec.solrField.to_s] = Benchmark::Tms.new(0,0,0,0, 0, solrfieldspec.solrField)      
    end
    
    alias_method :<<, :add_spec


    # Iterate over each of the solr field specs
    def each
      @solrfieldspecs.each do |fs|
        yield fs
      end
    end
    
    # Fill a hashlike (either a hash or a SolrInputDocument) based on 
    # the specs, maps, and passed-in record. 
    #
    # Result is the hashlike getting new data added to it. Nothing is returned; it's all
    # side-effects.
    #
    # @param [MARC4J4R::Record] r The record
    # @param [Hash, SolrInputDocument] hashlike The hash-like object that contains previously-generated content

    
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
    
    # Same as #fill_hashlike_from_marc, but keeps track of how
    # long each solr field takes (cumulative; it's added to every
    # time you get data from a record). 
    #
    # @param [MARC4J4R::Record] r The record
    # @param [Hash, SolrInputDocument] hashlike The hash-like object that contains previously-generated content
    

    def fill_hashlike_from_marc_benchmark r, hashlike
      @solrfieldspecs.each do |sfs|
        @benchmarks[sfs.solrField.to_s] += Benchmark.measure do
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


    # Get a new SolrInputDocument based on the record passed in.
    # Statistics will optionally be kept, and can be accessed
    # via the @benchmarks intance varible later on.
    #
    # @param [MARC4J4R::Record] r The record
    # @param [Boolean] timeit Whether to keep cumulative benchmarking statistics or not
    # @return [SolrInputDocument] Thew new, filled SolrInputDocument    

    def doc_from_marc r, timeit = false
      doc = SolrInputDocument.new
      if timeit
        fill_hashlike_from_marc_benchmark r, doc
      else 
        fill_hashlike_from_marc r, doc
      end
      return doc
    end      
    
    # Exactly the same as #doc_from_marc, but the return object is a 
    # subclass of Hash
    #
    # @param [MARC4J4R::Record] r The record
    # @param [Boolean] timeit Whether to keep cumulative benchmarking statistics or not
    # @return [MockSolrDoc] Thew new, filled Hash    
    
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