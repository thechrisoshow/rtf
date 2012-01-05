module RTF
  class ListTable
    def initialize
      @templates = []
    end

    def new_template
      @templates.push ListTemplate.new(next_template_id)
      @templates.last
    end

    def to_rtf(indent=0)
      return '' if @templates.empty?

      prefix = indent > 0 ? ' ' * indent : ''

      # List table
      text = "#{prefix}{\\*\\listtable"
      @templates.each {|tpl| text << tpl.to_rtf}
      text << "}"

      # List override table, a Cargo Cult.
      text << "#{prefix}{\\*\\listoverridetable"
      @templates.each do |tpl|
        text << "{\\listoverride\\listid#{tpl.id}\\listoverridecount0\\ls#{tpl.id}}"
      end
      text << "}\n"
    end

    protected
      def next_template_id
        @templates.size + 1
      end

  end

  class ListMarker
    def initialize(name, codepoint=nil)
      @name      = name
      @codepoint = codepoint
    end

    def bullet?
      !@codepoint.nil?
    end

    def type
      bullet? ? :bullet : :decimal
    end

    def number_type
      # 23: bullet, 0: arabic
      # applies to the \levelnfcN macro
      #
      bullet? ? 23 : 0
    end

    def name
      name  = "\\{#@name\\}"
      name << '.' unless bullet?
      name
    end

    def template_format
      # The first char is the string size, the next ones are
      # either placeholders (\'0X) or actual characters to
      # include in the format. In the bullet case, \uc0 is
      # used to get rid of the multibyte translation: we want
      # an Unicode character.
      #
      # In the decimal case, we have a fixed format, with a
      # dot following the actual number.
      #
      if bullet?
        "\\'01\\uc0\\u#@codepoint"
      else
        "\\'02\\'00. "
      end
    end

    def text_format(n=nil)
      text = 
        if bullet?
          "\\uc0\\u#@codepoint"
        else
          "#{n}."
        end

      "\t#{text}\t"
    end
  end

  class ListTemplate
    attr_reader :id

    Markers = {
      :disc    => ListMarker.new('disc',    0x2022),
      :hyphen  => ListMarker.new('hyphen',  0x2043),
      :decimal => ListMarker.new('decimal'        )
    }

    def initialize(id)
      @levels = []
      @id     = id
    end

    def level_for(level, kind = :bullets)
      @levels[level-1] ||= begin
        # Only disc for now: we'll add support
        # for more customization options later
        marker = Markers[kind == :bullets ? :disc : :decimal]
        ListLevel.new(self, marker, level)
      end
    end

    def to_rtf(indent=0)
      prefix = indent > 0 ? ' ' * indent : ''

      text = "#{prefix}{\\list\\listtemplate#{id}\\listhybrid"
      @levels.each {|lvl| text << lvl.to_rtf}
      text << "{\\listname;}\\listid#{id}}\n"

      text
    end
  end

  class ListLevel
    ValidLevels = (1..9)

    LevelTabs = [
      220,  720,  1133, 1700, 2267,
      2834, 3401, 3968, 4535, 5102,
      5669, 6236, 6803
    ].freeze

    ResetTabs = [560].concat(LevelTabs[2..-1]).freeze

    attr_reader :level, :marker

    def initialize(template, marker, level)
      unless marker.kind_of? ListMarker
        RTFError.fire("Invalid marker #{marker.inspect}")
      end

      unless ValidLevels.include? level
        RTFError.fire("Invalid list level: #{level}")
      end

      @template = template 
      @level    = level
      @marker   = marker
    end

    def type
      @marker.type
    end

    def reset_tabs
      ResetTabs
    end

    def tabs
      @tabs ||= begin
        tabs = LevelTabs.dup # Kernel#tap would be prettier here

        (@level - 1).times do
          # Reverse-engineered while looking at Textedit.app
          # generated output: they already made sure that it
          # would look good on every RTF editor :-p
          #
          a,  = tabs.shift(3)
          a,b = a + 720, a + 1220 
          tabs.shift while tabs.first < b
          tabs.unshift a, b
        end

        tabs
      end
    end

    def id
      @id ||= @template.id * 10 + level
    end

    def indent
      @indent ||= level * 720
    end

    def to_rtf(indent=0)
      prefix = indent > 0 ? ' ' * indent : ''

      text  = "#{prefix}{\\listlevel\\levelstartat1"
      
      # Marker type. The first declaration is for Backward Compatibility (BC).
      nfc  = @marker.number_type
      text << "\\levelnfc#{nfc}\\levelnfcn#{nfc}"

      # Justification, currently only left justified (0). First decl for BC.
      text << '\leveljc0\leveljcn0'

      # Character that follows the level text, currently only TAB.
      text << '\levelfollow0'

      # BC: Minimum distance from the left & right edges.
      text << '\levelindent0\levelspace360'

      # Marker name
      text << "{\\*\\levelmarker #{@marker.name}}"

      # Marker text format
      text << "{\\leveltext\\leveltemplateid#{id}#{@marker.template_format};}"
      text << '{\levelnumbers;}'

      # The actual spacing
      text << "\\fi-360\\li#{self.indent}\\lin#{self.indent}}\n"
    end

  end
end
