require 'marcspec/solrfieldspec'


module MARCSpec
  
  # A ConstantSolrSpec always returns the same value(s) no matter what's in the record.
  class ConstantSolrSpec < SolrFieldSpec
    attr_accessor :constantValue
    
    
    def initialize opts = {}
      @solrField  = opts[:solrField]
      @constantValue = opts[:constantValue]
      @arity = 1
      
      # Check to make sure we didn't get anything else and warn if need be
      [:firstOnly, :mapname, :noMapKeyDefault, :specs, :default, :module, :functionSymbol].each do |s|
        if opts[s] 
          raise ArgumentError, "#{s} is not a valid option for Constant spec (one with :constantValue defined)"
        end
      end
    end
    
    # Return the constant value associated with this spec
    # @param [MARC4J4R::Record] r The record. IGNORED. It's a constant ;-)
    # @param [Hash, SolrInputDocument] doc The hash-like object that contains previously-generated content. IGNORED
    # @return [String, Array] The constant value(s) associated with this object.
    
    def marc_values r, doc = {}
      return @constantValue
    end
    
    # Basic equality
    def == other
      return @constantValue == other.constantValue
    end
    
    # Build up from a ruby hash
    # @deprecated Use the DSL
    def self.fromHash h
      return self.new(h)
    end
    
    def asDSLString
      return "constant('#{@solrField}') do\n  value #{@constantValue.inspect}\nend"
    end
    
    # Used to round-trip to/from hash syntax
    # @deprecated Use the DSL
    def asPPString
      s = StringIO.new
      s.print "{\n :solrField=> "
      PP.singleline_pp(@solrField, s)
      s.print(",\n ")
      s.print ":constantValue => "
      PP.singleline_pp(@constantValue, s)
      s.print "\n}"
      return s.string
    end
    
  end
end
      
      
    