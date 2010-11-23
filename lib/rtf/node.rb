#!/usr/bin/env ruby

require 'stringio'

module RTF
   # This class represents an element within an RTF document. The class provides
   # a base class for more specific node types.
   class Node
      # Node parent.
      attr_accessor :parent
      
      # Constructor for the Node class.
      #
      # ==== Parameters
      # parent::  A reference to the Node that owns the new Node. May be nil
      #           to indicate a base or root node.
      def initialize(parent)
         @parent = parent
      end

      # This method retrieves a Node objects previous peer node, returning nil
      # if the Node has no previous peer.
      def previous_node
         peer = nil
         if parent != nil and parent.respond_to?(:children)
            index = parent.children.index(self)
            peer  = index > 0 ? parent.children[index - 1] : nil
         end
         peer
      end

      # This method retrieves a Node objects next peer node, returning nil
      # if the Node has no previous peer.
      def next_node
         peer = nil
         if parent != nil and parent.respond_to?(:children)
            index = parent.children.index(self)
            peer  = parent.children[index + 1]
         end
         peer
      end

      # This method is used to determine whether a Node object represents a
      # root or base element. The method returns true if the Nodes parent is
      # nil, false otherwise.
      def is_root?
         @parent == nil
      end

      # This method traverses a Node tree to locate the root element.
      def root
         node = self
         node = node.parent while node.parent != nil
         node
      end
   end # End of the Node class.


   # This class represents a specialisation of the Node class to refer to a Node
   # that simply contains text.
   class TextNode < Node
     # Actual text
      attr_accessor :text

      # This is the constructor for the TextNode class.
      #
      # ==== Parameters
      # parent::  A reference to the Node that owns the TextNode. Must not be
      #           nil.
      # text::    A String containing the node text. Defaults to nil.
      #
      # ==== Exceptions
      # RTFError::  Generated whenever an nil parent object is specified to
      #             the method.
      def initialize(parent, text=nil)
         super(parent)
         if parent == nil
            RTFError.fire("Nil parent specified for text node.")
         end
         @parent = parent
         @text   = text
      end

      # This method concatenates a String on to the end of the existing text
      # within a TextNode object.
      #
      # ==== Parameters
      # text::  The String to be added to the end of the text node.
      def append(text)
         if @text != nil
            @text = @text + text.to_s
         else
            @text = text.to_s
         end
      end

      # This method inserts a String into the existing text within a TextNode
      # object. If the TextNode contains no text then it is simply set to the
      # text passed in. If the offset specified is past the end of the nodes
      # text then it is simply appended to the end.
      #
      # ==== Parameters
      # text::    A String containing the text to be added.
      # offset::  The numbers of characters from the first character to insert
      #           the new text at.
      def insert(text, offset)
         if @text != nil
            @text = @text[0, offset] + text.to_s + @text[offset, @text.length]
         else
            @text = text.to_s
         end
      end

      # This method generates the RTF equivalent for a TextNode object. This
      # method escapes any special sequences that appear in the text.
      def to_rtf
        rtf=(@text == nil ? '' : @text.gsub("{", "\\{").gsub("}", "\\}").gsub("\\", "\\\\"))
        # Encode as Unicode.
        if RUBY_VERSION>"1.9.0"
          rtf.encode("UTF-16LE").each_codepoint.map {|cp|
            cp < 128 ? cp.chr : "\\u#{cp}\\'3f"
          }.join("")
        else
          rtf
        end
      end
   end # End of the TextNode class.


   # This class represents a Node that can contain other Node objects. Its a
   # base class for more specific Node types.
   class ContainerNode < Node
      include Enumerable

      # Children elements of the node
      attr_accessor :children

      # This is the constructor for the ContainerNode class.
      #
      # ==== Parameters
      # parent::     A reference to the parent node that owners the new
      #              ContainerNode object.
      def initialize(parent)
         super(parent)
         @children = []
         @children.concat(yield) if block_given?
      end

      # This method adds a new node element to the end of the list of nodes
      # maintained by a ContainerNode object. Nil objects are ignored.
      #
      # ==== Parameters
      # node::  A reference to the Node object to be added.
      def store(node)
         if node != nil
            @children.push(node) if @children.include?(Node) == false
            node.parent = self if node.parent != self
         end
         node
      end

      # This method fetches the first node child for a ContainerNode object. If
      # a container contains no children this method returns nil.
      def first
         @children[0]
      end

      # This method fetches the last node child for a ContainerNode object. If
      # a container contains no children this method returns nil.
      def last
         @children.last
      end

      # This method provides for iteration over the contents of a ContainerNode
      # object.
      def each
         @children.each {|child| yield child}
      end

      # This method returns a count of the number of children a ContainerNode
      # object contains.
      def size
         @children.size
      end

      # This method overloads the array dereference operator to allow for
      # access to the child elements of a ContainerNode object.
      #
      # ==== Parameters
      # index::  The offset from the first child of the child object to be
      #          returned. Negative index values work from the back of the
      #          list of children. An invalid index will cause a nil value
      #          to be returned.
      def [](index)
         @children[index]
      end

      # This method generates the RTF text for a ContainerNode object.
      def to_rtf
         RTFError.fire("#{self.class.name}.to_rtf method not yet implemented.")
      end
   end # End of the ContainerNode class.


   # This class represents a RTF command element within a document. This class
   # is concrete enough to be used on its own but will also be used as the
   # base class for some specific command node types.
   class CommandNode < ContainerNode
      # String containing the prefix text for the command
      attr_accessor :prefix
      # String containing the suffix text for the command
      attr_accessor :suffix
      # A boolean to indicate whether the prefix and suffix should
      # be written to separate lines whether the node is converted
      # to RTF. Defaults to true
      attr_accessor :split
      # A boolean to indicate whether the prefix and suffix should
      # be wrapped in curly braces. Defaults to true.
      attr_accessor :wrap

      # This is the constructor for the CommandNode class.
      #
      # ==== Parameters
      # parent::  A reference to the node that owns the new node.
      # prefix::  A String containing the prefix text for the command.
      # suffix::  A String containing the suffix text for the command. Defaults
      #           to nil.
      # split::   A boolean to indicate whether the prefix and suffix should
      #           be written to separate lines whether the node is converted
      #           to RTF. Defaults to true.
      # wrap::    A boolean to indicate whether the prefix and suffix should
      #           be wrapped in curly braces. Defaults to true.
      def initialize(parent, prefix, suffix=nil, split=true, wrap=true)
         super(parent)
         @prefix = prefix
         @suffix = suffix
         @split  = split
         @wrap   = wrap
      end

      # This method adds text to a command node. If the last child node of the
      # target node is a TextNode then the text is appended to that. Otherwise
      # a new TextNode is created and append to the node.
      #
      # ==== Parameters
      # text::  The String of text to be written to the node.
      def <<(text)
         if last != nil and last.respond_to?(:text=)
            last.append(text)
         else
            self.store(TextNode.new(self, text))
         end
      end

      # This method generates the RTF text for a CommandNode object.
      def to_rtf
         text = StringIO.new

         text << '{'       if wrap?
         text << @prefix   if @prefix

         self.each do |entry|
            text << "\n" if split?
            text << entry.to_rtf
         end

         text << "\n"    if split?
         text << @suffix if @suffix
         text << '}'     if wrap?

         text.string
      end

      # This method provides a short cut means of creating a paragraph command
      # node. The method accepts a block that will be passed a single parameter
      # which will be a reference to the paragraph node created. After the
      # block is complete the paragraph node is appended to the end of the child
      # nodes on the object that the method is called against.
      #
      # ==== Parameters
      # style::  A reference to a ParagraphStyle object that defines the style
      #          for the new paragraph. Defaults to nil to indicate that the
      #          currently applied paragraph styling should be used.
      def paragraph(style=nil)
         node = ParagraphNode.new(self, style)
         yield node if block_given?
         self.store(node)
      end

      # This method provides a short cut means of creating a new ordered or
      # unordered list. The method requires a block that will be passed a
      # single parameter that'll be a reference to the first level of the
      # list. See the +ListLevelNode+ doc for more information.
      #
      # Example usage:
      #
      #   rtf.list do |level1|
      #     level1.item do |li|
      #       li << 'some text'
      #       li.apply(some_style) {|x| x << 'some styled text'}
      #     end
      #
      #     level1.list(:decimal) do |level2|
      #       level2.item {|li| li << 'some other text in a decimal list'}
      #       level2.item {|li| li << 'and here we go'}
      #     end
      #   end
      #
      def list(kind=:bullets)
        node = ListNode.new(self)
        yield node.list(kind)
        self.store(node)
      end

      def link(url, text=nil)
        node = LinkNode.new(self, url)
        node << text if text
        yield node   if block_given?
        self.store(node)
      end

      # This method provides a short cut means of creating a line break command
      # node. This command node does not take a block and may possess no other
      # content.
      def line_break
         self.store(CommandNode.new(self, '\line', nil, false))
         nil
      end

      # This method inserts a footnote at the current position in a node.
      #
      # ==== Parameters
      # text::  A string containing the text for the footnote.
      def footnote(text)
         if text != nil && text != ''
            mark = CommandNode.new(self, '\fs16\up6\chftn', nil, false)
            note = CommandNode.new(self, '\footnote {\fs16\up6\chftn}', nil, false)
            note.paragraph << text
            self.store(mark)
            self.store(note)
         end
      end

      # This method inserts a new image at the current position in a node.
      #
      # ==== Parameters
      # source::  Either a string containing the path and name of a file or a
      #           File object for the image file to be inserted.
      #
      # ==== Exceptions
      # RTFError::  Generated whenever an invalid or inaccessible file is
      #             specified or the image file type is not supported.
      def image(source)
         self.store(ImageNode.new(self, source, root.get_id))
      end

      # This method provides a short cut means for applying multiple styles via
      # single command node. The method accepts a block that will be passed a
      # reference to the node created. Once the block is complete the new node
      # will be append as the last child of the CommandNode the method is called
      # on.
      #
      # ==== Parameters
      # style::  A reference to a CharacterStyle object that contains the style
      #          settings to be applied.
      #
      # ==== Exceptions
      # RTFError::  Generated whenever a non-character style is specified to
      #             the method.
      def apply(style)
         # Check the input style.
         if style.is_character_style? == false
            RTFError.fire("Non-character style specified to the "\
                          "CommandNode#apply() method.")
         end

         # Store fonts and colours.
         root.colours << style.foreground if style.foreground != nil
         root.colours << style.background if style.background != nil
         root.fonts << style.font if style.font != nil

         # Generate the command node.
         node = CommandNode.new(self, style.prefix(root.fonts, root.colours))
         yield node if block_given?
         self.store(node)
      end

      # This method provides a short cut means of creating a bold command node.
      # The method accepts a block that will be passed a single parameter which
      # will be a reference to the bold node created. After the block is
      # complete the bold node is appended to the end of the child nodes on
      # the object that the method is call against.
      def bold
         style      = CharacterStyle.new
         style.bold = true
         if block_given?
            apply(style) {|node| yield node}
         else
            apply(style)
         end
      end

      # This method provides a short cut means of creating an italic command
      # node. The method accepts a block that will be passed a single parameter
      # which will be a reference to the italic node created. After the block is
      # complete the italic node is appended to the end of the child nodes on
      # the object that the method is call against.
      def italic
         style        = CharacterStyle.new
         style.italic = true
         if block_given?
            apply(style) {|node| yield node}
         else
            apply(style)
         end
      end

      # This method provides a short cut means of creating an underline command
      # node. The method accepts a block that will be passed a single parameter
      # which will be a reference to the underline node created. After the block
      # is complete the underline node is appended to the end of the child nodes
      # on the object that the method is call against.
      def underline
         style           = CharacterStyle.new
         style.underline = true
         if block_given?
            apply(style) {|node| yield node}
         else
            apply(style)
         end
      end

      # This method provides a short cut means of creating a subscript command
      # node. The method accepts a block that will be passed a single parameter
      # which will be a reference to the subscript node created. After the
      # block is complete the subscript node is appended to the end of the
      # child nodes on the object that the method is call against.
      def subscript
         style           = CharacterStyle.new
         style.subscript = true
         if block_given?
            apply(style) {|node| yield node}
         else
            apply(style)
         end
      end

      # This method provides a short cut means of creating a superscript command
      # node. The method accepts a block that will be passed a single parameter
      # which will be a reference to the superscript node created. After the
      # block is complete the superscript node is appended to the end of the
      # child nodes on the object that the method is call against.
      def superscript
         style             = CharacterStyle.new
         style.superscript = true
         if block_given?
            apply(style) {|node| yield node}
         else
            apply(style)
         end
      end

      # This method provides a short cut means of creating a strike command
      # node. The method accepts a block that will be passed a single parameter
      # which will be a reference to the strike node created. After the
      # block is complete the strike node is appended to the end of the
      # child nodes on the object that the method is call against.
      def strike
         style        = CharacterStyle.new
         style.strike = true
         if block_given?
            apply(style) {|node| yield node}
         else
            apply(style)
         end
      end

      # This method provides a short cut means of creating a font command node.
      # The method accepts a block that will be passed a single parameter which
      # will be a reference to the font node created. After the block is
      # complete the font node is appended to the end of the child nodes on the
      # object that the method is called against.
      #
      # ==== Parameters
      # font::  A reference to font object that represents the font to be used
      #         within the node.
      # size::  An integer size setting for the font. Defaults to nil to
      #         indicate that the current font size should be used.
      def font(font, size=nil)
         style           = CharacterStyle.new
         style.font      = font
         style.font_size = size
         root.fonts << font
         if block_given?
            apply(style) {|node| yield node}
         else
            apply(style)
         end
      end

      # This method provides a short cut means of creating a foreground colour
      # command node. The method accepts a block that will be passed a single
      # parameter which will be a reference to the foreground colour node
      # created. After the block is complete the foreground colour node is
      # appended to the end of the child nodes on the object that the method
      # is called against.
      #
      # ==== Parameters
      # colour::  The foreground colour to be applied by the command.
      def foreground(colour)
         style            = CharacterStyle.new
         style.foreground = colour
         root.colours << colour
         if block_given?
            apply(style) {|node| yield node}
         else
            apply(style)
         end
      end

      # This method provides a short cut means of creating a background colour
      # command node. The method accepts a block that will be passed a single
      # parameter which will be a reference to the background colour node
      # created. After the block is complete the background colour node is
      # appended to the end of the child nodes on the object that the method
      # is called against.
      #
      # ==== Parameters
      # colour::  The background colour to be applied by the command.
      def background(colour)
         style            = CharacterStyle.new
         style.background = colour
         root.colours << colour
         if block_given?
            apply(style) {|node| yield node}
         else
            apply(style)
         end
      end

      # This method provides a short cut menas of creating a colour node that
      # deals with foreground and background colours. The method accepts a
      # block that will be passed a single parameter which will be a reference
      # to the colour node created. After the block is complete the colour node
      # is append to the end of the child nodes on the object that the method
      # is called against.
      #
      # ==== Parameters
      # fore::  The foreground colour to be applied by the command.
      # back::  The background colour to be applied by the command.
      def colour(fore, back)
         style            = CharacterStyle.new
         style.foreground = fore
         style.background = back
         root.colours << fore
         root.colours << back
         if block_given?
            apply(style) {|node| yield node}
         else
            apply(style)
         end
      end

      # This method creates a new table node and returns it. The method accepts
      # a block that will be passed the table as a parameter. The node is added
      # to the node the method is called upon after the block is complete.
      #
      # ==== Parameters
      # rows::     The number of rows that the table contains.
      # columns::  The number of columns that the table contains.
      # *widths::  One or more integers representing the widths for the table
      #            columns.
      def table(rows, columns, *widths)
         node = TableNode.new(self, rows, columns, *widths)
         yield node if block_given?
         store(node)
         node
      end

      alias :write  :<<
      alias :color  :colour
      alias :split? :split
      alias :wrap?  :wrap
   end # End of the CommandNode class.

   # This class represents a paragraph within an RTF document.
   class ParagraphNode < CommandNode
     def initialize(parent, style=nil)
       prefix = '\pard'
       prefix << style.prefix(nil, nil) if style

       super(parent, prefix, '\par')
     end
   end

   # This class represents an ordered/unordered list within an RTF document.
   #
   # Currently list nodes can contain any type of node, but this behaviour
   # will change in future releases. The class overrides the +list+ method
   # to return a +ListLevelNode+.
   #
   class ListNode < CommandNode
     def initialize(parent)
       prefix  = "\\"

       suffix  = '\pard'
       suffix << ListLevel::ResetTabs.map {|tw| "\\tx#{tw}"}.join
       suffix << '\ql\qlnatural\pardirnatural\cf0 \\'

       super(parent, prefix, suffix, true, false)

       @template = root.lists.new_template
     end

     # This method creates a new +ListLevelNode+ of the given kind and
     # stores it in the document tree.
     #
     # ==== Parameters
     # kind::  The kind of this list level, may be either :bullets or :decimal
     def list(kind)
       self.store ListLevelNode.new(self, @template, kind)
     end
   end

   # This class represents a list level, and carries out indenting information
   # and the bullet or number that is prepended to each +ListTextNode+.
   #
   # The class overrides the +list+ method to implement nesting, and provides
   # the +item+ method to add a new list item, the +ListTextNode+.
   class ListLevelNode < CommandNode
     def initialize(parent, template, kind, level=1)
       @template = template
       @kind     = kind
       @level    = template.level_for(level, kind)

       prefix  = '\pard'
       prefix << @level.tabs.map {|tw| "\\tx#{tw}"}.join
       prefix << "\\li#{@level.indent}\\fi-#{@level.indent}"
       prefix << "\\ql\\qlnatural\\pardirnatural\n"
       prefix << "\\ls#{@template.id}\\ilvl#{@level.level-1}\\cf0"

       super(parent, prefix, nil, true, false)
     end

     # Returns the kind of this level, either :bullets or :decimal
     attr_reader :kind

     # Returns the indenting level of this list, from 1 to 9
     def level
       @level.level
     end

     # Creates a new +ListTextNode+ and yields it to the calling block
     def item
       node = ListTextNode.new(self, @level)
       yield node
       self.store(node)
     end

     # Creates a new +ListLevelNode+ to implement nested lists
     def list(kind=@kind)
       node = ListLevelNode.new(self, @template, kind, @level.level+1)
       yield node
       self.store(node)
     end
   end

   # This class represents a list item, that can contain text or
   # other nodes. Currently any type of node is accepted, but after
   # more extensive testing this behaviour may change.
   class ListTextNode < CommandNode
     def initialize(parent, level)
       @level  = level
       @parent = parent

       number = siblings_count + 1 if parent.kind == :decimal
       prefix = "{\\listtext#{@level.marker.text_format(number)}}"
       suffix = '\\'

       super(parent, prefix, suffix, false, false)
     end

     private
       def siblings_count
         parent.children.select {|n| n.kind_of?(self.class)}.size
       end
   end

   class LinkNode < CommandNode
     def initialize(parent, url)
       prefix = "\\field{\\*\\fldinst HYPERLINK \"#{url}\"}{\\fldrslt "
       suffix = "}"

       super(parent, prefix, suffix, false)
     end
   end

   # This class represents a table node within an RTF document. Table nodes are
   # specialised container nodes that contain only TableRowNodes and have their
   # size specified when they are created an cannot be resized after that.
   class TableNode < ContainerNode
      # Cell margin. Default to 100
      attr_accessor :cell_margin
      
      # This is a constructor for the TableNode class.
      #
      # ==== Parameters
      # parent::   A reference to the node that owns the table.
      # rows::     The number of rows in the tabkle.
      # columns::  The number of columns in the table.
      # *widths::  One or more integers specifying the widths of the table
      #            columns.
      def initialize(parent, *args, &block)
        if args.size>=2
         rows=args.shift
         columns=args.shift
         widths=args
         super(parent) do
            entries = []
            rows.times {entries.push(TableRowNode.new(self, columns, *widths))}
            entries
         end
        
        elsif block
          block.arity<1 ? self.instance_eval(&block) : block.call(self)
        else
          raise "You should use 0 or >2 args"
        end
         @cell_margin = 100
      end

      # Attribute accessor.
      def rows
         entries.size
      end

      # Attribute accessor.
      def columns
         entries[0].length
      end

      # This method assigns a border width setting to all of the sides on all
      # of the cells within a table.
      #
      # ==== Parameters
      # width::  The border width setting to apply. Negative values are ignored
      #          and zero switches the border off.
      def border_width=(width)
         self.each {|row| row.border_width = width}
      end

      # This method assigns a shading colour to a specified row within a
      # TableNode object.
      #
      # ==== Parameters
      # index::   The offset from the first row of the row to have shading
      #           applied to it.
      # colour::  A reference to a Colour object representing the shading colour
      #           to be used. Set to nil to clear shading.
      def row_shading_colour(index, colour)
         row = self[index]
         row.shading_colour = colour if row != nil
      end

      # This method assigns a shading colour to a specified column within a
      # TableNode object.
      #
      # ==== Parameters
      # index::   The offset from the first column of the column to have shading
      #           applied to it.
      # colour::  A reference to a Colour object representing the shading colour
      #           to be used. Set to nil to clear shading.
      def column_shading_colour(index, colour)
         self.each do |row|
            cell = row[index]
            cell.shading_colour = colour if cell != nil
         end
      end

      # This method provides a means of assigning a shading colour to a
      # selection of cells within a table. The method accepts a block that
      # takes three parameters - a TableCellNode representing a cell within the
      # table, an integer representing the x offset of the cell and an integer
      # representing the y offset of the cell. If the block returns true then
      # shading will be applied to the cell.
      #
      # ==== Parameters
      # colour::  A reference to a Colour object representing the shading colour
      #           to be applied. Set to nil to remove shading.
      def shading_colour(colour)
         if block_given?
            0.upto(self.size - 1) do |x|
               row = self[x]
               0.upto(row.size - 1) do |y|
                  apply = yield row[y], x, y
                  row[y].shading_colour = colour if apply
               end
            end
         end
      end

      # This method overloads the store method inherited from the ContainerNode
      # class to forbid addition of further nodes.
      #
      # ==== Parameters
      # node::  A reference to the node to be added.
      def store(node)
         RTFError.fire("Table nodes cannot have nodes added to.")
      end

      # This method generates the RTF document text for a TableCellNode object.
      def to_rtf
         text = StringIO.new
         size = 0

         self.each do |row|
            if size > 0
               text << "\n"
            else
               size = 1
            end
            text << row.to_rtf
         end

         text.string
      end

      alias :column_shading_color :column_shading_colour
      alias :row_shading_color :row_shading_colour
      alias :shading_color :shading_colour
   end # End of the TableNode class.


   # This class represents a row within an RTF table. The TableRowNode is a
   # specialised container node that can hold only TableCellNodes and, once
   # created, cannot be resized. Its also not possible to change the parent
   # of a TableRowNode object.
   class TableRowNode < ContainerNode
      # This is the constructor for the TableRowNode class.
      #
      # ===== Parameters
      # table::   A reference to table that owns the row.
      # cells::   The number of cells that the row will contain.
      # widths::  One or more integers specifying the widths for the table
      #           columns
      def initialize(table, cells, *widths)
         super(table) do
            entries = []
            cells.times do |index|
               entries.push(TableCellNode.new(self, widths[index]))
            end
            entries
         end
      end

      # Attribute accessors
      def length
         entries.size
      end

      # This method assigns a border width setting to all of the sides on all
      # of the cells within a table row.
      #
      # ==== Parameters
      # width::  The border width setting to apply. Negative values are ignored
      #          and zero switches the border off.
      def border_width=(width)
         self.each {|cell| cell.border_width = width}
      end

      # This method overloads the parent= method inherited from the Node class
      # to forbid the alteration of the cells parent.
      #
      # ==== Parameters
      # parent::  A reference to the new node parent.
      def parent=(parent)
         RTFError.fire("Table row nodes cannot have their parent changed.")
      end

      # This method sets the shading colour for a row.
      #
      # ==== Parameters
      # colour::  A reference to the Colour object that represents the new
      #           shading colour. Set to nil to switch shading off.
      def shading_colour=(colour)
         self.each {|cell| cell.shading_colour = colour}
      end

      # This method overloads the store method inherited from the ContainerNode
      # class to forbid addition of further nodes.
      #
      # ==== Parameters
      # node::  A reference to the node to be added.
      #def store(node)
      #   RTFError.fire("Table row nodes cannot have nodes added to.")
      #end

      # This method generates the RTF document text for a TableCellNode object.
      def to_rtf
         text   = StringIO.new
         temp   = StringIO.new
         offset = 0

         text << "\\trowd\\tgraph#{parent.cell_margin}"
         self.each do |entry|
            widths = entry.border_widths
            colour = entry.shading_colour

            text << "\n"
            text << "\\clbrdrt\\brdrw#{widths[0]}\\brdrs" if widths[0] != 0
            text << "\\clbrdrl\\brdrw#{widths[3]}\\brdrs" if widths[3] != 0
            text << "\\clbrdrb\\brdrw#{widths[2]}\\brdrs" if widths[2] != 0
            text << "\\clbrdrr\\brdrw#{widths[1]}\\brdrs" if widths[1] != 0
            text << "\\clcbpat#{root.colours.index(colour)}" if colour != nil
            text << "\\cellx#{entry.width + offset}"
            temp << "\n#{entry.to_rtf}"
            offset += entry.width
         end
         text << "#{temp.string}\n\\row"

         text.string
      end
   end # End of the TableRowNode class.


   # This class represents a cell within an RTF table. The TableCellNode is a
   # specialised command node that is forbidden from creating tables or having
   # its parent changed.
   class TableCellNode < CommandNode
      # A definition for the default width for the cell.
      DEFAULT_WIDTH                              = 300
      # Width of cell
      attr_accessor :width
      # Attribute accessor.
      attr_reader :shading_colour, :style
      
      # This is the constructor for the TableCellNode class.
      #
      # ==== Parameters
      # row::     The row that the cell belongs to.
      # width::   The width to be assigned to the cell. This defaults to
      #           TableCellNode::DEFAULT_WIDTH.
      # style::   The style that is applied to the cell. This must be a
      #           ParagraphStyle class. Defaults to nil.
      # top::     The border width for the cells top border. Defaults to nil.
      # right::   The border width for the cells right hand border. Defaults to
      #           nil.
      # bottom::  The border width for the cells bottom border. Defaults to nil.
      # left::    The border width for the cells left hand border. Defaults to
      #           nil.
      #
      # ==== Exceptions
      # RTFError::  Generated whenever an invalid style setting is specified.
      def initialize(row, width=DEFAULT_WIDTH, style=nil, top=nil, right=nil,
                     bottom=nil, left=nil)
         super(row, nil)
         if style != nil && style.is_paragraph_style? == false
            RTFError.fire("Non-paragraph style specified for TableCellNode "\
                          "constructor.")
         end

         @width          = (width != nil && width > 0) ? width : DEFAULT_WIDTH
         @borders        = [(top != nil && top > 0) ? top : nil,
                            (right != nil && right > 0) ? right : nil,
                            (bottom != nil && bottom > 0) ? bottom : nil,
                            (left != nil && left > 0) ? left : nil]
         @shading_colour = nil
         @style          = style
      end

      # Attribute mutator.
      #
      # ==== Parameters
      # style::  A reference to the style object to be applied to the cell.
      #          Must be an instance of the ParagraphStyle class. Set to nil
      #          to clear style settings.
      #
      # ==== Exceptions
      # RTFError::  Generated whenever an invalid style setting is specified.
      def style=(style)
         if style != nil && style.is_paragraph_style? == false
            RTFError.fire("Non-paragraph style specified for TableCellNode "\
                          "constructor.")
         end
         @style = style
      end

      # This method assigns a width, in twips, for the borders on all sides of
      # the cell. Negative widths will be ignored and a width of zero will
      # switch the border off.
      #
      # ==== Parameters
      # width::  The setting for the width of the border.
      def border_width=(width)
         size = width == nil ? 0 : width
         if size > 0
            @borders[0] = @borders[1] = @borders[2] = @borders[3] = size.to_i
         else
            @borders = [nil, nil, nil, nil]
         end
      end

      # This method assigns a border width to the top side of a table cell.
      # Negative values are ignored and a value of 0 switches the border off.
      #
      # ==== Parameters
      # width::  The new border width setting.
      def top_border_width=(width)
         size = width == nil ? 0 : width
         if size > 0
            @borders[0] = size.to_i
         else
            @borders[0] = nil
         end
      end

      # This method assigns a border width to the right side of a table cell.
      # Negative values are ignored and a value of 0 switches the border off.
      #
      # ==== Parameters
      # width::  The new border width setting.
      def right_border_width=(width)
         size = width == nil ? 0 : width
         if size > 0
            @borders[1] = size.to_i
         else
            @borders[1] = nil
         end
      end

      # This method assigns a border width to the bottom side of a table cell.
      # Negative values are ignored and a value of 0 switches the border off.
      #
      # ==== Parameters
      # width::  The new border width setting.
      def bottom_border_width=(width)
         size = width == nil ? 0 : width
         if size > 0
            @borders[2] = size.to_i
         else
            @borders[2] = nil
         end
      end

      # This method assigns a border width to the left side of a table cell.
      # Negative values are ignored and a value of 0 switches the border off.
      #
      # ==== Parameters
      # width::  The new border width setting.
      def left_border_width=(width)
         size = width == nil ? 0 : width
         if size > 0
            @borders[3] = size.to_i
         else
            @borders[3] = nil
         end
      end

      # This method alters the shading colour associated with a TableCellNode
      # object.
      #
      # ==== Parameters
      # colour::  A reference to the Colour object to use in shading the cell.
      #           Assign nil to clear cell shading.
      def shading_colour=(colour)
         root.colours << colour
         @shading_colour = colour
      end

      # This method retrieves an array with the cell border width settings.
      # The values are inserted in top, right, bottom, left order.
      def border_widths
         widths = []
         @borders.each {|entry| widths.push(entry == nil ? 0 : entry)}
         widths
      end

      # This method fetches the width for top border of a cell.
      def top_border_width
         @borders[0] == nil ? 0 : @borders[0]
      end

      # This method fetches the width for right border of a cell.
      def right_border_width
         @borders[1] == nil ? 0 : @borders[1]
      end

      # This method fetches the width for bottom border of a cell.
      def bottom_border_width
         @borders[2] == nil ? 0 : @borders[2]
      end

      # This method fetches the width for left border of a cell.
      def left_border_width
         @borders[3] == nil ? 0 : @borders[3]
      end

      # This method overloads the paragraph method inherited from the
      # ComamndNode class to forbid the creation of paragraphs.
      #
      # ==== Parameters
      # style::  The paragraph style, ignored
      def paragraph(style=nil)
         RTFError.fire("TableCellNode#paragraph() called. Table cells cannot "\
                       "contain paragraphs.")
      end

      # This method overloads the parent= method inherited from the Node class
      # to forbid the alteration of the cells parent.
      #
      # ==== Parameters
      # parent::  A reference to the new node parent.
      def parent=(parent)
         RTFError.fire("Table cell nodes cannot have their parent changed.")
      end

      # This method overrides the table method inherited from CommandNode to
      # forbid its use in table cells.
      #
      # ==== Parameters
      # rows::     The number of rows for the table.
      # columns::  The number of columns for the table.
      # *widths::  One or more integers representing the widths for the table
      #            columns.
      def table(rows, columns, *widths)
         RTFError.fire("TableCellNode#table() called. Nested tables not allowed.")
      end

      # This method generates the RTF document text for a TableCellNode object.
      def to_rtf
         text      = StringIO.new
         separator = split? ? "\n" : " "
         line      = (separator == " ")

         text << "\\pard\\intbl"
         text << @style.prefix(nil, nil) if @style != nil
         text << separator
         self.each do |entry|
            text << "\n" if line
            line = true
            text << entry.to_rtf
         end
         text << (split? ? "\n" : " ")
         text << "\\cell"

         text.string
      end
   end # End of the TableCellNode class.


   # This class represents a document header.
   class HeaderNode < CommandNode
      # A definition for a header type.
      UNIVERSAL                                  = :header

      # A definition for a header type.
      LEFT_PAGE                                  = :headerl

      # A definition for a header type.
      RIGHT_PAGE                                 = :headerr

      # A definition for a header type.
      FIRST_PAGE                                 = :headerf

      # Attribute accessor.
      attr_reader :type

      # Attribute mutator.
      attr_writer :type


      # This is the constructor for the HeaderNode class.
      #
      # ==== Parameters
      # document::  A reference to the Document object that will own the new
      #             header.
      # type::      The style type for the new header. Defaults to a value of
      #             HeaderNode::UNIVERSAL.
      def initialize(document, type=UNIVERSAL)
         super(document, "\\#{type.id2name}", nil, false)
         @type = type
      end

      # This method overloads the footnote method inherited from the CommandNode
      # class to prevent footnotes being added to headers.
      #
      # ==== Parameters
      # text::  Not used.
      #
      # ==== Exceptions
      # RTFError::  Always generated whenever this method is called.
      def footnote(text)
         RTFError.fire("Footnotes are not permitted in page headers.")
      end
   end # End of the HeaderNode class.


   # This class represents a document footer.
   class FooterNode < CommandNode
      # A definition for a header type.
      UNIVERSAL                                  = :footer

      # A definition for a header type.
      LEFT_PAGE                                  = :footerl

      # A definition for a header type.
      RIGHT_PAGE                                 = :footerr

      # A definition for a header type.
      FIRST_PAGE                                 = :footerf

      # Attribute accessor.
      attr_reader :type

      # Attribute mutator.
      attr_writer :type


      # This is the constructor for the FooterNode class.
      #
      # ==== Parameters
      # document::  A reference to the Document object that will own the new
      #             footer.
      # type::      The style type for the new footer. Defaults to a value of
      #             FooterNode::UNIVERSAL.
      def initialize(document, type=UNIVERSAL)
         super(document, "\\#{type.id2name}", nil, false)
         @type = type
      end

      # This method overloads the footnote method inherited from the CommandNode
      # class to prevent footnotes being added to footers.
      #
      # ==== Parameters
      # text::  Not used.
      #
      # ==== Exceptions
      # RTFError::  Always generated whenever this method is called.
      def footnote(text)
         RTFError.fire("Footnotes are not permitted in page footers.")
      end
   end # End of the FooterNode class.


   # This class represents an image within a RTF document. Currently only the
   # PNG, JPEG and Windows Bitmap formats are supported. Efforts are made to
   # identify the file type but these are not guaranteed to work.
   class ImageNode < Node
      # A definition for an image type constant.
      PNG                                        = :pngblip

      # A definition for an image type constant.
      JPEG                                       = :jpegblip

      # A definition for an image type constant.
      BITMAP                                     = :dibitmap0

      # A definition for an architecture endian constant.
      LITTLE_ENDIAN                              = :little

      # A definition for an architecture endian constant.
      BIG_ENDIAN                                 = :big

      # Attribute accessor.
      attr_reader :x_scaling, :y_scaling, :top_crop, :right_crop, :bottom_crop,
                  :left_crop, :width, :height

      # Attribute mutator.
      attr_writer :x_scaling, :y_scaling, :top_crop, :right_crop, :bottom_crop,
                  :left_crop


      # This is the constructor for the ImageNode class.
      #
      # ==== Parameters
      # parent::  A reference to the node that owns the new image node.
      # source::  A reference to the image source. This must be a String or a
      #           File.
      # id::      The unique identifier for the image node.
      #
      # ==== Exceptions
      # RTFError::  Generated whenever the image specified is not recognised as
      #             a supported image type, something other than a String or
      #             File or IO is passed as the source parameter or if the
      #             specified source does not exist or cannot be accessed.
      def initialize(parent, source, id)
         super(parent)
         @source = nil
         @id     = id
         @read   = []
         @type   = nil
         @x_scaling = @y_scaling = nil
         @top_crop = @right_crop = @bottom_crop = @left_crop = nil
         @width = @height = nil

         # Check what we were given.
         src = source
         src.binmode if src.instance_of?(File)
         src = File.new(source, 'rb') if source.instance_of?(String)
         if src.instance_of?(File)
            # Check the files existence and accessibility.
            if !File.exist?(src.path)
               RTFError.fire("Unable to find the #{File.basename(source)} file.")
            end
            if !File.readable?(src.path)
               RTFError.fire("Access to the #{File.basename(source)} file denied.")
            end
            @source = src
         else
            RTFError.fire("Unrecognised source specified for ImageNode.")
         end

         @type = get_file_type(src)
         if @type == nil
            RTFError.fire("The #{File.basename(source)} file contains an "\
                          "unknown or unsupported image type.")
         end

         @width, @height = get_dimensions
      end

      # This method attempts to determine the image type associated with a
      # file, returning nil if it fails to make the determination.
      #
      # ==== Parameters
      # file::  A reference to the file to check for image type.
      def get_file_type(file)
         type = nil

         # Check if the file is a JPEG.
         read_source(2)

         if @read[0,2] == [255, 216]
            type = JPEG
         else
            # Check if it's a PNG.
            read_source(6)
            if @read[0,8] == [137, 80, 78, 71, 13, 10, 26, 10]
               type = PNG
            else
               # Check if its a bitmap.
               if @read[0,2] == [66, 77]
                  size = to_integer(@read[2,4])
                  type = BITMAP if size == File.size(file.path)
               end
            end
         end

         type
      end

      # This method generates the RTF for an ImageNode object.
      def to_rtf
         text  = StringIO.new
         count = 0

         #text << '{\pard{\*\shppict{\pict'
         text << '{\*\shppict{\pict'
         text << "\\picscalex#{@x_scaling}" if @x_scaling != nil
         text << "\\picscaley#{@y_scaling}" if @y_scaling != nil
         text << "\\piccropl#{@left_crop}" if @left_crop != nil
         text << "\\piccropr#{@right_crop}" if @right_crop != nil
         text << "\\piccropt#{@top_crop}" if @top_crop != nil
         text << "\\piccropb#{@bottom_crop}" if @bottom_crop != nil
         text << "\\picw#{@width}\\pich#{@height}\\bliptag#{@id}"
         text << "\\#{@type.id2name}\n"
         @source.each_byte {|byte| @read << byte} if @source.eof? == false
         @read.each do |byte|
            text << ("%02x" % byte)
            count += 1
            if count == 40
               text << "\n"
               count = 0
            end
         end
         #text << "\n}}\\par}"
         text << "\n}}"

         text.string
      end

      # This method is used to determine the underlying endianness of a
      # platform.
      def get_endian
         [0, 125].pack('c2').unpack('s') == [125] ? BIG_ENDIAN : LITTLE_ENDIAN
      end

      # This method converts an array to an integer. The array must be either
      # two or four bytes in length.
      #
      # ==== Parameters
      # array::    A reference to the array containing the data to be converted.
      # signed::   A boolean to indicate whether the value is signed. Defaults
      #            to false.
      def to_integer(array, signed=false)
         from = nil
         to   = nil
         data = []

         if array.size == 2
            data.concat(get_endian == BIG_ENDIAN ? array.reverse : array)
            from = 'C2'
            to   = signed ? 's' : 'S'
         else
            data.concat(get_endian == BIG_ENDIAN ? array[0,4].reverse : array)
            from = 'C4'
            to   = signed ? 'l' : 'L'
         end
         data.pack(from).unpack(to)[0]
      end

      # This method loads the data for an image from its source. The method
      # accepts two call approaches. If called without a block then the method
      # considers the size parameter it is passed. If called with a block the
      # method executes until the block returns true.
      #
      # ==== Parameters
      # size::  The maximum number of bytes to be read from the file. Defaults
      #         to nil to indicate that the remainder of the file should be read
      #         in.
      def read_source(size=nil)
         if block_given?
            done = false

            while done == false && @source.eof? == false
              @read << @source.getbyte
               done = yield @read[-1]
            end
         else
            if size != nil
               if size > 0
                  total = 0
                  while @source.eof? == false && total < size
					  
                     @read << @source.getbyte
                     total += 1
                  end
               end
            else
               @source.each_byte {|byte| @read << byte}
            end
         end
      end

      # This method fetches details of the dimensions associated with an image.
      def get_dimensions
         dimensions = nil

         # Check the image type.
         if @type == JPEG
            # Read until we can't anymore or we've found what we're looking for.
            done = false
            while @source.eof? == false && done == false
               # Read to the next marker.
               read_source {|c| c == 0xff} # Read to the marker.
               read_source {|c| c != 0xff} # Skip any padding.

               if @read[-1] >= 0xc0 && @read[-1] <= 0xc3
                  # Read in the width and height details.
                  read_source(7)
                  dimensions = @read[-4,4].pack('C4').unpack('nn').reverse
                  done       = true
               else
                  # Skip the marker block.
                  read_source(2)
                  read_source(@read[-2,2].pack('C2').unpack('n')[0] - 2)
               end
            end
         elsif @type == PNG
            # Read in the data to contain the width and height.
            read_source(16)
            dimensions = @read[-8,8].pack('C8').unpack('N2')
         elsif @type == BITMAP
            # Read in the data to contain the width and height.
            read_source(18)
            dimensions = [to_integer(@read[-8,4]), to_integer(@read[-4,4])]
         end

         dimensions
      end

      private :read_source, :get_file_type, :to_integer, :get_endian,
              :get_dimensions
   end # End of the ImageNode class.


   # This class represents an RTF document. In actuality it is just a
   # specialised Node type that cannot be assigned a parent and that holds
   # document font, colour and information tables.
   class Document < CommandNode
      # A definition for a document character set setting.
      CS_ANSI                          = :ansi

      # A definition for a document character set setting.
      CS_MAC                           = :mac

      # A definition for a document character set setting.
      CS_PC                            = :pc

      # A definition for a document character set setting.
      CS_PCA                           = :pca

      # A definition for a document language setting.
      LC_AFRIKAANS                     = 1078

      # A definition for a document language setting.
      LC_ARABIC                        = 1025

      # A definition for a document language setting.
      LC_CATALAN                       = 1027

      # A definition for a document language setting.
      LC_CHINESE_TRADITIONAL           = 1028

      # A definition for a document language setting.
      LC_CHINESE_SIMPLIFIED            = 2052

      # A definition for a document language setting.
      LC_CZECH                         = 1029

      # A definition for a document language setting.
      LC_DANISH                        = 1030

      # A definition for a document language setting.
      LC_DUTCH                         = 1043

      # A definition for a document language setting.
      LC_DUTCH_BELGIAN                 = 2067

      # A definition for a document language setting.
      LC_ENGLISH_UK                    = 2057

      # A definition for a document language setting.
      LC_ENGLISH_US                    = 1033

      # A definition for a document language setting.
      LC_FINNISH                       = 1035

      # A definition for a document language setting.
      LC_FRENCH                        = 1036

      # A definition for a document language setting.
      LC_FRENCH_BELGIAN                = 2060

      # A definition for a document language setting.
      LC_FRENCH_CANADIAN               = 3084

      # A definition for a document language setting.
      LC_FRENCH_SWISS                  = 4108

      # A definition for a document language setting.
      LC_GERMAN                        = 1031

      # A definition for a document language setting.
      LC_GERMAN_SWISS                  = 2055

      # A definition for a document language setting.
      LC_GREEK                         = 1032

      # A definition for a document language setting.
      LC_HEBREW                        = 1037

      # A definition for a document language setting.
      LC_HUNGARIAN                     = 1038

      # A definition for a document language setting.
      LC_ICELANDIC                     = 1039

      # A definition for a document language setting.
      LC_INDONESIAN                    = 1057

      # A definition for a document language setting.
      LC_ITALIAN                       = 1040

      # A definition for a document language setting.
      LC_JAPANESE                      = 1041

      # A definition for a document language setting.
      LC_KOREAN                        = 1042

      # A definition for a document language setting.
      LC_NORWEGIAN_BOKMAL              = 1044

      # A definition for a document language setting.
      LC_NORWEGIAN_NYNORSK             = 2068

      # A definition for a document language setting.
      LC_POLISH                        = 1045

      # A definition for a document language setting.
      LC_PORTUGUESE                    = 2070

      # A definition for a document language setting.
      LC_POTUGUESE_BRAZILIAN           = 1046

      # A definition for a document language setting.
      LC_ROMANIAN                      = 1048

      # A definition for a document language setting.
      LC_RUSSIAN                       = 1049

      # A definition for a document language setting.
      LC_SERBO_CROATIAN_CYRILLIC       = 2074

      # A definition for a document language setting.
      LC_SERBO_CROATIAN_LATIN          = 1050

      # A definition for a document language setting.
      LC_SLOVAK                        = 1051

      # A definition for a document language setting.
      LC_SPANISH_CASTILLIAN            = 1034

      # A definition for a document language setting.
      LC_SPANISH_MEXICAN               = 2058

      # A definition for a document language setting.
      LC_SWAHILI                       = 1089

      # A definition for a document language setting.
      LC_SWEDISH                       = 1053

      # A definition for a document language setting.
      LC_THAI                          = 1054

      # A definition for a document language setting.
      LC_TURKISH                       = 1055

      # A definition for a document language setting.
      LC_UNKNOWN                       = 1024

      # A definition for a document language setting.
      LC_VIETNAMESE                    = 1066

      # Attribute accessor.
      attr_reader :fonts, :lists, :colours, :information, :character_set,
                  :language, :style

      # Attribute mutator.
      attr_writer :character_set, :language


      # This is a constructor for the Document class.
      #
      # ==== Parameters
      # font::       The default font to be used by the document.
      # style::      The style settings to be applied to the document. This
      #              defaults to nil.
      # character::  The character set to be applied to the document. This
      #              defaults to Document::CS_ANSI.
      # language::   The language setting to be applied to document. This
      #              defaults to Document::LC_ENGLISH_UK.
      def initialize(font, style=nil, character=CS_ANSI, language=LC_ENGLISH_UK)
         super(nil, '\rtf1')
         @fonts         = FontTable.new(font)
         @lists         = ListTable.new
         @default_font  = 0
         @colours       = ColourTable.new
         @information   = Information.new
         @character_set = character
         @language      = language
         @style         = style == nil ? DocumentStyle.new : style
         @headers       = [nil, nil, nil, nil]
         @footers       = [nil, nil, nil, nil]
         @id            = 0
      end

      # This method provides a method that can be called to generate an
      # identifier that is unique within the document.
      def get_id
         @id += 1
         Time.now().strftime('%d%m%y') + @id.to_s
      end

      # Attribute accessor.
      def default_font
         @fonts[@default_font]
      end

      # This method assigns a new header to a document. A Document object can
      # have up to four header - a default header, a header for left pages, a
      # header for right pages and a header for the first page. The method
      # checks the header type and stores it appropriately.
      #
      # ==== Parameters
      # header::  A reference to the header object to be stored. Existing header
      #           objects are overwritten.
      def header=(header)
         if header.type == HeaderNode::UNIVERSAL
            @headers[0] = header
         elsif header.type == HeaderNode::LEFT_PAGE
            @headers[1] = header
         elsif header.type == HeaderNode::RIGHT_PAGE
            @headers[2] = header
         elsif header.type == HeaderNode::FIRST_PAGE
            @headers[3] = header
         end
      end

      # This method assigns a new footer to a document. A Document object can
      # have up to four footers - a default footer, a footer for left pages, a
      # footer for right pages and a footer for the first page. The method
      # checks the footer type and stores it appropriately.
      #
      # ==== Parameters
      # footer::  A reference to the footer object to be stored. Existing footer
      #           objects are overwritten.
      def footer=(footer)
         if footer.type == FooterNode::UNIVERSAL
            @footers[0] = footer
         elsif footer.type == FooterNode::LEFT_PAGE
            @footers[1] = footer
         elsif footer.type == FooterNode::RIGHT_PAGE
            @footers[2] = footer
         elsif footer.type == FooterNode::FIRST_PAGE
            @footers[3] = footer
         end
      end

      # This method fetches a header from a Document object.
      #
      # ==== Parameters
      # type::  One of the header types defined in the header class. Defaults to
      #         HeaderNode::UNIVERSAL.
      def header(type=HeaderNode::UNIVERSAL)
         index = 0
         if type == HeaderNode::LEFT_PAGE
            index = 1
         elsif type == HeaderNode::RIGHT_PAGE
            index = 2
         elsif type == HeaderNode::FIRST_PAGE
            index = 3
         end
         @headers[index]
      end

      # This method fetches a footer from a Document object.
      #
      # ==== Parameters
      # type::  One of the footer types defined in the footer class. Defaults to
      #         FooterNode::UNIVERSAL.
      def footer(type=FooterNode::UNIVERSAL)
         index = 0
         if type == FooterNode::LEFT_PAGE
            index = 1
         elsif type == FooterNode::RIGHT_PAGE
            index = 2
         elsif type == FooterNode::FIRST_PAGE
            index = 3
         end
         @footers[index]
      end

      # Attribute mutator.
      #
      # ==== Parameters
      # font::  The new default font for the Document object.
      def default_font=(font)
         @fonts << font
         @default_font = @fonts.index(font)
      end

      # This method provides a short cut for obtaining the Paper object
      # associated with a Document object.
      def paper
         @style.paper
      end

      # This method overrides the parent=() method inherited from the
      # CommandNode class to disallow setting a parent on a Document object.
      #
      # ==== Parameters
      # parent::  A reference to the new parent node for the Document object.
      #
      # ==== Exceptions
      # RTFError::  Generated whenever this method is called.
      def parent=(parent)
         RTFError.fire("Document objects may not have a parent.")
      end

      # This method inserts a page break into a document.
      def page_break
         self.store(CommandNode.new(self, '\page', nil, false))
         nil
      end

      # This method fetches the width of the available work area space for a
      # typical Document object page.
      def body_width
         @style.body_width
      end

      # This method fetches the height of the available work area space for a
      # a typical Document object page.
      def body_height
         @style.body_height
      end

      # This method generates the RTF text for a Document object.
      def to_rtf
         text = StringIO.new

         text << "{#{prefix}\\#{@character_set.id2name}"
         text << "\\deff#{@default_font}"
         text << "\\deflang#{@language}" if @language != nil
         text << "\\plain\\fs24\\fet1"
         text << "\n#{@fonts.to_rtf}"
         text << "\n#{@colours.to_rtf}" if @colours.size > 0
         text << "\n#{@information.to_rtf}"
         text << "\n#{@lists.to_rtf}"
         if @headers.compact != []
            text << "\n#{@headers[3].to_rtf}" if @headers[3] != nil
            text << "\n#{@headers[2].to_rtf}" if @headers[2] != nil
            text << "\n#{@headers[1].to_rtf}" if @headers[1] != nil
            if @headers[1] == nil or @headers[2] == nil
               text << "\n#{@headers[0].to_rtf}"
            end
         end
         if @footers.compact != []
            text << "\n#{@footers[3].to_rtf}" if @footers[3] != nil
            text << "\n#{@footers[2].to_rtf}" if @footers[2] != nil
            text << "\n#{@footers[1].to_rtf}" if @footers[1] != nil
            if @footers[1] == nil or @footers[2] == nil
               text << "\n#{@footers[0].to_rtf}"
            end
         end
         text << "\n#{@style.prefix(self)}" if @style != nil
         self.each {|entry| text << "\n#{entry.to_rtf}"}
         text << "\n}"

         text.string
      end
   end # End of the Document class.
end # End of the RTF module.
