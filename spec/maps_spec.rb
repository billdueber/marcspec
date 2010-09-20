require 'spec_helper'

describe "KV Maps" do
  before do
    @kvmap = MARCSpec::KVMap.new('kvmap', {'one' => '1', 'two' => ['2', 'zwei']})
  end
  
  it "knows its name" do
    @kvmap.mapname.should ==  'kvmap'
  end
  
  it "gets simple value from a kv map" do
    @kvmap['one'].should ==  '1'
  end
  
  it "gets a list value from a kv map" do
    @kvmap['two'].should ==  ['2', 'zwei']
  end
  
  it "gets nothing on nonmatches for kvmap" do
    @kvmap['ddd'].should ==  nil
  end

  it "gets default if set for nonmatches with KVMap" do
    @kvmap['ddd', 'default'].should ==  'default'
  end

  it "gets key if default is :passthrough for nonmatches with KVMap" do
    @kvmap['ddd', :passthrough].should ==  'ddd'
  end

  
  it "correctly uses default value" do
    @kvmap['ddd', 'default'].should ==  'default'
    @kvmap['one', 'default'].should ==  '1'
  end
  
  it "should round-trip a kvmap" do
    s = @kvmap.asPPString
    newkvmap = MARCSpec::KVMap.fromPPString s
    newkvmap.should ==  @kvmap
  end
  
  
  it "should read a kv solrmarc file" do
    map = MARCSpec::KVMap.from_solrmarc_file "#{DIR}/data/umich/translation_maps/country_map.properties"
    map.mapname.should ==  'country_map'
    map["nl"].should ==  "New Caledonia"
  end
  
  it "should correctly deal with solrmarc files with escaped chars (via \\)" do
    map = MARCSpec::KVMap.from_solrmarc_file "#{DIR}/data/umich/translation_maps/location_map.properties"
    map['AAEL'].should ==  'AAEL'
    map['AAEL MICE'].should ==  'AAEL MICE'
    map['BUHR AAEL'].should ==  'BUHR'
  end
  
  
  it "can dump/load a kv map via generic map interface" do
    map = MARCSpec::KVMap.from_solrmarc_file "#{DIR}/data/umich/translation_maps/country_map.properties"
    f = Tempfile.new('kvmap')
    f.puts map.asPPString
    path = f.path
    f.close
    map2 = MARCSpec::Map.fromFile(path)
    f.unlink
    map.class.should ==  MARCSpec::KVMap    
    map.should ==  map2
  end
  
  it "can name a map based on the filename when using fromFile(path)" do
    map = MARCSpec::Map.fromFile("#{DIR}/data/simplemap.rb")
    map.mapname.should ==  'simplemap'
  end

end

describe "MVMaps" do
  before do
    @mvmap = MARCSpec::MultiValueMap.new('mvmap', [
                                                  [/bi/, 'Bill'], 
                                                  [/mo/i, 'Molly'], 
                                                  [/ll/, 'Bill'], 
                                                  [/lly/i, ['One', 'Two']], 
                                                  [/^.*?\s+(.*)$/, Proc.new{|m| m[1]}]
                                                  ]
                                          )
    @mvmapCollapse = MARCSpec::MultiValueMap.new('mvmap', [
        [/^bill/i, 'William'],
        [/^will.*/i, 'William'],
        [/dueber/i, 'Dueber'],
        [/duebs/i, 'Dueber']
      ])                                          
  end
  
  it "knows its name" do
    @mvmap.mapname.should ==  'mvmap'
  end
  
  it "gets nothing on nonmatches for mvmap" do
    @mvmap['ddd'].should ==  nil
  end
  
  it "gets default if set for nonmatches with MVMap" do
    @mvmap['ddd', 'default'].should ==  'default'
  end
  

  it "gets key if default is :passthrough for nonmatches with KVMap" do
    @mvmap['ddd', :passthrough].should ==  'ddd'
  end

  
  it "gets correct values from multivaluemap" do
    @mvmap['bi'].should ==  ['Bill']
    @mvmap['bill'].should ==  ['Bill']
    @mvmap['mobi'].sort.should ==  ['Bill', 'Molly'].sort
    @mvmap['Molly'].sort.should ==  ['Molly', 'Bill', 'One', 'Two'].sort
  end

  it "correctly uses default value" do
    @mvmap['bi', 'default'].should ==  ['Bill']
    @mvmap['ddd', 'default'].should ==  'default'
  end
  
  it "should round trip a multivaluemap without a Proc" do 
    cleanmap = []
    @mvmap.map.each do |kv|
      cleanmap.push kv unless kv[1].is_a? Proc
    end
    @mvmap.map = cleanmap
    s = @mvmap.asPPString
    newmvmap = MARCSpec::MultiValueMap.fromPPString s
    newmvmap.should ==  @mvmap
  end
  
  it "can't round-trip a multivaluemap with a Proc" do
    s = @mvmap.asPPString
    newmvmap = MARCSpec::MultiValueMap.fromPPString s
    newmvmap.should_not ==  @mvmap
  end
  
  
  it "can use a proc in a multivaluemap" do
    @mvmap['Molly Dueber'].sort.should ==  ['Molly', 'Bill', 'Dueber', 'One', 'Two'].sort
  end
  
  it "can use a simple passthrough in a multivaluemap" do
     @mvmap = MARCSpec::MultiValueMap.new('mvmap', [[/.*/, Proc.new {|m| m[0]}]])
     @mvmap['one'].should ==  ['one']
     @mvmap['two'].should ==  ['two']
  end

  it "should read a pattern solrmarc file" do
    map = MARCSpec::MultiValueMap.from_solrmarc_file "#{DIR}/data/umich/translation_maps/library_map.properties"
    map.mapname.should ==  'library_map'
    map['UMTRI Stuff'].should ==  ['Transportation Research Institute Library (UMTRI)']
    map['HATCH DOCS'].should ==  ['Hatcher Graduate', 'Hatcher Graduate Documents Center']
  end

  it "can dump/load a multivalue map via generic map interface" do
    map = MARCSpec::MultiValueMap.from_solrmarc_file "#{DIR}/data/umich/translation_maps/library_map.properties"
    f = Tempfile.new('mvmap')
    f.puts map.asPPString
    path = f.path
    f.close
    map2 = MARCSpec::Map.fromFile(path)
    f.unlink
    map.class.should ==  MARCSpec::MultiValueMap
    map.should ==  map2
  end

  it "collapses ok" do
    @mvmapCollapse['bill'].should ==  ['William']
    @mvmapCollapse['william'].should ==  ['William']
    @mvmapCollapse['bill dueber'].sort.should ==  ['William', 'Dueber'].sort
    @mvmapCollapse['Will "duebes" Dueber'].sort.should ==  ['William', 'Dueber'].sort
    @mvmapCollapse['notinthere'].should ==  nil
  end
    
  
end
