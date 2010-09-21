require 'logger'
require 'marc4j4r'

$LOG = Logger.new(STDOUT)
$LOG.level = Logger::WARN

require "marcspec/customspec"
require "marcspec/solrfieldspec"
require "marcspec/constantspec"
require "marcspec/kvmap"
require "marcspec/multivaluemap"
require "marcspec/specset"
require "marcspec/marcfieldspec"
require "marcspec/dsl"

module CacheSpot
  # Build up a little module to include in MARC4J4R::Record that
  # gives us a way to cache computed values within the record itself
  # It's just a hash.
  #
  # Pretty sure this belongs somewhere else; not sure where.
  #
  # @return [Hash] the cachespot hash
  def cachespot
    @_cachespot ||= {}
    return @_cachespot
  end
end

MARC4J4R::Record.send(:include, CacheSpot)