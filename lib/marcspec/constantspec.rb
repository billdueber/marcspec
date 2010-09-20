require 'marcspec/solrfieldspec'


module MARCSpec
  class ConstantSolrSpec < SolrFieldSpec
    attr_accessor :constantValue
    
    #attr_accessor :solrField, :first, :map, :noMapKeyDefault, :marcfieldspecs, :default, :arity
    
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
    
    def marc_values r, doc = {}
      return @constantValue
    end
    
    def == other
      return @constantValue == other.constantValue
    end
    
    def self.fromHash h
      return self.new(h)
    end
    
    def asDSLString
      return "constant('#{@solrField}') do\n  value #{@constantValue.inspect}\nend"
    end
    
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
      
      
    