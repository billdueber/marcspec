require 'spec_helper'

describe "MARCFieldSpec" do
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
    # puts "PRINTING SFS"
    # pp sfs
    # puts "PRINTING MAP"
    # pp @map
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
  
  it "round trips if you add the map by hand" do
    @opts[:map] = @map
    @opts[:noMapKeyDefault] = @noMapKeyDefault
    sfs = MARCSpec::SolrFieldSpec.new(@opts)
    sfs << @titleAC # not in map, get noMapKeyDefault
    sfs << @twosixtyC # in map, get mapValue
    
    newsfs = MARCSpec::SolrFieldSpec.fromPPString(sfs.asPPString)
    newsfs.map = @map
    sfs.should.equal newsfs
  end

end    

