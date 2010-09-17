require 'stringio'
require 'marc4j4r/controlfield'

module MARCSpec
  class SolrFieldSpec
    attr_accessor :solrField, :first, :map, :noMapKeyDefault, :marcfieldspecs, :defaultValue,  :mapname
    attr_reader :arity

    def initialize(opts)
      @solrField  = opts[:solrField]
      @first = opts[:firstOnly] || false      
      @defaultValue = opts[:default] || nil
      @map = opts[:map] || nil
      @noMapKeyDefault = opts[:noMapKeyDefault] || nil
      @arity = 1
      @marcfieldspecs = []
    end

    def << tagspec
      @marcfieldspecs << tagspec
    end


    def raw_marc_values r, doc
      vals = []
      @marcfieldspecs.each do |ts|
        vals.concat ts.marc_values(r)
      end
      return vals
    end
      
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
    
    
    def == other
      return ((other.solrField == self.solrField) and
             (other.first == self.first) and
             (other.map == self.map) and
             (other.defaultValue == self.defaultValue) and
             (other.noMapKeyDefault == self.noMapKeyDefault) and
             (other.marcfieldspecs == self.marcfieldspecs))
    end
    
    def self.fromPPString str
      return self.fromHash eval(str)
    end
    
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
    
    def pretty_print pp
      pp.pp eval(self.asPPString)
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