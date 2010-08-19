require 'logger'
require 'marc4j4r'

$LOG = Logger.new(STDOUT)
$LOG.level = Logger::WARN

require "marcspec/customspec"
require "marcspec/solrfieldspec"
require "marcspec/kvmap"
require "marcspec/multivaluemap"
require "marcspec/specset"
require "marcspec/marcfieldspec"


# Build up a little module to include in MARC4J4R::Record that
# gives us a way to cache computed values within the record itself
# It's just a hash.

module CacheSpot
  def cacheadd k, v
    @_cachespot ||= {}
    @_cachespot[k] = v
    return v
  end
  
  def cacheget k
    @_cachespot ||= {}
    return @_cachespot[k]
  end
end

MARC4J4R::Record.send(:include, CacheSpot)