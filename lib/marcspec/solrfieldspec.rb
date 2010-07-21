require 'stringio'
module MARCSpec
  class SolrFieldSpec
    attr_accessor :field, :first, :map, :tagspecs

    def initialize(opts)
      @field  = opts[:field]
      @first = opts[:firstOnly] || false      
      @default = opts[:default] || nil
      @map = opts[:map] || nil
      @mapname = opts[:mapname] || nil
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
    
    
    def pretty_print pp
      s = StringIO.new
      s.print "{\n :solrField=> "
      PP.singleline_pp(@field, s)
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
      puts s.string
      return nil
    end

  end
end    