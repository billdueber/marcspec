require 'pp'

module MARCSpec
  class KVMap 
    attr_accessor :mapname
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
    
    def pretty_print pp
      pp.pp @map
    end
    
    
    def self.load filename
      rawmap = eval(File.open(filename).read)
      
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
