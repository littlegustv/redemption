class Material

    attr_reader :id
    attr_reader :name
    attr_reader :symbol
    attr_reader :metallic

    def initialize(row)
        @id = row[:id]
        @name = row[:name].gsub(/_/, " ")
        @symbol = (row[:symbol] || row[:name].gsub(/ /, "_")).to_sym
        @metallic = row[:metallic]
    end

    def ==(other_object)
        super(other_object) || @symbol == other_object
    end

    def to_material
        self
    end

end
