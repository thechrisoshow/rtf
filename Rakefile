require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name = "rtf"
    s.summary = 'Ruby library to create rich text format documents.'
    s.email = "paw220470@yahoo.ie"
    s.homepage = "http://github.com/thechrisoshow/rtf"
    s.description = 'Ruby RTF is a library that can be used to create '\
                    'rich text format (RTF) documents. RTF is a text '\
                    'based standard for laying out document content.'
    s.authors = ["Peter Wood"]
    s.files = FileList["[A-Z]*", "{examples,lib,test}/**/*"]
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = 'ruby-rtf'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('[A-Z]*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib' << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = false
end

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

task :default => :test
