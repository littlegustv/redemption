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