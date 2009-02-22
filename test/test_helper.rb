require 'rubygems'
require 'test/unit'

$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rtf'
include RTF

class Test::Unit::TestCase
  
  def fixture_file_path(filename)
    File.join(File.dirname(__FILE__), "fixtures", filename)
  end
end
