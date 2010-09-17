require 'marcspec/map'
require 'marcspec/solrfieldspec'


module MARCSpec

  # A CustomSolrSpec is a SolrFieldSpec that derives all its values from a custom function. The custom function
  # must me a module function that takes a hash-like document object, a MARC4J4R record, and an array of other arguments and returns a 
  # (possibly empty) list of resulting values.
  #
  # See the example file simple_sample/index.rb in the marc2solr project for configuration examples.
  #
  # @example A sample custom function, to be placed in the configuration directory's lib/ subdir
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
  # @example A simple custom spec made by hand
  # css = MARCSpec::CustomSolrSpec.new(:module => MARC2Solr::MyCustomStuff,
  #                                    :functionSymbol => :uppercaseTitle,
  #                                    :map => ss.map('mapname')
  #                                   )
  #
  # 
  

  class CustomSolrSpec < SolrFieldSpec
    
    attr_accessor :module, :functionSymbol, :functionArgs
    
    # Get a new Custom Solr Spec based on the passed in options. 
    # @param [Hash] opts Initialization options
    # @option opts [String, Array<String>] :solrField the name(s) of the Solr field(s) that will receive the data derived from this spec
    # @option opts [Module] :module the actual module constant (not a string or symbol representation) which holds the 
    # custom function we'll be calling
    # @option opts [Symbol] :functionSymbol A symbol of the name of the custom function
    # @option opts [Boolean] :firstOnly (false) Whether we should return the first found value
    # @option opts [String] :default (nil) The value to return if the custom function returns no values
    # @option opts [MARC2Solr::Map] :map (nil) An optional Map used to translate resulting values
    # @option opts [String] :noMapKeyDefault (nil) The value to return if (a) a value is found, (b) a map is defined, but (c) there's
    # no key in the map that matches the value. 
    #
    # Note that the last four options don't make sense if multiple :solrFields are given, and are illegal in that case.
    
    def initialize(opts)
      @solrField  = opts[:solrField]
      @module = opts[:module] || nil
      @functionSymbol = opts[:functionSymbol] || nil

      @functionArgs = opts[:functionArgs] || []
      
      @first = opts[:firstOnly] || false      
      @defaultValue = opts[:default] || nil
      @map = opts[:map] || nil
      @noMapKeyDefault = opts[:noMapKeyDefault] || nil
      
      if @solrField.is_a? Array
        @arity = @solrField.size
        if @first or @defaultValue or @map or @noMapKeyDefault 
          raise ArgumentError, "Custom spec with multiple solrFields can't have :first, :map, :default, or :noMapKeyDefault set"
        end
      else
        @arity = 1
      end
      
      
    end
    
    # Get values from a MARC object and/or the prevously-filled document object.
    #
    # Note that the doc is read-write here, but for the love of god, just leave it alone.
    #
    # @param [MARC4J4R::Record] r A marc record
    # @param [SolrInputDocument, Hash] doc The document we're constructing. 
    # @return [Array<String>] An array of values returned by the custom method
    
    def raw_marc_values r, doc
      return @module.send(@functionSymbol, doc, r, *@functionArgs)
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
      if @defaultValue
        s.print(":default => ")
        PP.singleline_pp(@defaultValue, s)
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
      s.print(",\n :functionSymbol => ")
      PP.singleline_pp(@functionSymbol, s)
      if @functionArgs
        s.print(",\n :functionArgs => ")
        PP.singleline_pp(@functionArgs, s)
      end
      s.print "\n}"
      return  s.string
    end
    
  end
end
    