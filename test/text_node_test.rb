# encoding:UTF-8
require 'test_helper'

# Information class unit test class.
class TextNodeTest < Test::Unit::TestCase
   def setup
      @node = Node.new(nil)
   end

   def test01
      nodes = []
      nodes.push(TextNode.new(@node))
      nodes.push(TextNode.new(@node, 'Node 2'))
      nodes.push(TextNode.new(@node))
      nodes.push(TextNode.new(@node, ''))

      assert(nodes[0].text == nil)
      assert(nodes[1].text == 'Node 2')
      assert(nodes[2].text == nil)
      assert(nodes[3].text == '')

      nodes[0].text = 'This is the altered text for node 1.'
      assert(nodes[0].text == 'This is the altered text for node 1.')

      nodes[1].append('La la la')
      nodes[2].append('La la la')
      assert(nodes[1].text == 'Node 2La la la')
      assert(nodes[2].text == 'La la la')

      nodes[2].text = nil
      nodes[1].insert(' - ', 6)
      nodes[2].insert('TEXT', 2)
      assert(nodes[1].text == 'Node 2 - La la la')
      assert(nodes[2].text == 'TEXT')

      nodes[2].text = nil
      nodes[3].text = '{\}'
      assert(nodes[0].to_rtf == 'This is the altered text for node 1.')
      assert(nodes[1].to_rtf == 'Node 2 - La la la')
      assert(nodes[2].to_rtf == '')
      assert(nodes[3].to_rtf == '\{\\\}')
   end

   def test02
      begin
         TextNode.new(nil)
         flunk('Successfully created a TextNode with a nil parent.')
      rescue => error
      end
   end
   def test_utf8
     nodes = []
     nodes.push(TextNode.new(@node))
     nodes.push(TextNode.new(@node))

     nodes[0].text="ASCCI"
     assert_equal("ASCCI", nodes[0].to_rtf)


     utf8="Á"
     exp="\\u#{utf8.unpack("U")[0]}\\'3f"
     nodes[0].text=utf8
     assert_equal(exp, nodes[0].to_rtf)

   end
end
