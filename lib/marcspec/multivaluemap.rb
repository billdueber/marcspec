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
  # Again, note that if several keys are === to the passed argument, all the values will be returned. 
  
  class MultiValueMap   < Map
    
    attr_accessor :mapname,:map
    

    def [] key, default=nil
      rv =  @map.map {|pv| pv[0] === key ? pv[1] : nil}
      rv.flatten!
      rv.compact!
      rv.uniq!
      if rv.size > 0
        return rv
      else
        return [default]
      end
    end
    
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
        
    def asPPString
      s = StringIO.new
      s.print "{\n :maptype=>:multi,\n :mapname=>"
      PP.singleline_pp(@mapname, s)
      s.print ",\n :map => "
      PP.pp(@map, s)
      s.puts "\n}"
      return s.string
    end
  end
end
      