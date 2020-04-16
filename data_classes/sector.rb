#

class Sector
    attr_reader :id
    attr_reader :name
    attr_reader :symbol

    def initialize(row)
        @id = row[:id]
        @name = row[:name]
        @symbol = row[:name].to_s.to_sym
    end

    def ==(other_object)
        super(other_object) || @symbol == other_object
    end

    def to_sector
        self
    end
end
