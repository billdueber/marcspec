require 'marc4j4r'
require 'set'
module MARCSpec

  # A ControlFieldSpec takes a control tag (generally 001..009) and an optional 1-based range
  # When called with marc_values(record), it returns either the complete value of all
  # occurances of the field in question (in the order they appear in the record), or 
  # the one-based substrings based on the passed range. 
  #
  # @example Get the whole 001
  # cfs = MARCSpec::ControlTagSpec.new('001')
  # 
  # @example Get the first three characters of the 008
  # cfs = MARCSpec::ControlTagSpec.new('001', 1..3)
  #
  # Note that the use of the one-based range in this manner flies in the face of programming
  # convention, but conforms to the way MARC substrings are specified. The weirdness is allowed
  # to make translation from MARC documentation as easy as possible.
  
  class ControlFieldSpec
    attr_accessor :tag, :range
    
    def initialize (tag, range=nil)
      unless MARC4J4R::ControlField.control_tag? tag
        raise ArgumentError "Tag must be a control tag"
      end
      @tag = tag
      return if range.nil?
      
      if range.is_a? Fixnum
        if range < 1
          raise ArgumentError, "Range must be nil, an integer offset (1-based), or a Range, not #{range}"
        end
        
        range = range - 1
        @range = range..range
        
      elsif range.is_a? Range
        @range = Range.new(range.first - 1, range.last - 1)
      else
        raise ArgumentError, "Range must be nil, an integer offset (1-based), or a Range, not #{range.inspect}"
      end
    end
    
    def marc_values r
      vals = r.find_by_tag(@tag).map {|f| f.value}
      if @range
        return vals.map {|v| v[@range]}
      else
        return vals
      end
    end
  end
  
  # A VariableFieldSpec has a tag (three chars) and a set of codes. Its #marc_values(r) method will return
  # all the values for the subfields for the given codes joined by the optional joiner (space by default)
  #
  # The subfield values are presented in the order they appear in the document, *not* the order the subfield
  # codes are specified
  #
  # @example Get the $a from the 245s
  # vfs = MARCSpec::VariableFieldSpec.new('245', 'a')
  #
  # vfs = MARCSpec::VariableFieldSpec.new('245', 'ab')
  
  
  class VariableFieldSpec
    
    attr_accessor :tag, :codes, :joiner
    def initialize tag, codes=nil, joiner=' '
      @tag = tag
      @joiner = joiner
      self.codes = codes
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
        vals << subvals.join(@joiner) if subvals.size > 0
      end
      return vals
    end

  end
  
end   
