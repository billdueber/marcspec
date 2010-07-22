require 'stringio'
module MARCSpec
  class SolrFieldSpec
    attr_accessor :solrField, :first, :map, :noMapKeyDefault, :tagspecs

    def initialize(opts)
      @solrField  = opts[:solrField]
      @first = opts[:firstOnly] || false      
      @default = opts[:default] || nil
      @map = opts[:map] || nil
      @noMapKeyDefault = opts[:noMapKeyDefault] || nil
      @tagspecs = []
    end

    def << tagspec
      @tagspecs << tagspec
    end

    def marc_values r
      vals = []
      # puts "Tagspecs has #{@tagspecs.size} items"
      @tagspecs.each do |ts|
        vals.concat ts.marc_values(r)
        # puts vals.join(', ')
        break if @first and vals.size > 0
      end
      
      if @first
        vals = [vals.compact.first].compact
      end

      # If we got nothing 
      if vals.size == 0
        if @default.nil? # unless there's a default value, just return nothing
          return []
        else
          vals =  [@default]
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
             (other.noMapKeyDefault == self.noMapKeyDefault) and
             (other.tagspecs == self.tagspecs))
    end
    
    def self.fromPPString str
      return self.fromHash eval(str)
    end
    
    def self.fromHash h
      sfs = self.new(h)
      h[:specs].each do |s|
        if s.size < 3 
          sfs << MARCSpec::ControlFieldSpec.new(*s)
        else
          sfs << MARCSpec::VariableFieldSpec.new(s[0], s[3], s[4])
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
      s.print(":specs => [\n   ")
      @tagspecs.each do |ts|
        PP.singleline_pp(ts, s)
        s.print(",\n   ")
      end
      s.print "\n ]"
      s.print "\n}"
      return  s.string
    end

  end
end    