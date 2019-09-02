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
end

module Position
    SLEEP = 0
    REST = 1
    STAND = 2
    FIGHT = 3

    STRINGS = [
        "sleeping",
        "resting",
        "standing",
        "fighting"
    ]
end
