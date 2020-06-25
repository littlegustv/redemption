class Integer

    #
    # Returns an ordinal number as a string using this one.
    #
    #   2.ordinalize  # => "2nd"
    #   17.ordinalize # => "17th"
    #
    # @return [String] The number as a String.
    #
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

    #
    # Returns the Gold value for an amount of wealth.
    #
    #   1253.gold # => 1
    #
    # @return [Integer] The value in Gold.
    #
    def gold
        ( self / 1000 ).floor
    end

    #
    # Returns the Silver value for an amount of wealth.
    #
    #   1253.silver # => 253
    #
    # @return [Integer] The value in silver.
    #
    def silver
        ( self - gold * 1000 )
    end

    #
    # Returns a string representation of a wealth value, described in terms of silver/gold.
    #
    #   1253.to_worth # => "1 gold and 253 silver."
    #
    # @return [String] The string.
    #
    def to_worth
        self.gold > 0 ? "#{ self.gold } gold and #{ self.silver } silver" : "#{ self.silver } silver"
    end

    #
    # Returns a binary value for this Integer. Any nonzero Integer is 'true'.
    #
    # @return [Boolean] False if Integer is 0, otherwise true.
    #
    def to_b
        !self.zero?
    end

end

class Array

    # @param message [String] A message format to send to this array of Gameobjects.
    # @param objects [Array] The array of object to inject into the message.
    # @param send_to_sleeping [Boolean] Whether or not the message should be sent to sleeping targets.
    # @return [nil]
    
    #
    # Sends an output to an array of GameObjects.
    # 
    #   output("0<N> drops 0<p> 1<n>.", [mobile, item]) # "A bag boy drops his sword."
    #   # 0 and 1 are the index of the object in the objects array
    #
    #   # Pronoun format
    #   "N" => Name                 "A bag boy"
    #   "S" => Short Description    "A boy is waiting here to pack your bags for you. "
    #   "L" => Long Description     "With a bored look on his face, you know that this youngster..."
    #   "O" => Personal Objective   "Him"
    #   "U" => Personal Subjective  "He"
    #   "P" => Possessive           "His"
    #   "R" => Reflexive            "Himself"
    #
    #   # Capitalization of pronouns in the format will be reflected in the output.
    #   "0<N>" => "A bag boy"
    #   "0<n>" => "a bag boy"
    #
    # @param [String] message The format.
    # @param [Array<GameObject>] objects The objects.
    # @param [Boolean] send_to_sleeping True if the message should be sent even to sleeping GameObjects.
    #
    # @return [nil]
    #
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
        self.split("\n").each_slice( column_count ).map{ |row| row.map{ |col| col.to_s.rpad( column_width ) }.join(" ".freeze) }.join("\n")
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

    def to_query( default_quantity = 1 )
        return Query.new(self, default_quantity)
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

    def rpad(n, fill=" ".freeze)
        n += self.color_code_length_offset
        return self.ljust(n, fill)
    end

    def lpad(n, fill=" ".freeze)
        n += self.color_code_length_offset
        return self.rjust(n, fill)
    end

end

class Symbol

    def to_direction
        return Game.instance.direction_with_symbol(self)
    end

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

    def to_race
        return Game.instance.race_with_symbol(self)
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

    def to_wear_location
        return Game.instance.wear_location_with_symbol(self)
    end

end

def dice( count, sides )
    n = 0
    count.to_i.times do
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
        s = s.to_s.gsub(/\n/, "\n#{" ".freeze * 20} ")
        if @last_newline
            @timestamp = Time.now
            s = "{d[#{@timestamp.strftime("%m-%d %T.%L")}]\033{x #{s}"
        end
        if min_line_length > s.length + @line.length
            s += (" ".freeze * (min_line_length - s.length - @line.length))
        end
        @line << s
        if !@last_newline && newline
            diff = Time.now - @timestamp
            col = @@time_diffs.select { |k, v| k <= diff }.values.last
            s = "#{s}#{" ".freeze * [80 - @line.length, 0].max}#{col}#{diff.to_s[0..6]}{x\r\n"
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
