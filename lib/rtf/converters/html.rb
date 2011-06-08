require 'rtf'
require 'nokogiri'

module PM
  module RTF
    extend self

    def from_html(html)
      html = ::Nokogiri::HTML::Document.parse(html)
      html.css('body').children.to_rtf
    end

    def new(font = :default)
      ::RTF::Document.new font(font)
    end

    def font(key)
      ::RTF::Font.new(*case key
        when :default   then [::RTF::Font::ROMAN,  'Times New Roman']
        when :monospace then [::RTF::Font::MODERN, 'Courier New'    ]
      end)
    end

    def style(key)
      ::RTF::CharacterStyle.new.tap do |style|
        case key.to_sym
        when :h1
          style.font_size = 46
          style.bold = true
        when :h2
          style.font_size = 38
          style.bold = true
        when :h3
          style.font_size = 28
          style.bold = true
        end
      end
    end

    module Nokogiri
      module NodeSet
        def to_rtf(rtf = nil)
          (rtf || PM::RTF.new).tap do |rtf|
            each {|node| node.to_rtf(rtf)}
          end
        end
      end

      module Node
        def to_rtf(rtf)
          #puts "handling #{to_html}"

          case name
          when 'text'                   then rtf << text
          when 'br'                     then rtf.line_break
          when 'b', 'strong'            then rtf.bold &recurse
          when 'i', 'em', 'cite'        then rtf.italic &recurse
          when 'u'                      then rtf.underline &recurse
          when 'blockquote', 'p', 'div' then rtf.paragraph &recurse
          when 'sup'                    then rtf.subscript &recurse
          when 'sub'                    then rtf.superscript &recurse
          when 'ul'                     then rtf.list :bullets, &recurse
          when 'ol'                     then rtf.list :decimal, &recurse
          when 'li'                     then rtf.item &recurse
          when 'a'                      then rtf.link self[:href], &recurse
          when 'h1', 'h2', 'h3'         then rtf.apply(PM::RTF.style(name), &recurse); rtf.line_break
          when 'code'                   then rtf.font PM::RTF.font(:monospace), &recurse
          else
            #puts "Ignoring #{to_html}"
          end

          return rtf
        end

        def recurse
          #puts "recursing on #{children.to_html}"
          lambda {|rtf| children.to_rtf(rtf)}
        end
      end
    end

  end
end

Nokogiri::XML::NodeSet.instance_eval { include PM::RTF::Nokogiri::NodeSet }
Nokogiri::XML::Node.instance_eval    { include PM::RTF::Nokogiri::Node    }
