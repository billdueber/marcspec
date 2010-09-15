require 'spec_helper'

describe "Maps" do
  before do
    @kvmap = MARCSpec::KVMap.new('kvmap', {'one' => '1', 'two' => ['2', 'zwei']})
    @mvmap = MARCSpec::MultiValueMap.new('mvmap', [
                                                  [/bi/, 'Bill'], 
                                                  [/mo/i, 'Molly'], 
                                                  [/ll/, 'Bill'], 
                                                  [/lly/i, ['One', 'Two']], 
                                                  [/^.*?\s+(.*)$/, Proc.new{|m| m[1]}]
                                                  ]
                                          )
  end
  
  it "knows its name" do
    @kvmap.mapname.should.equal 'kvmap'
    @mvmap.mapname.should.equal 'mvmap'
  end
  
  it "gets simple value from a kv map" do
    @kvmap['one'].should.equal '1'
  end
  
  it "gets a list value from a kv map" do
    @kvmap['two'].should.equal ['2', 'zwei']
  end
  
  it "gets nothing on nonmatches" do
    @kvmap['ddd'].should.equal nil
    @mvmap['ddd'].should.equal [nil]
  end
  
  it "gets correct values from multivaluemap" do
    @mvmap['bi'].should.equal ['Bill']
    @mvmap['bill'].should.equal ['Bill']
    @mvmap['mobi'].sort.should.equal ['Bill', 'Molly'].sort
    @mvmap['Molly'].sort.should.equal ['Molly', 'Bill', 'One', 'Two'].sort
  end
  
  it "correctly uses default value" do
    @mvmap['bi', 'default'].should.equal ['Bill']
    @mvmap['ddd', 'default'].should.equal ['default']
    @kvmap['ddd', 'default'].should.equal 'default'
    @kvmap['one', 'default'].should.equal '1'
  end
  
  it "should round-trip a kvmap" do
    s = @kvmap.asPPString
    newkvmap = MARCSpec::KVMap.fromPPString s
    newkvmap.should.equal @kvmap
  end
  
  it "should round trip a multivaluemap without a Proc" do 
    cleanmap = []
    @mvmap.map.each do |kv|
      cleanmap.push kv unless kv[1].is_a? Proc
    end
    @mvmap.map = cleanmap
    s = @mvmap.asPPString
    newmvmap = MARCSpec::MultiValueMap.fromPPString s
    newmvmap.should.equal @mvmap
  end
  
  it "can't round-trip a multivaluemap with a Proc" do
    s = @mvmap.asPPString
    puts s
    newmvmap = MARCSpec::MultiValueMap.fromPPString s
    newmvmap.should.not.equal @mvmap
  end
  
  
  it "can use a proc in a multivaluemap" do
    @mvmap['Molly Dueber'].sort.should.equal ['Molly', 'Bill', 'Dueber', 'One', 'Two'].sort
  end
  
  it "can use a simple passthrough in a multivaluemap" do
     @mvmap = MARCSpec::MultiValueMap.new('mvmap', [[/.*/, Proc.new {|m| m[0]}]])
     @mvmap['one'].should.equal ['one']
     @mvmap['two'].should.equal ['two']
  end
  
  it "should read a kv solrmarc file" do
    map = MARCSpec::KVMap.from_solrmarc_file "#{DIR}/data/umich/translation_maps/country_map.properties"
    map.mapname.should.equal 'country_map'
    map["nl"].should.equal "New Caledonia"
  end
  
  it "should correctly deal with solrmarc files with escaped chars (via \\)" do
    map = MARCSpec::KVMap.from_solrmarc_file "#{DIR}/data/umich/translation_maps/location_map.properties"
    map['AAEL'].should.equal 'AAEL'
    map['AAEL MICE'].should.equal 'AAEL MICE'
    map['BUHR AAEL'].should.equal 'BUHR'
  end
  
  it "should read a pattern solrmarc file" do
    map = MARCSpec::MultiValueMap.from_solrmarc_file "#{DIR}/data/umich/translation_maps/library_map.properties"
    map.mapname.should.equal 'library_map'
    map['UMTRI Stuff'].should.equal ['Transportation Research Institute Library (UMTRI)']
    map['HATCH DOCS'].should.equal ['Hatcher Graduate', 'Hatcher Graduate Documents Center']
  end
  
  it "can dump/load a kv map via generic map interface" do
    map = MARCSpec::KVMap.from_solrmarc_file "#{DIR}/data/umich/translation_maps/country_map.properties"
    f = Tempfile.new('kvmap')
    f.puts map.asPPString
    path = f.path
    f.close
    map2 = MARCSpec::Map.fromFile(path)
    f.unlink
    map.class.should.equal MARCSpec::KVMap    
    map.should.equal map2
  end

  it "can dump/load a multivalue map via generic map interface" do
    map = MARCSpec::MultiValueMap.from_solrmarc_file "#{DIR}/data/umich/translation_maps/library_map.properties"
    f = Tempfile.new('mvmap')
    f.puts map.asPPString
    path = f.path
    f.close
    map2 = MARCSpec::Map.fromFile(path)
    f.unlink
    map.class.should.equal MARCSpec::MultiValueMap
    map.should.equal map2
  end

  
end