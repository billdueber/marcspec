require 'spec_helper'

describe "Maps" do
  before do
    @kvmap = MARCSpec::KVMap.new('kvmap', {'one' => 1, 'two' => 2})
    @mvmap = MARCSpec::MultiValueMap.new('mvmap', [[/bi/, 'Bill'], [/mo/, 'Molly'], [/ll/, 'Bill']])
  end
  
  it "knows its name" do
    @kvmap.mapname.should.equal 'kvmap'
    @mvmap.mapname.should.equal 'mvmap'
  end
  
  it "should round-trip a kvmap" do
    s = @kvmap.asPPString
    newkvmap = MARCSpec::KVMap.fromHash eval(s)
    newkvmap.should.equal @kvmap
  end
  
  it "should round trip a multivaluemap" do 
    s = @mvmap.asPPString
    newmvmap = MARCSpec::MultiValueMap.fromHash eval(s)
    newmvmap.should.equal @mvmap
  end
  
end