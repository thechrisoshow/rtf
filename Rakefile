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
  self.extra_dev_deps << ["hoe",">=0"] 
end
