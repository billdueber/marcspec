require 'spec_helper'

positive = lambda{|x| x > 0}

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
        ["260",  "a"],
        ["651",  "a"],
        ["651",  "z"],
       ]
      },
      {
       :solrField=>'title', 
       :specs=>[['245']]
      },
      {
        :solrField => 'titleA',
        :specs => [['245',  'a']]
      },
      {
        :solrField => 'constantField',
        :constantValue => ['A', 'B']
      }
    ]
    
    @ss = MARCSpec::SpecSet.new
    @ss.buildSpecsFromList(@speclist)
    @h = @ss.hash_from_marc @one
    
  end
  
  it "should get all the specs" do
    @ss.solrfieldspecs.size.should ==  4
  end
  
  it "gets the places field" do
    @h['places'].sort.should ==  @places.sort
  end
  
  it "gets title" do
    @h['title'].should == @title
  end
  
  it "gets title_a" do
    @h['titleA'].should == @titleA
  end
  
  it "gets constant" do
    @h['constantField'].should == ['A', 'B']
  end
  
  it "allows customs that reference previous work" do
    @speclist << {:solrField=>'titleSort', :module=>A::B, :functionSymbol=>:sortable, :functionArgs=>['title']}
    ss = MARCSpec::SpecSet.new
    ss.buildSpecsFromList(@speclist)
    h = ss.hash_from_marc @one
    h['title'].should ==  @title
    h['titleSort'].should ==  @title.map{|a| a.gsub(/\p{Punct}/, ' ').gsub(/\s+/, ' ').strip.downcase}
  end
  
  it "should allow repeated solrFields" do
    @speclist << {:solrField=>'titleA', :specs=>[['260',  'c']]} # '1939.'
    expected = @titleA
    expected << '1939.'
    ss = MARCSpec::SpecSet.new
    ss.buildSpecsFromList(@speclist)
    h = ss.hash_from_marc @one
    h['titleA'].sort.should ==  expected.sort
  end
  
  it "should allow multi-headed custom fields" do
    @speclist << {:solrField => ['one', 'two', 'letters'],
                  :module => A::B,
                  :functionSymbol => :three_value_custom,
      }
    ss = MARCSpec::SpecSet.new
    ss.buildSpecsFromList(@speclist)
    h = ss.hash_from_marc @one
    h['one'].should ==  [1]
    h['two'].should ==  [2]
    h['letters'].should ==  ['a', 'b']
  end
  
  it "bails if it can't find a map" do
    @speclist << {:solrField => 'tst', :mapname=>'nosuch', :specs => [['245']]}
    lambda{@ss.buildSpecsFromList(@speclist)}.should raise_error(SystemExit )
  end
  
end



describe "Specset Benchmarking" do
  before do
    @reader = MARC4J4R::Reader.new("#{DIR}/data/batch.dat")    
    @speclist = [
      {
       :solrField=>'title', 
       :specs=>[['245']]
      },
      {
       :solrField=> "places",
       :specs => [
        ["260",  "a"],
        ["651",  "a"],
        ["651",  "z"],
       ]
      },      
      {
        :solrField => 'titleA',
        :specs => [['245',  'a']]
      }
    ]
    
    @ss = MARCSpec::SpecSet.new
    @ss.buildSpecsFromList(@speclist)    
  end
  
  it "should benchmark" do
    @reader.each do |r|
      h = @ss.hash_from_marc(r, true)
    end
    @ss.solrfieldspecs.each do |sfs|
      @ss.benchmarks[sfs.solrField].real.should be > 0.0
    end
    
    # @ss.benchmarks.each do |k,v|
    #   puts "%-10s %s" % [k + ':', v.to_s]
    # end
  end
end
    





  
    