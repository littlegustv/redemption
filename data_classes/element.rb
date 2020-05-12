#

class Element
    attr_reader :id
    attr_reader :name
    attr_reader :symbol
    attr_reader :resist_stat

    def initialize(row)
        @id = row[:id]
        @name = row[:name].gsub(/_/, " ")
        @symbol = (row[:symbol] || row[:name].gsub(/ /, "_")).to_sym
        @resist_stat = Game.instance.stats.dig(row[:resist_stat_id])
    end

    def ==(other_object)
        super(other_object) || @symbol == other_object
    end

    def to_element
        self
    end

end
