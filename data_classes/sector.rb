#

class Sector
    attr_reader :id
    attr_reader :name
    attr_reader :symbol
    attr_reader :water
    attr_reader :underwater
    attr_reader :requires_flight

    def initialize(row)
        @id = row[:id]
        @name = row[:name].gsub(/_/, " ")
        @symbol = (row[:symbol] || row[:name].gsub(/ /, "_")).to_sym
        @water = row[:water].to_i.to_b
        @underwater = row[:underwater].to_i.to_b
        @requires_flight = row[:requires_flight].to_i.to_b
    end

    def ==(other_object)
        super(other_object) || @symbol == other_object
    end

    def to_sector
        self
    end
end
