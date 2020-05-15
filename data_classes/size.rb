#

class Size
    attr_reader :id
    attr_reader :name
    attr_reader :symbol
    attr_reader :value

    def initialize(row)
        @id = row[:id]
        @name = row[:name].gsub(/_/, " ")
        @symbol = (row[:symbol] || row[:name].gsub(/ /, "_")).to_sym
        @value = row[:value]
    end

    def ==(other_object)
        super(other_object) || @symbol == other_object
    end

    def to_size
        self
    end
end
