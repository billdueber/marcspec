require 'rubygems'
require 'marc4j4r'
require 'tempfile'
require 'logger'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'marcspec'

DIR = File.dirname(__FILE__)

Logback::Simple.loglevel = :warn
Logback::Simple.startConsoleLogger