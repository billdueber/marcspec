require 'spec_helper'

describe "Basics" do
  before do
    @one = MARC4J4R::Reader.new("#{DIR}/data/one.dat").first
    @places = ['Medina', 'Texas', 'United States of America.', 'Medina, Texas,']
    @titleA = ['The Texas ranger']
    @speclist = [
      {
       :solrField=> "places",
       :specs => [
        ["260", "*", "*", "a"],
        ["651", "*", "*", "a"],
        ["651", "*", "*", "z"],
       ]
      },
      {
        :solrField => 'titleA',
        :specs => [['245', '*', '*', 'a']]
      }
    ]
  end
  
  it "should build from a list" do 
    ss = MARCSpec::SpecSet.new
    ss.buildSpecsFromList(@speclist)
    ss.solrfieldspecs.size.should.equal 2
    h = ss.hash_from_marc @one
    h['places'].sort.should.equal @places.sort
    h['titleA'].should.equal @titleA
  end
  
end
  
    