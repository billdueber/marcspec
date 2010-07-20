module MARCSpec
  class SolrFieldSpec
    attr_accessor :field, :first, :map, :tagspecs

    def initialize(opts)
      @field  = opts[:field]
      @first = opts[:first] || false      
      @default = opts[:default] || nil
      @map = opts[:map] || nil
      @noMapValueDefault = opts[:noMapValueDefault] || nil
      @tagspecs = []
    end

    def << tagspec
      tagspec.parent = self
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

      # If we got nothing, return the default
      if vals.size == 0
        return @default
      end
      
      # If we've got a map, map it.

      if (@map)
        vals.map! {|v| @map[v, @noMapValueDefault]}
      end
      
      # Flatten it all out
      
      vals.flatten!
      vals.uniq!
      vals.compact!
      return vals
    end

  end
end    