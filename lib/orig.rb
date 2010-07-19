require 'set'
require 'pp'
require 'logger'

$LOG ||= Logger.new(STDERR)

module MARCSpec

  class MapSpec
    attr_accessor :map, :type, :default
    
    def initialize(type, map, default=nil)
      @type = type
      @default = default
      @map = map
    end
    
    def [] key
      if (@type == :kv)
        if @map.has_key? key
          return @map[key]
        else
          return @default
        end
      end
      
      # For a pattern, we find all that match. 
      
      if (@type == :pattern)
        rv = []
        @map.each do |pv|
          pat = pv[0]
          val = pv[1]
#          puts "Trying pattern #{pat} against #{key}"
          if pat.match(key)
            rv << val
#            puts "Matched: adding #{val}"
          end
        end
        rv.uniq!
        if rv.size > 0
          return  rv
        else 
          return @default
        end
      end
    end
  end
  
  class CustomSpec
    def initialize(proc, args)
      @proc = proc
      @args = args
    end
    
    def marc_values_hash fieldnames, r
      a = @proc(r, args)
      rv = {}
      fieldnames.each_with_index do |fn, i|
        rv[fn] = a[i]
      end
      return rv
    end
  end
      
    
  class TagSpec
    attr_accessor :tag, :codes, :joiner, :parent, :ind1, :ind2, :range, :is_control
    
    def initialize(tag, codes=nil)
      @codes = Set.new
      @tag = tag
      @joiner = ' '
      @substr = nil
      tagint = tag.to_i
      @is_control = (tagint != 0 and tagint < 10)
      if (codes)
        self.codes = codes
      end
    end
    
    def range= newrange
      if newrange =~ /\s*(\d+)-(\d+)/
        start = $1.to_i 
        last =  $2.to_i
        @range = start..last
      else
        se = newrange.to_i
        @range = se..se
      end
    end
    
    def codes= newcodes
      if newcodes.is_a? Range
        @codes = newcodes.to_a
      elsif newcodes !~ /\S/
        @codes = nil
      # Otherwise, just split into individual characters
      else
        @codes = newcodes.split(//)
      end
    end
    
    def marc_values r
      if @is_control
        vals = r.find_by_tag(@tag).map {|f| f.value}
#        puts "Start with #{vals.join(', ')}"
        if @range
          vals.map! {|v| v[@range]}
        end
#        puts "End with #{vals.join(', ')}"
        
      else 
        fields = r.find_by_tag(@tag)
        vals = []
        fields.each do |f|
          subvals = f.sub_values(@codes)
          vals << subvals.join(@joiner) if subvals.size > 0
        end
      end
      # puts vals.join(', ')
      return vals
    end
    
  end
  
  class FieldSpec
    attr_accessor :field, :first, :map, :tagspecs
    
    def initialize(opts)
      @field  = opts[:field]
      @first = opts[:first] || false
      @map = opts[:map] || nil
      @tagspecs = []
    end
    
    def << tagspec
      tagspec.parent = self
      @tagspecs << tagspec
    end
    
    def marc_values r
      vals = []
      # puts "Tagspecs has #{@tagspecs.size} items"
      @tagspecs.each do |ts|
        vals.concat ts.marc_values(r)
        # puts vals.join(', ')
        break if @first and vals.size > 0
      end
      
      if (@map)
        vals.map! {|v| @map[v]}
        # vals.each do |v|
        #   puts "Map: #{v} => #{@map[v].to_s}"
        # end
      end
      vals.flatten!
      vals.uniq!
      vals.compact!
      return vals
    end
    
  end
  
  
  class SpecSet
    attr_accessor :tmaps, :fieldspecs
    def initialize(*args)
      tmapdir = args.pop!
      unless File.directory? tmapdir
        $LOG.error "Directory #{tmapdir} not found"
        raise LoadError, "Directory #{tmapdir} not found"
      end
              
      @tmaps = {}
      Dir.glob(tmapdir + '/*.rb') do |fn|
        basename = File.basename(fn).sub(/\.rb$/, '')
        $LOG.info "Loading translation map #{basename}"
        
        begin
          rawmap = eval(File.open(fn).read)
          @tmaps[basename] = MapSpec.new(rawmap[:type], rawmap[:map], rawmap[:default])
        rescue SyntaxError
          $LOG.error "Error processing translation map file #{fn}: #{$!}"
          raise SyntaxError, $!
        end
        
      end
      
      @fieldspecs = []
      
    # Get the index files
      args.each do |indexfile|
        begin
          unless File.exists? indexfile
            $LOG.error "File #{indexfile} does not exist"
            raise LoadError, "File #{indexfile} does not exist"
          end
          $LOG.info "Loading index file #{indexfile}"
          rawindex = eval(File.open(indexfile).read)
          rawindex.each do |entry|
            fs = FieldSpec.new(:field => entry[:solrField], :first=>entry[:firstOnly])
            mapname = entry[:map]
            if mapname
              if @tmaps.has_key? mapname
                fs.map = @tmaps[mapname]
              else 
                $LOG.error "Can't find map #{mapname}"
              end
            end
            entry[:specs].each do |entryts|
            
              # A one- or two-element entry is a control field
              # A three element entry (tag, ind1, ind2) is all subs of a field (need to implement)
              # A four element field is tag, ind1, ind2, subs
              # A five element field is tag, ind1, ind2, subs, joiner
              
            
              tag = entryts[0]
            
              # Is tag the symbol :custom? Then make it a custom item
            
              if tag == :custom
                ts = CustomSpec.new(entryts[1], entryts[2..-1])
                fs << ts
                next
              end
            
              # If it's not custom, the solrField better be a scale
              if entry[:solrField].is_a? Array
                # log an error and bail out
              end
            
              # Otherwise, it's a tag spec
              if tag.is_a? Fixnum
                tag = '%03d' % tag
              end
            
            
              ts = TagSpec.new(tag)
              if entryts.size < 3
                ts.is_control = true
                ts.range = entryts[1] if entryts[1]
              else
                ts.ind1 = entryts[1]
                ts.ind2 = entryts[2]            
                ts.codes = entryts[3]
                ts.joiner = entryts[4] if entryts[4]
              end
              fs << ts
            end
            self << fs
          end
        rescue SyntaxError
          $LOG.error "Error processing index file #{indexfile}: #{$!}"
          raise SyntaxError
        end      
      end
    end
    
    def each
      @fieldspecs.each do |fs|
        yield fs
      end
    end
    
    def << fieldspec
      @fieldspecs << fieldspec
    end
    
    def doc_from_marc r
      doc = SolrInputDocument.new
      @fieldspecs.each do |fs|
        doc[fs.field] = fs.marc_values(r)
      end
      return doc
    end      
    
    def hash_from_marc r
      h = {}
      @fieldspecs.each do |fs|
       h[fs.field] = fs.marc_values(r)
      end
      return h
    end
    
  end
end  