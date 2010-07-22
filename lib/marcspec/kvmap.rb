require 'marcspec/map'
require 'pp'

module MARCSpec
  class KVMap < Map

    def [] key, default=nil
      if @map.has_key? key
        @map[key]
      else
        default
      end
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
    
        
    def self.from_solrmarc_file filename
      mapname = File.basename(filename).sub(/\..+?$/, '')
      map = {}
      File.open(filename) do |smf|
        smf.each_line do |l|
          l.chomp!
          next unless l =~ /\S/
          l.strip!
          next if l =~ /^#/
          unless l =~ /^(.+?)\s*=\s*(.+)$/
            $LOG.warn "KVMap import skipping weird line in #{filename}\n  #{l}"
            next
          end
          map[$1] = $2
        end
      end
      return self.new(mapname, map)
    end
    
    
  end
end
