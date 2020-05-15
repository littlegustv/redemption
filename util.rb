class Integer

    def ordinalize
        if (11..13).include?(self % 100)
            "#{self}th"
        else
        case self % 10
            when 1; "#{self}st"
            when 2; "#{self}nd"
            when 3; "#{self}rd"
            else    "#{self}th"
        end
      end
    end

    def gold
        ( self / 1000 ).floor
    end

    def silver
        ( self - gold * 1000 )
    end

    def to_worth
        self.gold > 0 ? "#{ self.gold } gold and #{ self.silver } silver" : "#{ self.silver } silver"
    end

    def to_b
        !self.zero?
    end

end

class Array

    def each_output( message, objects = [], send_to_sleeping: false )
        targets = self.select{ |t| t.instance_of? Player }
        if targets.size == 0
            return
        end
        if !send_to_sleeping
            targets.reject!{ |t| t.position == :sleeping }
        end
        targets.each do | player |
            player.output( message, objects.to_a )
        end
    end

    def to_list(conjunction = nil, separator = ",")
        if conjunction.to_s.strip.length > 0
            conjunction = " #{conjunction}"
        else
            conjunction = ""
        end
        case self.size
        when 0
            return ""
        when 1
            return self.first.to_s
        when 2
            return "#{self[0]}#{conjunction} #{self[1]}"
        else
            return self[0...-1].join("#{separator} ").concat("#{separator}#{conjunction} #{self[-1]}")
        end
    end

end

class String

    def to_a
        [ self ]
    end

    def to_args
        self.scan(/(((\d+|all)\*)?((\d+|all)\.)?([^\s\.\'\*]+|'[\w\s]+'?))/i).map(&:first).map{ |arg| arg.gsub("'", "") }
    end

    def to_columns( column_width, column_count )
        # split by line
        self.split("\n").each_slice( column_count ).map{ |row| row.map{ |col| col.to_s.rpad( column_width ) }.join(" ") }.join("\n")
    end

    def fuzzy_match( arg )
        self.downcase.start_with? arg.to_s.downcase
            # arg = arg.to_s.downcase
            # self[0, arg.length].downcase == arg
        # self.match(/#{arg}/i)
    end

    ## Returns a copy of this string with the first character capitalized.
    #  Knows to skip whitespace and color codes.
    def capitalize_first
        first = self[/\A(({[A-Za-z]|[^A-Za-z])*)([a-z])/, 3]
        if first
            return gsub(/\A(({[A-Za-z]|\s)*)([a-z])/, "#{$1}#{first.upcase}")
        end
        return self
    end

    ## Capitalize the first character of this string.
    #  Knows to skip whitespace and color codes.
    def capitalize_first!
        first = self[/\A(({[A-Za-z]|[^A-Za-z])*)([a-z])/, 3]
        if first
            return gsub!(/\A(({[A-Za-z]|\s)*)([a-z])/, "#{$1}#{first.upcase}")
        end
        return nil
    end

    def sanitize
        result = self.dup
        result.gsub!(/</, "<<")
        result.gsub!(/>/, ">>")
        result.gsub!(/[\[\]\^]/, "")
        result.gsub!(/[\r\n]/, "")
        return result
    end

    def to_query( default_quantity = "all" )
        if self == "all"
            { offset: 0, quantity: "all", keyword: [""] }
        else
            {
                offset: self[/(\d+|all)\./, 1] || 0,
                quantity: self[/(\d+|all)\*/, 1] || default_quantity,
                keyword: self[/((\d+|all).)?'?([a-zA-Z\s]+)'?/, 3].to_s.downcase.split(" ").map(&:to_sym).to_set
            }
        end
    end

    def replace_color_codes
        out = self
        Constants::COLOR_CODE_REPLACEMENTS.each do |k, v|
            out.gsub!(/#{k}/, v)
        end
        return out
    end

    def color_code_length_offset
        count = 0
        Constants::COLOR_CODE_REPLACEMENTS.each do |k, v|
            self.scan(/#{k}/) do
                count += 2
            end
        end
        return count
    end

    def rpad(n, fill=" ")
        n += self.color_code_length_offset
        return self.ljust(n, fill)
    end

    def lpad(n, fill=" ")
        n += self.color_code_length_offset
        return self.rjust(n, fill)
    end

end

class Symbol

    def to_element
        return Game.instance.element_with_symbol(self)
    end

    def to_gender
        return Game.instance.gender_with_symbol(self)
    end

    def to_genre
        return Game.instance.genre_with_symbol(self)
    end

    def to_material
        return Game.instance.material_with_symbol(self)
    end

    def to_noun
        return Game.instance.noun_with_symbol(self)
    end

    def to_position
        return Game.instance.position_with_symbol(self)
    end

    def to_sector
        return Game.instance.sector_with_symbol(self)
    end

    def to_size
        return Game.instance.size_with_symbol(self)
    end

    def to_stat
        return Game.instance.stat_with_symbol(self)
    end

end

def dice( count, sides )
    n = 0
    count.times do
        n += rand(1..sides)
    end
    return n
    # count.times.collect{ rand(1..sides) }.sum
end

# small class just to handle logging with the option to skip line breaks
class Logger
    include Singleton

    @@time_diffs = {
        0.000 => "{D",
        0.020 => "{c",
        0.040 => "{g",
        0.060 => "{y",
        0.080 => "{r"
    }

    def initialize
        $stdout.sync = true
        @last_newline = true
        @timestamp = nil
        @line = ""
    end

    def log(s, newline, min_line_length)
        s = s.to_s.gsub(/\n/, "\n#{" " * 20} ")
        if @last_newline
            @timestamp = Time.now
            s = "{d[#{@timestamp.strftime("%m-%d %T.%L")}]\033{x #{s}"
        end
        if min_line_length > s.length + @line.length
            s += (" " * (min_line_length - s.length - @line.length))
        end
        @line << s
        if !@last_newline && newline
            diff = Time.now - @timestamp
            col = @@time_diffs.select { |k, v| k <= diff }.values.last
            s = "#{s}#{" " * [80 - @line.length, 0].max}#{col}#{diff.to_s[0..6]}{x\r\n"
        elsif newline
            s += "\r\n"
        end
        print s.replace_color_codes
        if newline
            @line = ""
        end
        @last_newline = newline
    end

end

# pass-through for the logger
def log(s, newline = true, min_line_length = 0)
    Logger.instance.log(s, newline, min_line_length)
end
