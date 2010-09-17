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
        
    # Override initialize and map= so we can do some optimization
    
    def initialize *args
      super(*args)
      self.optimize
    end
    
    def map= map
      @map = map
      self.optimize
    end
    
    
    def optimize
      @super_regexp = Regexp.union @map.map{|pv| pv[0]}
      inverted = {}
      @map.each do |pv|
        inverted[pv[1]] ||= []
        inverted[pv[1]] << pv[0]
      end
      inverted.each_pair do |vals, patterns|
        next unless patterns.size > 1
        newpat = Regexp.union patterns
        patterns.each do |p|
          @map.delete_if{|pv| p == pv[0]}
        end
        @map << [newpat, vals]
      end
    end
    
    # Given a passed_in_key (and optional default) return the set of values that match, as described
    # above.
    def [] key, default=nil
      rv = []
      
      if @super_regexp.match key # do *any* of them match?
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
      end

      if rv.size > 0
        return rv
      else
        if default == :passthrough
          return key
        else
          return default
        end
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
      