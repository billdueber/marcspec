require 'stringio'
require 'marc4j4r/controlfield'

module MARCSpec
  
  
  # The basic Solr Field spec -- a specification object that knows how to extract data
  # from a MARC record.
  
  class SolrFieldSpec
    attr_accessor :solrField, :first, :map, :noMapKeyDefault, :marcfieldspecs, :defaultValue,  :_mapname
    attr_reader :arity

    # Get a new object
    
    def initialize(opts)
      @solrField  = opts[:solrField]
      @first = opts[:firstOnly] || false      
      @defaultValue = opts[:default] || nil
      @map = opts[:map] || nil
      @noMapKeyDefault = opts[:noMapKeyDefault] || nil
      @arity = 1
      @marcfieldspecs = []
    end

    # Add a new tag specification
    # @param [MARCSpec::ControlFieldSpec, MARCSpec::VariableFieldSpec] tagspec The spec to add
    
    def << tagspec
      @marcfieldspecs << tagspec
    end

    # Get raw (not translated by a map or anything) values from the MARC
    #
    # @param [MARC4J4R::Record] r The record
    # @param [Hash, SolrInputDocument] doc The hash-like object that contains previously-generated content
    # @return [Array] an array of values from the MARC record
    
    def raw_marc_values r, doc
      vals = []
      @marcfieldspecs.each do |ts|
        vals.concat ts.marc_values(r)
      end
      return vals
    end
    
    # Get the values from the MARC, provide a default or mapping as necessary
    #
    # @param [MARC4J4R::Record] r The record
    # @param [Hash, SolrInputDocument] doc The hash-like object that contains previously-generated content
    # @return [Array] an array of values from the MARC record after mapping/default/mapMissDefault/firstOnly
 
    def marc_values r, doc = {}
      vals = raw_marc_values r, doc
      return vals if @arity > 1
      unless vals.is_a? Array
        vals = [vals]
      end
      
      if @first
        vals = [vals.compact.first].compact
      end

      # If we got nothing, just return either nothing or the defualt,
      # if there is one. Don't screw around with mapping.
      if vals.size == 0
        if @defaultValue.nil? # unless there's a default value, just return nothing
          return []
        else
          return [@defaultValue]
        end
      end
      
      # If we've got a map, map it.

      if (@map)
        vals.map! {|v| @map[v, @noMapKeyDefault]}
      end
      
      # Flatten it all out
      
      vals.flatten!
      vals.uniq!
      vals.compact!
      return vals
    end
    
    # Basic equality
    # @param [MARCSpec::SolrFieldSpec] other The other object to compare to
    # @return [Boolean] whether it's the same
    
    def == other
      return ((other.solrField == self.solrField) and
             (other.first == self.first) and
             (other.map == self.map) and
             (other.defaultValue == self.defaultValue) and
             (other.noMapKeyDefault == self.noMapKeyDefault) and
             (other.marcfieldspecs == self.marcfieldspecs))
    end
    
    # Build an object from a asPPString string
    # @deprecated Use the DSL
    def self.fromPPString str
      return self.fromHash eval(str)
    end
    
    # Build an object from an eval'd asPPString string
    # @deprecated Use the DSL
    
    def self.fromHash h
      sfs = self.new(h)
      h[:specs].each do |s|
        if MARC4J4R::ControlField.control_tag? s[0]
          sfs << MARCSpec::ControlFieldSpec.new(*s)
        else
          sfs << MARCSpec::VariableFieldSpec.new(s[0], s[1], s[2])
        end
      end
      return sfs
    end
    
    # Output as a ruby hash
    # @deprecated Use the DSL
        
    def pretty_print pp
      pp.pp eval(self.asPPString)
    end
    
    # Create a string representation suitable for inclusion in a DSL file
    # @return [String] a DSL snippet
    def asDSLString
      s = StringIO.new
      s.puts "field('#{@solrField}') do"
      s.puts "  firstOnly" if @first
      if @defaultValue
        s.puts "  default " + 
        PP.singleline_pp(@defaultValue + "\n", s)
      end
      if @map
        s.print "  mapname "
        PP.pp(@map.mapname, s)
      end
      if @noMapKeyDefault
        s.print("  mapMissDefault ")
        PP.singleline_pp(@noMapKeyDefault, s)
        s.print("\n ")
      end
      @marcfieldspecs.each do |spec|
        s.puts "  " + spec.asDSLString
      end
      s.puts "end"
      return s.string
    end
      
      
    # Output as a string representation of a ruby hash
    # @deprecated Use the DSL
    
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
      s.print(":specs => [\n")
      @marcfieldspecs.each do |ts|
        s.print '  '
        PP.singleline_pp(ts, s)
        s.print(",\n")
      end
      s.print " ]\n}"
      return  s.string
    end

  end
end    