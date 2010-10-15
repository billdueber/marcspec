require 'pp'
require 'jlogger'

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
    include JLogger::Simple
    
    attr_accessor :tag, :codes, :joiner, :ind1, :ind2, :codehistory

    # Get a new object
    #
    # @param [String] tag The MARC field tag
    # @param [String, Array] codes The list of subfield codes (as 'abc' or ['a', 'b', 'c']) whose values we want
    # @param [String] joiner What string to use to join the subfield values
    # @return [VariableFieldSpec] the new object
    
    def initialize tag, codes=nil, joiner=' '
      @tag = tag
      @joiner = joiner || ' '
      self.codes = codes
      @codehistory = []
    end
    
    # Basic equality
    # @param [VariableFieldSpec] other The other spec
    # @return [Boolean] whether or not it matches in all values
    
    def == other
      return ((self.tag == other.tag) and
              (self.codes = other.codes) and
              (self.joiner = other.joiner))
    end

    
    # Set the list of subfield codes we're concerned with. 
    # Internally, we always store this as an array. For input, accept
    # an array of single-letter codes, a string of codes like 'abjk09',
    # or a range like 'a'..'z'. nil means to use all the subfields
    #
    # @param [String, Array<String>, Range<String>, nil] c The code(s) to use
    # @return [Array] the new set of codes
    
    def codes= c
      @codehistory << @codes if @codes
      if c.nil?
        @codes = nil
        return nil
      end

      if( c.is_a? Array) or (c.is_a? Range)
        @codes = c.to_a
      else
        @codes = c.split(//)
      end

      return @codes
    end

    # Get the values associated with the tag (and optional subfield codes) for the given record
    #
    # @param [MARC4J4R::Record] r The record you want to extract values from
    # @return [Array<String>] the extracted values, if any
    
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


    # Get a DSL snipped representing this object
    # @return [String] the DSL string
    
    def asDSLString
      subs = @codes.join('')
      if subs.size > 0
        # return "spec('#{@tag}') {subs '#{subs}'}"
        return "spec('#{tag}#{subs}')"
      else
        return "spec('#{@tag}')"
      end
    end
      
        
    # Print out hash version of this object
    # @deprecated Use the DSL
    def pretty_print pp
      pp.pp eval(self.asPPString)
    end
    
    # Create a eval'able string of a hash version of this object
    # @deprecated Use the DSL
    
    def asPPString
      s = StringIO.new
      if @joiner and @joiner != ' '
        PP.pp([@tag, @codes.join(''), @joiner], s)
      else
        PP.pp([@tag, @codes.join('')], s)
      end
      return s.string
    end

   # Create an object from an asPPString string
   # @deprecated Use the DSL
   def self.fromPPString str
     a = eval(str)
     return self.new(a[0], a[1], a[2])
   end

  end

end