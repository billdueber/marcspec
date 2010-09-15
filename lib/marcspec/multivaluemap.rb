require 'marcspec/map'
require 'pp'


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
  # IF the key is a regexp, the value may then be a Proc object that takes a single argument: the 
  # MatchData object produced by calling key.match(passed_in_value)
  #
  # Again, note that if several keys are === to the passed argument, all the values will be returned. 
  
  class MultiValueMap   < Map
    
    attr_accessor :mapname,:map
    
    # Given a passed_in_key (and optional default) return the set of values that match, as described
    # above.
    def [] key, default=nil
      rv = []
      @map.each do |pv|
        if pv[1].is_a? Proc
          match = pv[0].match key
          rv << pv[1].call(match) if match
        else
          rv << pv[1] if pv[0] === key
        end
      end
      rv.flatten!
      rv.compact!
      rv.uniq!
      if rv.size > 0
        return rv
      else
        return [default]
      end
    end
    
    # Try to produce a valid MVMap from a solrmarc file
    # @param [String] filename The file to read
    # @return [MARCSpec::MultiValueMap] A new mvmap
    def self.from_solrmarc_file filename
      mapname = File.basename(filename).sub(/\..+?$/, '')
      kvlist = []
      File.open(filename) do |f|
        prop = Java::java.util.Properties.new
        prop.load(f.to_inputstream)
        prop.each do |patstring,kv|
          unless patstring =~ /^pattern/ and kv =~ /.+=>.+/
            $LOG.warn "MultiValueMap import skipping weird line in #{filename}\n  #{l}"
            next
          end
          match = /^\s*(.+?)\s*=>\s*(.+?)\s*$/.match(kv)
          kvlist << [Regexp.new(match[1]), match[2]]
        end
      end        
      return self.new(mapname, kvlist)
    end
        
    # Produce a string suitable for pretty-printing. Unfortunately, we need to just plain
    # delete the procs before doing so
    
    def asPPString
      map = @map.reject {|kv| kv[1].is_a? Proc}
      s = StringIO.new
      s.print "{\n :maptype=>:multi,\n :mapname=>"
      PP.singleline_pp(@mapname, s)
      s.print ",\n :map => "
      PP.pp(map, s)
      s.puts "\n}"
      return s.string
    end
  end
end
      