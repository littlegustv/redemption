

class Position
    attr_reader :id
    attr_reader :name
    attr_reader :symbol
    attr_reader :value
    attr_reader :regen_multiplier

    def initialize(row)
        @id = row[:id]
        @name = row[:name]
        @symbol = row[:name].to_s.to_sym
        @value = row[:value]
        @regen_multiplier = row[:regen_multiplier]
    end

    def ==(other_object)
        super(other_object) || @symbol == other_object
    end

    def <(other_object)
        @value < other_object.value
    end

    def >(other_object)
        @value > other_object.value
    end

    def to_position
        self
    end
end
