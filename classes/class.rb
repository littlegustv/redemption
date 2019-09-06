class PlayerClass
    attr_reader :classname

    def initialize(options)
        @classname = 'Default'
        self.instance_options_try(options)
    end
end
