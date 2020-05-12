# This class is basically a container for a few damage

class Noun

    attr_reader :id
    attr_reader :element
    attr_reader :name
    attr_reader :symbol
    attr_reader :magic

    def initialize(row)
        @id = row[:id]
        @element = Game.instance.elements[row[:element_id]]
        @name = row[:name].gsub(/_/, " ")
        @symbol = (row[:symbol] || row[:name].gsub(/ /, "_")).to_sym
        @magic = row[:magic]
    end

    def ==(other_object)
        super(other_object) || @symbol == other_object
    end

    def to_noun
        self
    end

end
