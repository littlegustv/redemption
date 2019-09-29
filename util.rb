class Object
  def instance_options_try(options)
    options.each do |key, value|
      if instance_variable_defined?("@#{key}")
        self.instance_variable_set("@#{key}", value)
      else
        puts "Illegal instance variable tried [key: #{key}, value: #{value}]."
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

  def to_query
    if self == "all"
        { offset: 0, quantity: "all", keyword: [""] }
    else
        {
            offset: self.match(/(\d+|all)\./).to_a.last,
            quantity: self.match(/(\d+|all)\*/).to_a.last,
            keyword: self.match(/((\d+|all).)?'?([a-zA-Z\s]+)'?/).to_a.last.to_s.split
        }
    end
  end

end

def dice( count, sides )
    count.times.collect{ rand(1..sides) }.sum
end

def log(s)
    puts "\033[0;30m[#{Time.now}]\033[0m #{s}"
end
