require 'spec_helper'

module A
  module B
    def self.titleUp doc, r, codes=nil
      title = r['245']
      if codes
        return [title.sub_values(codes).join(' ').upcase]
      else  
        return [title.value.upcase]
      end
    end
    
    # downcase and strip punctuation to create a sortable entitiy. Here, we're actually
    # ignoring the passed-in record entirely
    def self.sortable doc, r, whereTheTitleIs
      vals = []
      if doc[whereTheTitleIs]
        doc[whereTheTitleIs].each do |title|
          vals << title.gsub(/\p{Punct}/, ' ').gsub(/\s+/, ' ').strip.downcase
        end
      end
      return vals
    end
    
    
    def self.three_value_custom doc, r
      return [1, 2, ['a', 'b']]
    end
  end
end


describe "SpecSet Basics" do
  before do
    @one = MARC4J4R::Reader.new("#{DIR}/data/one.dat").first
    @places = ['Medina', 'Texas', 'United States of America.', 'Medina, Texas,']
    @title = ['The Texas ranger [sound recording] / Sung by Beale D. Taylor.']
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
     {:solrField=>'title', :specs=>[['245', '*', '*']]},
      {
        :solrField => 'titleA',
        :specs => [['245', '*', '*', 'a']]
      }
    ]
  end
  
  it "should build from a list" do 
    ss = MARCSpec::SpecSet.new
    ss.buildSpecsFromList(@speclist)
    ss.solrfieldspecs.size.should.equal 3
    h = ss.hash_from_marc @one
    h['places'].sort.should.equal @places.sort
    h['title'].should.equal @title
    h['titleA'].should.equal @titleA
  end
  
  it "allows customs that reference previous work" do
    @speclist << {:solrField=>'titleSort', :module=>A::B, :methodSymbol=>:sortable, :methodArgs=>['title']}
    ss = MARCSpec::SpecSet.new
    ss.buildSpecsFromList(@speclist)
    h = ss.hash_from_marc @one
    h['title'].should.equal @title
    h['titleSort'].should.equal @title.map{|a| a.gsub(/\p{Punct}/, ' ').gsub(/\s+/, ' ').strip.downcase}
  end
  
  it "should allow repeated solrFields" do
    @speclist << {:solrField=>'titleA', :specs=>[['260', '*', '*', 'c']]} # '1939.'
    expected = @titleA
    expected << '1939.'
    ss = MARCSpec::SpecSet.new
    ss.buildSpecsFromList(@speclist)
    h = ss.hash_from_marc @one
    h['titleA'].sort.should.equal expected.sort
  end
  
  it "should allow multi-headed custom fields" do
    @speclist << {:solrField => ['one', 'two', 'letters'],
                  :module => A::B,
                  :methodSymbol => :three_value_custom,
      }
    ss = MARCSpec::SpecSet.new
    ss.buildSpecsFromList(@speclist)
    h = ss.hash_from_marc @one
    h['one'].should.equal [1]
    h['two'].should.equal [2]
    h['letters'].should.equal ['a', 'b']
  end
    
    
end
   





  
    