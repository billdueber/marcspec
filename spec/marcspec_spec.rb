require 'spec_helper'

# LEADER 00734njm a2200217uu 4500
# 001    afc99990058366
# 003    DLC
# 005    20071104155141.9
# 007    sd ummunniauub
# 008    071103s1939    xxufmnne||||||||| u eng||
# 010    $a afc99990058366
# 040    $a DLC $c DLC
# 245 04 $a The Texas ranger $h [sound recording] / $c Sung by Beale D. Taylor.
# 260    $a Medina, Texas, $c 1939.
# 300    $a 1 sound disc : $b analog, 33 1/3 rpm, mono. ; $c 12 in.
# 651  0 $a Medina $z Texas $z United States of America.
# 700 1  $a Lomax, John Avery, 1867-1948 $e Recording engineer.
# 700 1  $a Lomax, Ruby T. (Ruby Terrill) $e Recording engineer.
# 700 1  $a Taylor, Beale D. $e Singer.
# 852    $a American Folklife Center, Library of Congress
# 852    $a DLC

describe "ControlFieldSpec" do

  before do
    @one = MARC4J4R::Reader.new("#{DIR}/data/one.dat").first
    # @batch = MARC4J4R::Reader.new("#{DIR}/batch.dat").collect
  end

  
  it "gets a single full value" do
    cfs = MARCSpec::ControlFieldSpec.new('001')
    cfs.marc_values(@one).should.equal ["afc99990058366"]    
  end
  
  it "gets a single character" do
    cfs = MARCSpec::ControlFieldSpec.new('001', 10 )
    cfs.marc_values(@one).should.equal ['5']
  end
  
  it "gets a range of characters" do
    cfs = MARCSpec::ControlFieldSpec.new('001', 10..14 )
    cfs.marc_values(@one).should.equal ['58366']
  end
end

describe "VariableFieldSpec" do
  before do
    @one = MARC4J4R::Reader.new("#{DIR}/data/one.dat").first
    # @batch = MARC4J4R::Reader.new("#{DIR}/batch.dat").collect
  end

  it "Should get a whole field separated by spaces" do
    dfs = MARCSpec::VariableFieldSpec.new('260')
    dfs.marc_values(@one).should.equal ["Medina, Texas, 1939."]
  end

  it "Should get just the $a" do
    dfs = MARCSpec::VariableFieldSpec.new('260', 'a')
    dfs.marc_values(@one).should.equal ["Medina, Texas,"]
  end
  
  it "Should get all fields via several equal routes" do
    a = MARCSpec::VariableFieldSpec.new('260').marc_values(@one)
    ac =  MARCSpec::VariableFieldSpec.new('260', ['a', 'c']).marc_values(@one)
    ca =  MARCSpec::VariableFieldSpec.new('260', ['c', 'a']).marc_values(@one)
    allrange = MARCSpec::VariableFieldSpec.new('260', 'a'..'z').marc_values(@one)
    a.should.equal ac
    ac.should.equal ca
    ca.should.equal allrange
  end
  
  it "should get all three 700a's" do
    a = MARCSpec::VariableFieldSpec.new('700', 'a').marc_values(@one)
    a.should.equal ["Lomax, John Avery, 1867-1948", "Lomax, Ruby T. (Ruby Terrill)", "Taylor, Beale D."]
  end
end

describe "SolrFieldSpec" do
  before do 
    @one = MARC4J4R::Reader.new("#{DIR}/data/one.dat").first
    # @batch = MARC4J4R::Reader.new("#{DIR}/batch.dat").collect
    @opts = {:field=>'solrfield'}
    @titleAC =  MARCSpec::VariableFieldSpec.new('245', ['a', 'c'])
    @titleACValue = "The Texas ranger Sung by Beale D. Taylor."
    @twosixtyC = MARCSpec::VariableFieldSpec.new('260', 'c')
    @twosixtyCValue = "1939."
    
    @nonmatchingSpec =  MARCSpec::VariableFieldSpec.new('999', ['a', 'c'])
    
    @default = 'DEFAULT'
    
    
    @mapValue = "twosixtyCMapValue"
    @mapValueForDefault = 'mapValueForDefaultValue'
    @noMapKeyDefault = 'noMapKeyDefault'
    
    @map = MARCSpec::KVMap.new('nameOfTheMap', {@twosixtyCValue => @mapValue, @default=>@mapValueForDefault})
    
  end
  
  it "works with a single fieldspec" do
    sfs = MARCSpec::SolrFieldSpec.new(@opts)
    sfs << @titleAC
    sfs.marc_values(@one).should.equal [@titleACValue]
  end
  
  
  it "works with a double fieldspec" do
    sfs = MARCSpec::SolrFieldSpec.new(@opts)
    sfs << @titleAC
    sfs << @twosixtyC
    sfs.marc_values(@one).should.equal [@titleACValue, @twosixtyCValue]
  end

  it "preserves order" do
    sfs = MARCSpec::SolrFieldSpec.new(@opts)
    sfs << @twosixtyC
    sfs << @titleAC
    sfs.marc_values(@one).should.equal [@twosixtyCValue, @titleACValue]
  end

  
  it "works with firstOnly" do
    @opts[:firstOnly] = true
    sfs = MARCSpec::SolrFieldSpec.new(@opts)
    sfs << @titleAC
    sfs << @twosixtyC
    sfs.marc_values(@one).should.equal [@titleACValue]
  end
  
  it "returns nothing where there are no matches" do
    sfs = MARCSpec::SolrFieldSpec.new(@opts)
    sfs << @nonmatchingSpec
    sfs.marc_values(@one).should.equal []
  end
  
  it "works with a default" do
    @opts[:default] = @default
    sfs = MARCSpec::SolrFieldSpec.new(@opts)
    sfs << @nonmatchingSpec
    sfs.marc_values(@one).should.equal [@default]
  end
  
  it "works with a KV Map and no defaults" do
    @opts[:map] = @map
    sfs = MARCSpec::SolrFieldSpec.new(@opts)
    sfs << @titleAC
    sfs << @twosixtyC
    sfs.marc_values(@one).should.equal [@mapValue]
  end
  
  it "works with a KV Map and just a map default" do
    @opts[:map] = @map
    @opts[:noMapKeyDefault] = @noMapKeyDefault
    sfs = MARCSpec::SolrFieldSpec.new(@opts)
    sfs << @titleAC # not in map, get noMapKeyDefault
    sfs << @twosixtyC # in map, get mapValue
    pp sfs
    sfs.marc_values(@one).should.equal [@noMapKeyDefault, @mapValue]
  end

  it "works with a KV Map and maps default value correctly" do
    @opts[:map] = @map
    @opts[:default] = @default
    @opts[:noMapKeyDefault] = @noMapKeyDefault
    sfs = MARCSpec::SolrFieldSpec.new(@opts)
    sfs << @nonmatchingSpec
    sfs.marc_values(@one).should.equal [@mapValueForDefault]
  end

    
end    










