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

describe "ControlTagSpec" do

  before do
    @one = MARC4J4R::Reader.new("#{DIR}/data/one.dat").first
    # @batch = MARC4J4R::Reader.new("#{DIR}/batch.dat").collect
  end

  
  it "gets a single full value" do
    cts = MARCSpec::ControlTagSpec.new('001')
    cts.marc_values(@one).should.equal ["afc99990058366"]    
  end
  
  it "gets a single character" do
    cts = MARCSpec::ControlTagSpec.new('001', 10 )
    cts.marc_values(@one).should.equal ['5']
  end
  
  it "gets a range of characters" do
    cts = MARCSpec::ControlTagSpec.new('001', 10..14 )
    cts.marc_values(@one).should.equal ['58366']
  end
  
  
    
  
end
