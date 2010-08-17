require 'marcspec/map'
require 'marcspec/solrfieldspec'


module MARCSpec

  # A CustomSolrSpec is a SolrFieldSpec that derives all its values from a custom function. The custom function
  # must me a module function that takes a record and an array of other arguments and returns a 
  # (possibly empty) list of resulting values.
  #
  # @example
  #  module MARC2Solr
  #   module MyCustomStuff
  #     def self.uppercaseTitle r, args=[]
  #       vals = []
  #       vals.push r['245'].value.upcase
  #       return vals
  #     end
  #   end
  # end
  #
  # css = MARCSpec::CustomSolrSpec.new(:module => MARC2Solr::MyCustomStuff,
  #                                    :methodSymbol => :uppercaseTitle,
  #                                    :map => ss.map('mapname')
  #                                   )
  # ss.add_spec(css)
  #
  # 
  

  class CustomSolrSpec < SolrFieldSpec
    
    attr_accessor :module, :methodSymbol, :methodArgs
    def initialize(opts)
      @solrField  = opts[:solrField]
      @module = opts[:module]
      @methodSymbol = opts[:methodSymbol]

      unless @solrField and @module and @methodSymbol
        raise ArgumentError, "Custom solr spec must have a field name in :solrField, module in :module, and the method name as a symbol in :methodSymbol"
      end
      
      
      @methodArgs = opts[:methodArgs] || []
      
      @first = opts[:firstOnly] || false      
      @default = opts[:default] || nil
      @map = opts[:map] || nil
      @noMapKeyDefault = opts[:noMapKeyDefault] || nil
      
      if @solrField.is_a? Array
        @arity = @solrField.size
        if @first or @default or @map or @noMapKeyDefault 
          raise ArgumentError, "Custom spec with multiple solrFields can't have :first, :map, :default, or :noMapKeyDefault set"
        end
      else
        @arity = 1
      end
      
      
    end
    
    
    def raw_marc_values r, doc
      return @module.send(@methodSymbol, doc, r, *@methodArgs)
    end
    
    def self.fromHash h
      return self.new(h)
    end
  
    
    def asPPString
      s = StringIO.new
      s.print "{\n :solrField=> "
      PP.singleline_pp(@solrField, s)
      s.print(",\n ")
      s.print ":firstOnly => true,\n " if @first
      if @default
        s.print(":default => ")
        PP.singleline_pp(@default, s)
        s.print(",\n ")
      end
      if @map
        s.print(":mapname => ")
        PP.singleline_pp(@map.mapname, s)
        s.print(",\n ")
      end
      if @noMapKeyDefault
        s.print(":noMapKeyDefault => ")
        PP.singleline_pp(@noMapKeyDefault, s)
        s.print(",\n ")
      end
      
      s.print(":module => ")
      PP.singleline_pp(@module, s)
      s.print(",\n :methodSymbol => ")
      PP.singleline_pp(@methodSymbol, s)
      if @methodArgs
        s.print(",\n :methodArgs => ")
        PP.singleline_pp(@methodArgs, s)
      end
      s.print "\n}"
      return  s.string
    end
    
  end
end
    