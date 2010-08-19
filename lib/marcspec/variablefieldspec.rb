require 'set'
require 'pp'
module MARCSpec
  # A VariableFieldSpec has a tag (three chars) and a set of codes. Its #marc_values(r) method will return
  # all the values for the subfields for the given codes joined by the optional joiner (space by default)
  #
  # The subfield values are presented in the order they appear in the document, *not* the order the subfield
  # codes are specified
  #
  # @example Get the $a from the 245s
  # vfs = MARCSpec::VariableFieldSpec.new('245', 'a')
  # vfs = MARCSpec::VariableFieldSpec.new('245', 'ab')
  # vfs =  MARCSpec::VariableFieldSpec.new('245', ['a', 'b'])
  # vfs =  MARCSpec::VariableFieldSpec.new('245', 'a'..'b')
  
  class VariableFieldSpec

    attr_accessor :tag, :codes, :joiner

    def initialize tag, codes=nil, joiner=' '
      @tag = tag
      @joiner = joiner || ' '
      self.codes = codes
    end

    def == other
      return ((self.tag == other.tag) and
              (self.codes = other.codes) and
              (self.joiner = other.joiner))
    end

    def codes= c
      if c.nil?
        @codes = nil
        return nil
      end

      if( c.is_a? Array) or (c.is_a? Set) or (c.is_a? Range)
        @codes = c.to_a
      else
        @codes = c.split(//)
      end

      return @codes
    end

    def marc_values r
      fields = r.find_by_tag(@tag)
      vals = []
      fields.each do |f|
        subvals = f.sub_values(@codes)
        subvals =  subvals.join(@joiner) if subvals.size > 0 and (@codes.nil? or @codes.size > 1)
        vals << subvals
      end
      vals.flatten!
      return vals
    end

    def pretty_print pp
      pp.pp eval(self.asPPString)
    end

    def asPPString
      s = StringIO.new
      if @joiner and @joiner != ' '
        PP.pp([@tag, '*', '*', @codes.join(''), @joiner], s)
      else
        PP.pp([@tag, '*', '*', @codes.join('')], s)
      end
      return s.string
    end

   def self.fromPPString str
     a = eval(str)
     return self.new(a[0], a[3], a[4])
   end

  end

end