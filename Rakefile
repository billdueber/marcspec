require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "marcspec"
    gem.summary = %Q{Extract data from MARC records and send to Solr}
    gem.description = %Q{TODO: longer description of your gem}
    gem.email = "bill@dueber.com"
    gem.homepage = "http://github.com/billdueber/marcspec"
    gem.authors = ["BillDueber"]
    gem.add_development_dependency "bacon", ">= 0"
    gem.add_development_dependency "yard", ">= 0"

    gem.add_development_dependency 'marc4j4r', '>=0.1.0'

    gem.add_dependency 'set'
    gem.add_dependency 'logger'
    
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |spec|
    spec.libs << 'spec'
    spec.pattern = 'spec/**/*_spec.rb'
    spec.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :spec => :check_dependencies

task :default => :spec

begin
  require 'yard'
  YARD::Rake::YardocTask.new
rescue LoadError
  task :yardoc do
    abort "YARD is not available. In order to run yardoc, you must: sudo gem install yard"
  end
end
