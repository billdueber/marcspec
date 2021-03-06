require 'spec_helper'

describe "SolrFieldSpec" do
  before do 
    @one = MARC4J4R::Reader.new("#{DIR}/data/one.dat").first
    # @batch = MARC4J4R::Reader.new("#{DIR}/batch.dat").collect
    @opts = {:solrField=>'solrfield'}
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
    sfs.marc_values(@one).should ==  [@titleACValue]
  end
  
  
  it "works with a double fieldspec" do
    sfs = MARCSpec::SolrFieldSpec.new(@opts)
    sfs << @titleAC
    sfs << @twosixtyC
    sfs.marc_values(@one).should ==  [@titleACValue, @twosixtyCValue]
  end

  it "preserves order" do
    sfs = MARCSpec::SolrFieldSpec.new(@opts)
    sfs << @twosixtyC
    sfs << @titleAC
    sfs.marc_values(@one).should ==  [@twosixtyCValue, @titleACValue]
  end

  
  it "works with firstOnly" do
    @opts[:firstOnly] = true
    sfs = MARCSpec::SolrFieldSpec.new(@opts)
    sfs << @titleAC
    sfs << @twosixtyC
    sfs.marc_values(@one).should ==  [@titleACValue]
  end
  
  it "returns nothing where there are no matches" do
    sfs = MARCSpec::SolrFieldSpec.new(@opts)
    sfs << @nonmatchingSpec
    sfs.marc_values(@one).should ==  []
  end
  
  it "works with a default" do
    @opts[:default] = @default
    sfs = MARCSpec::SolrFieldSpec.new(@opts)
    sfs << @nonmatchingSpec
    sfs.marc_values(@one).should ==  [@default]
  end
end

describe "Solr Field Specs and maps" do
  
  before do 
    @one = MARC4J4R::Reader.new("#{DIR}/data/one.dat").first
    # @batch = MARC4J4R::Reader.new("#{DIR}/batch.dat").collect
    @opts = {:solrField=>'solrfield'}
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
  
  it "works with a KV Map and no defaults" do
    @opts[:map] = @map
    sfs = MARCSpec::SolrFieldSpec.new(@opts)
    sfs << @titleAC
    sfs << @twosixtyC
    sfs.marc_values(@one).should ==  [@mapValue]
  end
  
  it "works with a KV Map and just a map default" do
    @opts[:map] = @map
    @opts[:noMapKeyDefault] = @noMapKeyDefault
    sfs = MARCSpec::SolrFieldSpec.new(@opts)
    sfs << @titleAC # not in map, get noMapKeyDefault
    sfs << @twosixtyC # in map, get mapValue
    sfs.marc_values(@one).should ==  [@noMapKeyDefault, @mapValue]
  end

  it "works with a KV Map and returns default value correctly" do
    @opts[:map] = @map
    @opts[:default] = @default
    @opts[:noMapKeyDefault] = @noMapKeyDefault
    sfs = MARCSpec::SolrFieldSpec.new(@opts)
    sfs << @nonmatchingSpec
    sfs.marc_values(@one).should ==  [@default]
  end
    
  it "returns multiple values from a kv map when appropriate" do
    @map[@twosixtyCValue] = ['one', 'two']
    @opts[:map] = @map
    sfs = MARCSpec::SolrFieldSpec.new(@opts)
    sfs << @twosixtyC
    sfs.marc_values(@one).sort.should ==  ['one', 'two']
  end
  
  it "flattens things out when getting multiple values from a kv map" do
    @map[@titleACValue] = ['one', 'two']
    @map[@twosixtyCValue] = ['three', 'four']
    @opts[:map] = @map
    sfs = MARCSpec::SolrFieldSpec.new(@opts)
    sfs << @twosixtyC
    sfs << @titleAC
    sfs.marc_values(@one).sort.should ==  ['one', 'two', 'three', 'four'].sort
  end

  
  it "round trips if you add the map by hand" do
    @opts[:map] = @map
    @opts[:noMapKeyDefault] = @noMapKeyDefault
    sfs = MARCSpec::SolrFieldSpec.new(@opts)
    sfs << @titleAC # not in map, get noMapKeyDefault
    sfs << @twosixtyC # in map, get mapValue
    
    newsfs = MARCSpec::SolrFieldSpec.fromPPString(sfs.asPPString)
    newsfs.map = @map
    sfs.should ==  newsfs
  end
end    

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
      if doc[]
        doc[whereTheTitleIs].each do |title|
          vals << title.gsub(/\p{Punct}/, ' ').gsub(/\s+/, ' ').strip.downcase
        end
      end
      return vals
    end
  end
end



describe "CustomSolrSpec" do
  before do 
    @one = MARC4J4R::Reader.new("#{DIR}/data/one.dat").first
    @opts = {:solrField=>'solrfield'}
    @titleACValue = "The Texas ranger Sung by Beale D. Taylor."
    @twosixtyCValue = "1939."
    @mapValue = "titleACUppercaseValue"
    @mapValueForDefault = 'mapValueForDefaultValue'
    @noMapKeyDefault = 'noMapKeyDefault'
    
    @map = MARCSpec::KVMap.new('nameOfTheMap', {@titleACValue.upcase => @mapValue, @default=>@mapValueForDefault})
  end
  
  
  it "works with no args or map" do
    css = MARCSpec::CustomSolrSpec.new(:solrField=>'solrField', :module=>A::B, :functionSymbol=>:titleUp)
    css.marc_values(@one).should ==  [@one['245'].value.upcase]
  end

  it "accepts nil for no args" do
    css = MARCSpec::CustomSolrSpec.new(:solrField=>'solrField', :module=>A::B, :functionSymbol=>:titleUp, :functionArgs=>nil)
    css.marc_values(@one).should ==  [@one['245'].value.upcase]
  end

  
  it "uses a custom method with args but no map" do
    css = MARCSpec::CustomSolrSpec.new(:solrField=>'solrField', :module=>A::B, :functionSymbol=>:titleUp, :functionArgs=>[['a', 'c']])
    css.marc_values(@one).should ==  [@titleACValue.upcase]
  end
  
  it "works with a map" do
    css = MARCSpec::CustomSolrSpec.new(:solrField=>'solrField', :map=>@map, :module=>A::B, :functionSymbol=>:titleUp, :functionArgs=>[['a', 'c']])
    css.marc_values(@one).should ==  [@mapValue]
  end
  
  it "works with a map that has multiple return values" do 
    @map[@titleACValue.upcase] = ['two', 'one']
    css = MARCSpec::CustomSolrSpec.new(:solrField=>'solrField', :map=>@map, :module=>A::B, :functionSymbol=>:titleUp, :functionArgs=>[['a', 'c']])
    css.marc_values(@one).should ==  ['two', 'one']
  end
  
  it "disallows multispecs with maps or default values" do
    lambda{
      css = MARCSpec::CustomSolrSpec.new(:solrField=>['s1', 's2'], :module=>A::B, :functionSymbol=>:titleUp, :map=>@map)
    }.should raise_error(ArgumentError)
    lambda{
      css = MARCSpec::CustomSolrSpec.new(:solrField=>['s1', 's2'], :module=>A::B, :functionSymbol=>:titleUp, :default=>"bill")
    }.should raise_error(ArgumentError)
  end
  
end

describe "ConstantSolrSpec" do
  it "sets correct fields" do
    c = MARCSpec::ConstantSolrSpec.new(:solrField=>"test", :constantValue=>"value")
    c.solrField.should ==  'test'
    c.constantValue.should ==  'value'
  end
  
  it "allows array of values" do 
    value = ['a', 'b', 'c']
    c = MARCSpec::ConstantSolrSpec.new(:solrField=>"test", :constantValue=>value)
    c.constantValue.should ==  value
  end

  bad = {
    :firstOnly => true,
    :default => 'default',
    :noMapKeyDefault => 'nmd',
    :mapname => 'map',
    :specs => [],
    :module => MARCSpec,
    :functionSymbol => :test
  }

  bad.each do |k,v|
    opts = {:solrField=>'test'}
    opts[k] = v
    it "raises ArgumentError if given invalid option #{k}" do
      lambda{c = MARCSpec::ConstantSolrSpec.new(opts)}.should raise_error(ArgumentError)
    end
  end
  
  it "should round trip" do
    c = MARCSpec::ConstantSolrSpec.new(:solrField=>"test", :constantValue=>"value")
    s = StringIO.new
    s.puts(c.asPPString)
    d = MARCSpec::ConstantSolrSpec.fromPPString(s.string)
    c.should ==  d
  end
end