class Object
    def instance_options_try(options)
        options.each do |key, value|
            if instance_variable_defined?("@#{key}")
                self.instance_variable_set("@#{key}", value)
            else
                log "Illegal instance variable tried [key: #{key}, value: #{value}]."
            end
        end
    end
end

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

end

class Array

    def each_output( message, objects = [], send_to_sleeping: false )
        targets = self.reject{ |t| t.respond_to?(:output) == false }
        if !send_to_sleeping
            targets.reject!{ |t| t.respond_to?(:position) && t.position == Constants::Position::SLEEP }
        end
        targets.each do | player |
            player.output( message, objects.to_a )
        end
    end
    
end

class String
    def to_a
        [ self ]
    end

    def to_columns( column_width, column_count )
        # split by line
        self.split("\n").each_slice( column_count ).map{ |row| row.map{ |col| col.to_s.rpad( column_width ) }.join(" ") }.join("\n")
    end

    def fuzzy_match( arg )
        self.start_with? arg.to_s.downcase
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

def dice( count, sides )
    n = 0
    count.times do
        n += rand(1..sides)
    end
    return n
    # count.times.collect{ rand(1..sides) }.sum
end

def log(s)
    s = s.to_s.gsub(/\n/, "\n#{" " * 27} ")
    puts "{d[#{Time.now}]\033{x #{s}".replace_color_codes
end
