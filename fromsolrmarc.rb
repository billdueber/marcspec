require 'logger'
require 'marc4j4r'
require 'pp'
$: << 'lib'
require 'marcspec'


$LOG = Logger.new(STDOUT)
$LOG.level = Logger::DEBUG

# We'll take two arguments: a .properties index file, and a new directory 
propfile = ARGV[0]
newdir = ARGV[1]

unless File.exist? propfile
  $LOG.error "Can't find file '#{propfile}"
  exit
end
unless File.readable? propfile
  $LOG.error "File '#{propfile}' exists but cannot be read"
  exit
end

# First, try to create the new directory
begin
  FileUtils.mkdir_p newdir
rescue Exception => e
  $LOG.warn e
  # error means it's already there???
end

propfiledir = File.dirname(propfile)
trmapdir = propfiledir + '/translation_maps'
newpropfile = File.basename(propfile, '.properties') + '.rb'





ss  = MARCSpec::SpecSet.new
Dir.glob(trmapdir + '/*').each do |f|
  File.open(f) do |fh|
    fh.each_line do |line|
      next if line =~ /^\s*#/
      next unless line =~ /\S/
      if line =~ /^\s*pattern/
        $LOG.debug "Adding '#{File.basename f}' as a pattern map"
        ss.add_map MARCSpec::MultiValueMap.from_solrmarc_file(f)
        break
      else
        $LOG.debug "Adding '#{File.basename f}' as a key/value map"
        ss.add_map MARCSpec::KVMap.from_solrmarc_file(f)
        break
      end
    end
  end
end



WHOLE = /^(\d{3})$/
CTRL = /^(\d{3})\[(.+?)\]/
VAR  = /^(\d{3})(.+)/

File.open('spec/data/umich/umich_index.properties') do |fh|
  fh.each_line do |line|
    next unless line =~ /\S/
    line.strip!
    next if line =~ /^#/
    fieldname,spec = line.split(/\s*=\s*/)
    if spec =~ /^custom/
      # $LOG.warn "Skipping custom line #{line}"
      next
    end
    
    sfs = MARCSpec::SolrFieldSpec.new(:solrField => fieldname)
    
    marcfields, *specials = spec.split(/\s*,\s*/)
    
    marcfields.split(/\s*:\s*/).each do |ms|
      if WHOLE.match ms
        tag = $1
        if MARC4J4R::ControlField.control_tag? tag
          sfs << MARCSpec::ControlFieldSpec.new(tag)
        else
          sfs << MARCSpec::VariableFieldSpec.new(tag)
        end
        next

      elsif CTRL.match ms
        tag = $1
        range = $2
        first,last = range.split('-')
        last ||= first
        first = first.to_i
        last = last.to_i
        sfs << MARCSpec::ControlFieldSpec.new(tag, (first..last))
        next
      elsif VAR.match ms
        tag = $1
        sfcodes = $2.split(//)
        sfs << MARCSpec::VariableFieldSpec.new(tag, sfcodes)
      else
        $LOG.warn "Didn't recognize line '#{line}'"
      end
    end # marcfields.split
    
    # Add in the specials
    specials.each do |special|
      case special
      when 'first'
        sfs.first = true
      else
        mapname =  special.gsub(/.properties$/, '')
        sfs.map = ss.map(mapname)
        if mapname.nil? 
          $LOG.warn "Unrecognized map name '#{mapname}'"
        end
      end
    end
      
    
    ss << sfs if sfs.marcfieldspecs.size > 0
  end
end

