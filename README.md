# marcspec

The MARCSpec contains classes designed to make it (relatively) easy to specify
a data field (my use case specifically is solr) in terms of sets of MARC fields and subfields. 

It currently requires the use of `marc4j4r` and hence JRuby, but I'm going to work on making a compatibility layer with [ruby-marc](http://marc.rubyforge.org/) now that the 0.4 version is out.

## Usage

```ruby
require 'rubygems'
require 'marcspec'
require 'marc4j4r'
require 'marc2solr/marc2solr_custom' # get the custom functions

ss = MARCSpec::SpecSet.build do
  field('id') {
    spec('001')
    firstOnly # only take the first 001
  }
  field('title') {
    spec('245a') # just the a
    spec('245ab') # just the ab
    spec('245')   # the whole thing
  }
  field('lccn') {
    spec('010a')
  }
  custom('oclc') { # use a custom function
    function(:valsByPattern) {
      mod MARC2Solr::Custom
      args '035', 'a', /(?:oclc|ocolc|ocm|ocn).*?(\d+)/i, 1
    }
  }
end

reader = MARC4J4R::Reader.new('mymarc.mrc', :strictmarc)

reader.each do |r|
  h = ss.hash_from_marc(r)
  # or doc = ss_doc_from_marc(r) # gets a SolrInputDocument
  
  puts h['lccn'][0] # the first lccn
  h['title'].each do |t|
    puts t
  end
  
end

```


## Docs and examples

Docs are hosted at the [[wiki|http://github.com/billdueber/marcspec/wiki/]]


Documented samples are available as part of the [marc2solr_example project](http://github.com/billdueber/marc2solr_example)
-- look in the simple_sample area to start with.


##Note on Patches/Pull Requests
 
* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a
  future version unintentionally.
* Commit, do not mess with rakefile, version, or history.
  (if you want to have your own version, that is fine but bump version in a commit by itself I can ignore when I pull)
* Send me a pull request. Bonus points for topic branches.

## Copyright

Copyright (c) 2010 BillDueber. See LICENSE for details.
