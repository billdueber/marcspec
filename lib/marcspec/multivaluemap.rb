module MARCSpec

  # A MultiValueMap (in this conectex) is an array of duples of the form
  # [thingToMatch, 'Value'] (or [thingToMatch, [array,of,values]])
  #
  # Accessing via [] will give you an array of non-nil values that match (via ===)
  # the corresponding keys.
  #
  # Keys can be either strings or regular expressions (e.g., /^Bil/). 
  #
  # Again, note that if several keys are == to the passed argument, all the values will be returned. 
  
  class MultiValueMap   

    # Createa new MultiValueMap from an array of duples and an optional default
    # value (which itself can be an array of strings)
    #
    # @param Array<Array<key, string or array of strings>> patternlist An array of two-item arrays (duples). Each duple consists 
    # of a single regular expression (what is to be matched against) and either a single string or an array of strings (the value
    # or values to return on match). 
    # @param [String, Array<String>] default The default value to return if no pattern matches. Default is none
    # @return [Array] An array of values from matched patterns, flattened and with nils removed. Can be an empty array.
    
    def initialize(kvlist)
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
  end
end
      