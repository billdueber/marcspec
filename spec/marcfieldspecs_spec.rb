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

  # afc99990058366 # data
  # 01234567890123 # index
  it "gets a single full value" do
    cfs = MARCSpec::ControlFieldSpec.new('001')
    cfs.marc_values(@one).should.equal ["afc99990058366"]    
  end
  
  it "gets a single character" do
    cfs = MARCSpec::ControlFieldSpec.new('001', 10 )
    cfs.marc_values(@one).should.equal ['8']
  end
  
  it "gets a range of characters" do
    cfs = MARCSpec::ControlFieldSpec.new('001', 6..10 )
    cfs.marc_values(@one).should.equal ['90058']
  end
  
  it "should round trip" do
    cfs = MARCSpec::ControlFieldSpec.new('001', 6..10 )
    cfs2 = MARCSpec::ControlFieldSpec.fromPPString(cfs.asPPString)
    cfs.should.equal cfs2
  end    
  
  it "throws an error if you try to use a datafield tag" do
    lambda{
      cfs = MARCSpec::ControlFieldSpec.new('010', 6..10 )
    }.should.raise ArgumentError
  end
  
  it "accepts various forms for the range" do
    cfs1 = MARCSpec::ControlFieldSpec.new('001')
    cfs2 = MARCSpec::ControlFieldSpec.new('001')
    cfs3 = MARCSpec::ControlFieldSpec.new('001')
    
    # Range 4-7 is 9999
    cfs1.range = 4
    cfs2.range = 4..4
    cfs1.marc_values(@one).should.equal ['9']
    cfs2.marc_values(@one).should.equal ['9']
  end
  
  it "rejects bad ranges" do
    lambda{
      cfs = MARCSpec::ControlFieldSpec.new('010', -1)
    }.should.raise ArgumentError

    lambda{
      cfs = MARCSpec::ControlFieldSpec.new('010', -1..3)
    }.should.raise ArgumentError
    
    lambda{
      cfs = MARCSpec::ControlFieldSpec.new('010', [1,2,3])
    }.should.raise ArgumentError
  end
end


describe "LeaderSpec" do
  before do
    @one = MARC4J4R::Reader.new("#{DIR}/data/one.dat").first
  end
  
  it "Works with full leader" do
    cfs = MARCSpec::LeaderSpec.new('LDR')
    cfs.marc_values(@one).should.equal @one.leader
  end
  
  it "Works with substring of leader" do
    cfs = MARCSpec::LeaderSpec.new('LDR', 3..5)
    cfs.marc_values(@one).should.equal @one.leader[3..5]
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
  
  it "should return separate values for repeated subfields if only one code is specified" do
    dfs = MARCSpec::VariableFieldSpec.new('651', 'z')
    dfs.marc_values(@one).sort.should.equal ['Texas', 'United States of America.']
  end
  
  it "Should get all fields via several equal routes" do
    a = MARCSpec::VariableFieldSpec.new('260').marc_values(@one)
    ac =  MARCSpec::VariableFieldSpec.new('260', ['a', 'c']).marc_values(@one)
    ca =  MARCSpec::VariableFieldSpec.new('260', ['c', 'a']).marc_values(@one)
    ca2 = MARCSpec::VariableFieldSpec.new('260', 'ca').marc_values(@one)
    allrange = MARCSpec::VariableFieldSpec.new('260', 'a'..'z').marc_values(@one)
    a.should.equal ac
    ac.should.equal ca
    ca.should.equal allrange
  end
  
  it "should get all three 700a's" do
    a = MARCSpec::VariableFieldSpec.new('700', 'a').marc_values(@one)
    a.should.equal ["Lomax, John Avery, 1867-1948", "Lomax, Ruby T. (Ruby Terrill)", "Taylor, Beale D."]
  end
  
  it "should round trip" do 
    ac =  MARCSpec::VariableFieldSpec.new('260', ['a', 'c'])
    ac2 = MARCSpec::VariableFieldSpec.fromPPString(ac.asPPString)
    ac.should.equal ac2
  end
  
end
