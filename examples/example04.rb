#!/usr/bin/env ruby

require 'rubygems'
require 'rtf'

include RTF

IMAGE_FILE = 'rubyrtf.png'

begin
   document = Document.new(Font.new(Font::ROMAN, 'Times New Roman'))

   # Add some text to the document and then add the scaled image.
   document.paragraph do |p|
      p << "This is a simple document that attempts to demonstrate the use "
      p << "of images in a document. A simple image should appear in the page "
      p << "header above, on the right hand side. The same image, scaled to "
      p << "four times its normal size, should appear below this text."
      p.line_break
   end

   # Add the scaled image.
   image = document.image(IMAGE_FILE)
   image.x_scaling = 400
   image.y_scaling = 400

   # Add some follow up text.
   document.paragraph do |p|
      p.line_break
      p << "Due to the way images are stored in RTF documents, adding images "
      p << "to a document can result in the document file becoming very large. "
      p << "The Ruby RTF library supports the addition of images in the PNG, "
      p << "JPEG and Windows device independent bitmap formats. A compressed "
      p << "image format (like PNG or JPEG) is preferrable to the plain bitmap "
      p << "format as this will result in a smaller document file."
   end

   # Add a header to the document.
   style  = ParagraphStyle.new
   style.justification = ParagraphStyle::RIGHT_JUSTIFY
   header = HeaderNode.new(document)
   header.paragraph(style) {|n| n.image(IMAGE_FILE)}
   document.header = header

   # Write the document to a file.
   File.open('example04.rtf', 'w') {|file| file.write(document.to_rtf)}
rescue => error
   puts "ERROR: #{error.message}"
   error.backtrace.each {|step| puts "   #{step}"}
end