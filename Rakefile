$:.unshift(File.expand_path(File.dirname(__FILE__)+"/lib"))
$:.unshift(File.expand_path(File.dirname(__FILE__)))
require 'rake'

require 'rubygems'
require 'hoe'
require 'rtf'
Hoe.plugin :git


h=Hoe.spec 'clbustos-rtf' do
  # Original author: Peter Wood
  self.developer 'Claudio Bustos', 'clbustos_at_gmail.com'
  self.version=RTF::VERSION
  self.git_log_author=true
  path = File.expand_path("~/.rubyforge/user-config.yml")
  config = YAML.load(File.read(path))
  host = "#{config["username"]}@rubyforge.org"
  
  remote_dir = "#{host}:/var/www/gforge-projects/ruby-statsample/rtf"
  self.rdoc_locations << remote_dir
  self.extra_dev_deps << ["hoe",">=0"] 
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
