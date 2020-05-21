#

class Direction
    attr_reader :id
    attr_reader :name
    attr_reader :symbol
    attr_reader :opposite

    def initialize(row)
        @id = row[:id]
        @name = row[:name].gsub(/_/, " ")
        @symbol = (row[:symbol] || row[:name].gsub(/ /, "_")).to_sym
    end

    def ==(other_object)
        super(other_object) || @symbol == other_object
    end

    def to_direction
        self
    end

    def set_opposite(opposite)
        @opposite = opposite
    end

end
