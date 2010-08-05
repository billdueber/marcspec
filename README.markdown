# marcspec

The MARCSpec contains classes designed to make it (relatively) easy to specify
a data field (my use case specifically is solr) in terms of sets of MARC fields.

## A simple breakdown of the hierarchy

This is all based on how the excellent [Solrmarc](http://code.google.com/p/solrmarc/)
deals with configuration. MARCSpec supports a subset of Solrmarc's configuration
options. 

  * A *specset* consists of a (possibly empty) set of named *maps* 
    and a list of *solrfieldspecs* 
  * A *solrfieldspec* consists of a field name, a list of *marcfieldspecs*,
    an optional *map* for translating raw values to something else, and
    a bunch of optional specials (e.g., a notation to only use the first value,
    a default value if no appropriate data is in the marc record, a default value
    for when marc data is found, but nothing is in the map, etc.)
  * A *marcfieldspec* is one of the following
    * A *ControlFieldSpec*, consisting of a tag (as a string, not a number) and
      an optional zero-based index (e.g., "001[3]") or range (e.g., "001[11..13]")
    * A *VariableFieldSpec*, consisting of a tag, a couple indicator patterns
      (currently ignored, but stay tuned), an optional list of subfields (default
      is all), and an optional string used to join the subfields (default is
      a single space)
  * A *map* is one of:
    * A *KVMap*, which is just a Ruby hash. It will return at most one value.
    * A *MultiValueMap*, which is an array of key/value duples. A passed
      potential map is compared (via ==) with every key, returning all
      the associated values.

Obviously, better descriptions and full documentation is available in each 
individual class.

## Note on Patches/Pull Requests
 
* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a
  future version unintentionally.
* Commit, do not mess with rakefile, version, or history.
  (if you want to have your own version, that is fine but bump version in a commit by itself I can ignore when I pull)
* Send me a pull request. Bonus points for topic branches.

== Copyright

Copyright (c) 2010 BillDueber. See LICENSE for details.
