require 'marc4j4r'
require 'set'
require 'pp'
module MARCSpec
  # A ControlFieldSpec takes a control tag (generally 001..009) and an optional zero-based range
  # When called with marc_values(record), it returns either the complete value of all
  # occurances of the field in question (in the order they appear in the record), or 
  # the zero-based substrings based on the passed range. 
  #
  # @example Get the whole 001
  # cfs = MARCSpec::ControlTagSpec.new('001')
  # 
  # @example Get the first three characters of the 008
  # cfs = MARCSpec::ControlTagSpec.new('001', 0..2)
  #
  # Note that the use of the zero-based range in this manner conforms to the way MARC 
  # substrings are specified.
  
  class ControlFieldSpec
    attr_accessor :tag, :range
    
    def initialize (tag, range=nil)
      unless MARC4J4R::ControlField.control_tag? tag
        raise ArgumentError, "Tag must be a control tag"
      end
      @tag = tag
      self.range = range
    end
    
    def == other
      return ((self.tag == other.tag) and
              (self.range = other.range))
    end
    
    
    # Always force a real range, since in Ruby 1.9 a string subscript with a single fixnum
    # will return the character code of that character (e.g., "Bill"[0] => 66, wherease 
    # "Bill"[0..0] gives the expected 'B'
    #
    # @param [nil, Fixnum, Range] range A zero-based substring range or character position
    # @return [MARCSpec::ControlFieldSpec] self
    
    def range= range
      if range.nil?
        @range = nil
        return self
      end
      if range.is_a? Fixnum
        if range < 0
          raise ArgumentError, "Range must be nil, an integer offset (1-based), or a Range, not #{range}"
        end
      
        @range = range..range
      
      elsif range.is_a? Range
        if range.begin < 1 or range.begin > range.end
          raise ArgumentError "Range must be one-based, with the start before the end, not #{range}"
        else
          @range = range
        end
      else
        raise ArgumentError, "Range must be nil, an integer offset (1-based), or a Range, not #{range.inspect}"
      end
      return self
    end
    
    
    def marc_values r
      vals = r.find_by_tag(@tag).map {|f| f.value}
      if @range
        return vals.map {|v| v[@range]}
      else
        return vals
      end
    end
    
    def pretty_print pp
      pp.pp eval(self.asPPString)
    end
    
    def asPPString
      s = StringIO.new
      if @range
        PP.pp([@tag, @range], s)
      else
        PP.pp([@tag], s)
      end
      return s.string
    end
    
    def self.fromPPString str
      a = eval(str)
      return self.new(*a)
    end
    
  end
end