require 'logger'

$LOG = Logger.new(STDOUT)
$LOG.level = Logger::WARN

require "marcspec/customspec"
require "marcspec/solrfieldspec"
require "marcspec/kvmap"
require "marcspec/multivaluemap"
require "marcspec/specset"
require "marcspec/marcfieldspec"