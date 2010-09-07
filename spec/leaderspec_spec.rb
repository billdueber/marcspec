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
