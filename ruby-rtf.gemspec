# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{ruby-rtf}
  s.version = "0.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Peter Wood"]
  s.date = %q{2009-02-23}
  s.description = %q{Ruby RTF is a library that can be used to create rich text format (RTF) documents. RTF is a text based standard for laying out document content.}
  s.email = %q{paw220470@yahoo.ie}
  s.files = ["VERSION.yml", "lib/rtf", "lib/rtf/colour.rb", "lib/rtf/font.rb", "lib/rtf/information.rb", "lib/rtf/node.rb", "lib/rtf/paper.rb", "lib/rtf/style.rb", "lib/rtf.rb", "test/character_style_test.rb", "test/colour_table_test.rb", "test/colour_test.rb", "test/command_node_test.rb", "test/container_node_test.rb", "test/document_style_test.rb", "test/document_test.rb", "test/fixtures", "test/fixtures/bitmap1.bmp", "test/fixtures/bitmap2.bmp", "test/fixtures/jpeg1.jpg", "test/fixtures/jpeg2.jpg", "test/fixtures/png1.png", "test/fixtures/png2.png", "test/font_table_test.rb", "test/font_test.rb", "test/footer_node_test.rb", "test/header_node_test.rb", "test/image_node_test.rb", "test/information_test.rb", "test/node_test.rb", "test/paragraph_style_test.rb", "test/style_test.rb", "test/table_cell_node_test.rb", "test/table_node_test.rb", "test/table_row_node_test.rb", "test/test_helper.rb", "test/text_node_test.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/thechrisoshow/ruby-rtf}
  s.rdoc_options = ["--inline-source", "--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Ruby library to create rich text format documents.}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
