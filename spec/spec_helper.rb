require 'rubygems'
require 'bacon'
require 'marc4j4r'
require 'tempfile'
begin
  require 'greeneggs'
rescue LoadError
end

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'marcspec'

DIR = File.dirname(__FILE__)

Bacon.summary_on_exit
