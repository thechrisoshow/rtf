$:.unshift(File.expand_path(File.dirname(__FILE__)+"/lib"))
$:.unshift(File.expand_path(File.dirname(__FILE__)))
require 'rake'

require 'rubygems'
require 'rtf'

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |t|
    t.libs << 'test'
    t.test_files = FileList['test/**/*_test.rb']
    t.verbose = true
  end
rescue LoadError
  puts "RCov is not available. In order to run rcov, you must: sudo gem install rcov"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib' << 'test'
  t.pattern = 'test/**/*.rb'
  t.verbose = false
end

task :default => :test
