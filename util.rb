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

class String
    def to_a
        [ self ]
    end

    def fuzzy_match( arg )
        self.match(/\A#{arg}.*\z/i)
    end

    def capitalize_first
        slice(0, 1).to_s.capitalize + slice(1..-1).to_s
    end

    def sanitize
        self.gsub(/[\%\[\]\^]/, "")
    end

    def to_query( default_quantity = "all" )
        if self == "all"
            { offset: 0, quantity: "all", keyword: [""] }
        else
            {
                offset: self.match(/(\d+|all)\./).to_a.last || 0,
                quantity: self.match(/(\d+|all)\*/).to_a.last || default_quantity,
                keyword: self.match(/((\d+|all).)?'?([a-zA-Z\s]+)'?/).to_a.last.to_s.split
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

    def lpad(n, fill=" ")
        n += self.color_code_length_offset
        return self.ljust(n, fill)
    end

    def rpad(n, fill=" ")
        n += self.color_code_length_offset
        return self.rjust(n, fill)
    end

end

def dice( count, sides )
    count.times.collect{ rand(1..sides) }.sum
end

def log(s)
    puts "{d[#{Time.now}]\033{x #{s}".replace_color_codes
end
