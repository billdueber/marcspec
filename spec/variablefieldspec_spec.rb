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

describe "VariableFieldSpec" do
  before do
    @one = MARC4J4R::Reader.new("#{DIR}/data/one.dat").first
    # @batch = MARC4J4R::Reader.new("#{DIR}/batch.dat").collect
  end

  it "Should get a whole field separated by spaces" do
    dfs = MARCSpec::VariableFieldSpec.new('260')
    dfs.marc_values(@one).should ==  ["Medina, Texas, 1939."]
  end

  it "Should get just the $a" do
    dfs = MARCSpec::VariableFieldSpec.new('260', 'a')
    dfs.marc_values(@one).should ==  ["Medina, Texas,"]
  end
  
  it "should return separate values for repeated subfields if only one code is specified" do
    dfs = MARCSpec::VariableFieldSpec.new('651', 'z')
    dfs.marc_values(@one).sort.should ==  ['Texas', 'United States of America.']
  end
  
  it "Should get all fields via several == routes" do
    a = MARCSpec::VariableFieldSpec.new('260').marc_values(@one)
    ac =  MARCSpec::VariableFieldSpec.new('260', ['a', 'c']).marc_values(@one)
    ca =  MARCSpec::VariableFieldSpec.new('260', ['c', 'a']).marc_values(@one)
    ca2 = MARCSpec::VariableFieldSpec.new('260', 'ca').marc_values(@one)
    allrange = MARCSpec::VariableFieldSpec.new('260', 'a'..'z').marc_values(@one)
    a.should ==  ac
    ac.should ==  ca
    ca.should ==  allrange
  end
  
  it "should get all three 700a's" do
    a = MARCSpec::VariableFieldSpec.new('700', 'a').marc_values(@one)
    a.should ==  ["Lomax, John Avery, 1867-1948", "Lomax, Ruby T. (Ruby Terrill)", "Taylor, Beale D."]
  end
  
  it "should round trip" do 
    ac =  MARCSpec::VariableFieldSpec.new('260', ['a', 'c'])
    ac2 = MARCSpec::VariableFieldSpec.fromPPString(ac.asPPString)
    ac.should ==  ac2
  end
  
end
