require 'spec_helper'

# The contents of @one
#
#
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


# Create a helper for the custom functions

module SPECHelper
  def self.test doc, r
    return 'Hello'
  end
  
  def self.single doc, r, arg
    return "Hello " + arg.to_s
  end
  
  def self.double doc, r, one, two
    return ["Hello", one, two].join(' ')
  end
  
  def self.any doc, r, *args
    return 'Hello ' + args.map{|s| s.to_s}.join(' ')
  end

end

describe "DSL" do
  before do 
    @one = MARC4J4R::Reader.new("#{DIR}/data/one.dat").first
  end
  
  describe "constant DSL" do
  
    it "can add a constant solrfieldspec" do
      ss = MARCSpec.build do
        constant('id') do
          value "Bill"
        end
      end
      ss.solrfieldspecs.size.should.equal 1
      ss.hash_from_marc(@one)['id'].should.equal ['Bill']
    end
  end

  describe "custom DSL" do
  
    # before do 
    #   @one = MARC4J4R::Reader.new("#{DIR}/data/one.dat").first
    # end
  
    it "builds a bare-bones custom" do
      ss = MARCSpec.build do
        custom('hello') do
          function(:test) {
            mod SPECHelper
          }
        end
      end
    
      ss.hash_from_marc(@one)['hello'].should.equal ['Hello']
    end
  
    it "builds a custom that can take a single argument" do
      ss = MARCSpec.build do
        custom('hello') do
          function(:single) {
            mod SPECHelper
            args 'Bill'
          }
        end
      end

      ss.hash_from_marc(@one)['hello'].should.equal ['Hello Bill']
    end
  
    it "builds a custom that can take two arguments" do
      ss = MARCSpec.build do
        custom('hello') do
          function(:double) {
            mod SPECHelper
            args 'Bill', 'Dueber'
          }
        end
      end

      ss.hash_from_marc(@one)['hello'].should.equal ['Hello Bill Dueber']
    end
 
    it "builds a custom that can take two arguments" do
      ss = MARCSpec.build do
        custom('hello') do
          function(:any) {
            mod SPECHelper
            args 1,2,3,4,5
          }
        end
      end

      ss.hash_from_marc(@one)['hello'].should.equal ['Hello 1 2 3 4 5']
    end
  end


  describe "control fields DSL" do
    # before do 
    #   @one = MARC4J4R::Reader.new("#{DIR}/data/one.dat").first
    # end
  
    it "should get a standard with a single whole control spec" do
      ss = MARCSpec.build do
        field("id") do
          spec('001') 
        end
      end
      ss.hash_from_marc(@one)['id'].should.equal ['afc99990058366']
    end

    it "should allow integer tags" do
      ss = MARCSpec.build do
        field("id") do
          spec(001) 
        end
      end
      ss.hash_from_marc(@one)['id'].should.equal ['afc99990058366']
    end

    it "can get a single char" do
      ss = MARCSpec.build do
        field("tst") do
          spec(001) {
            char 2
          }
        end
      end
      ss.hash_from_marc(@one)['tst'].should.equal ['c']
    end

    it "can get a range" do
      ss = MARCSpec.build do
        field("tst") do
          spec(001) {
            chars 2..6
          }
        end
      end
      ss.hash_from_marc(@one)['tst'].should.equal ['c9999']
    end

  end


  describe "variable fields DSL" do
    # before do 
    #   @one = MARC4J4R::Reader.new("#{DIR}/data/one.dat").first
    # end
  
    it "can get a whole variable field" do
      ss = MARCSpec.build do
        field("tst") do
          spec(260) 
        end
      end
      ss.hash_from_marc(@one)['tst'].should.equal ['Medina, Texas, 1939.']
    end
  
    it "can get a single subfield" do
      ss = MARCSpec.build do
        field("tst") do
          spec(260) {
            sub 'a'
          }
        end
      end
      ss.hash_from_marc(@one)['tst'].should.equal ['Medina, Texas,']
    end


    it "can get multiple subfields" do
      ss = MARCSpec.build do
        field("tst") do
          spec(245) {
            sub 'ac'
          }
        end
      end
      ss.hash_from_marc(@one)['tst'].should.equal ['The Texas ranger Sung by Beale D. Taylor.']
    end

    it "can get multiple subfields as array" do
      ss = MARCSpec.build do
        field("tst") do
          spec(245) {
            subs ['a', 'c']
          }
        end
      end
      ss.hash_from_marc(@one)['tst'].should.equal ['The Texas ranger Sung by Beale D. Taylor.']
    end 
  
    it "can get multiple different subfields from the same field" do
      ss = MARCSpec.build do
        field("tst") do
          spec(245) {
            sub 'a'
            sub 'c'
          }
        end
      end
      ss.hash_from_marc(@one)['tst'].should.equal ['The Texas ranger', 'Sung by Beale D. Taylor.']
    end  
  
    it "can handle multiple specs" do
      ss = MARCSpec.build do
        field('tst') do
          spec(245) {
            sub 'a'
          }
          spec(245) {
            sub 'c'
          }
        end
      end
      ss.hash_from_marc(@one)['tst'].should.equal ['The Texas ranger', 'Sung by Beale D. Taylor.']
    end
  end

  describe "SolrFieldSpec modifiers DSL" do
    it "works with firstOnly" do
      ss = MARCSpec.build do
        field('tst') do
          firstOnly
          
          spec(700) {
            sub 'a'
          }
        end
      end
      
      ss.hash_from_marc(@one)['tst'].should.equal ['Lomax, John Avery, 1867-1948']
    end
    
    it "works with default" do
      ss = MARCSpec.build do
        field('tst') do
          default 'Default value'

          spec(777) {
            sub 'a'
          }
        end
      end

      ss.hash_from_marc(@one)['tst'].should.equal ['Default value']
    end
  end
  
  describe "use as config file" do
    it "works in practice" do
      string = %q|
        field('tst') do
          default 'Default'
          spec(999)
        end
        
        field('id') do
          spec(001) {
            chars 2..6
          }
        end
      |

      ss = MARCSpec::SpecSet.new
      ss.instance_eval(string)
      ss.hash_from_marc(@one)['tst'].should.equal ['Default']
      ss.hash_from_marc(@one)['id'].should.equal ['c9999']      
    end
  end


end