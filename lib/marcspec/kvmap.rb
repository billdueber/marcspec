require 'pp'

module MARCSpec
  class KVMap 
    attr_accessor :mapname, :map
    def initialize(mapname, map)
      @mapname = mapname
      @map = map
    end
    def [] key, default=nil
      if @map.has_key? key
        @map[key]
      else
        default
      end
    end    
    
    def == other
      return ((other.mapname == self.mapname) and (other.map = self.map))
    end
    
    def pretty_print pp
      pp.pp eval(self.asPPString)
    end
    
    def asPPString
      s = StringIO.new
      s.print "{\n :maptype=>:kv,\n :mapname=>"
      PP.singleline_pp(@mapname, s)
      s.print ",\n :map => "
      PP.singleline_pp(@map, s)
      s.puts "\n}"
      return s.string
    end
    
    # Take the output of pretty_print and eval it to get rawmap; pass it
    # here to get the map object
    def self.fromPPString str
      rawmap = eval(str)
      return self.new(rawmap[:mapname], rawmap[:map])
    end
        
    def self.from_solrmarc_file filename
      mapname = File.basename(fn).sub(/\..+?$/, '')
      map = {}
      File.open(filename) do |smf|
        smf.each_line do |l|
          l.chomp!
          next unless l =~ /\S/
          l.strip!
          next if l =~ /^#/
          next unless l =~ /^(.+?)\s*=\s*(.+)$/
          map[$1] = $2
        end
      end
      return self.new(mapname, map)
    end
    
    
  end
end
