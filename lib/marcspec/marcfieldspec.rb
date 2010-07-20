require 'marc4j4r'

module MARCSpec

  # A ControlTagSpec takes a control tag (generally 001..009) and an optional 1-based range
  # When called with marc_values(record), it returns either the complete value of all
  # occurances of the field in question (in the order they appear in the record), or 
  # the one-based substrings based on the passed range. 
  #
  # @example Get the whole 001
  # cts = MARCSpec::ControlTagSpec.new('001')
  # 
  # @example Get the first three characters of the 008
  # cts = MARCSpec::ControlTagSpec.new('001', 1..3)
  #
  # Note that the use of the one-based range in this manner flies in the face of programming
  # convention, but conforms to the way MARC substrings are specified. The weirdness is allowed
  # to make translation from MARC documentation as easy as possible.
  
  class ControlTagSpec
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
  
  class VariableTagSpec
  end
  
  
end   
