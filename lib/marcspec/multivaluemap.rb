module MARCSpec

  # A MultiValueMap (in this conectex) is an array of duples of the form
  # [thingToMatch, 'Value'] (or [thingToMatch, [array,of,values]])
  # along with an associated name.
  #
  # Accessing via [] will give you an array of non-nil values that match (via ===)
  # the corresponding keys.
  #
  # Keys can be either strings or regular expressions (e.g., /^Bil/). 
  #
  # Again, note that if several keys are == to the passed argument, all the values will be returned. 
  
  class MultiValueMap   
    
    attr_accessor :mapname,:kvlist

    # Createa new MultiValueMap from an array of duples and an optional default
    # value (which itself can be an array of strings)
    #
    # @param Array<Array<key, string or array of strings>> patternlist An array of two-item arrays (duples). Each duple consists 
    # of a single regular expression (what is to be matched against) and either a single string or an array of strings (the value
    # or values to return on match). 
    # @param [String, Array<String>] default The default value to return if no pattern matches. Default is none
    # @return [Array] An array of values from matched patterns, flattened and with nils removed. Can be an empty array.
    
    def initialize(mapname, kvlist)
      @mapname = mapname
      @kvlist = kvlist
    end

    def [] key, default=nil
      rv =  @kvlist.map {|pv| pv[0] === key ? pv[1] : nil}
      rv.flatten!
      rv.compact!
      rv.uniq!
      if rv.size > 0
        return rv
      else
        return default
      end
    end
    
    def == other
      return ((other.mapname == self.mapname) and (other.kvlist = self.kvlist))
    end
    
    
    # Take the output of pretty_print and eval it to get rawmap; pass it
    # here to get the map object
    def self.fromHash rawmap
       return self.new(rawmap[:mapname], rawmap[:map])
    end
    
    def pretty_print pp
      puts self.asPPString
    end
    
    def asPPString
      s = StringIO.new
      s.print "{\n :maptype=>:multi,\n :mapname=>"
      PP.singleline_pp(@mapname, s)
      s.print ",\n :map => "
      PP.singleline_pp(@kvlist, s)
      s.puts "\n}"
      return s.string
    end
  end
end
      