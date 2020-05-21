class Genre

    attr_reader :id
    attr_reader :name
    attr_reader :symbol
    attr_reader :attack_speed
    attr_reader :affect_models

    def initialize(row)
        @id = row[:id]
        @name = row[:name].gsub(/_/, " ")
        @symbol = (row[:symbol] || row[:name].gsub(/ /, "_")).to_sym
        @attack_speed = row[:attack_speed].to_f
        @affect_models = Array.new
    end

    def ==(other_object)
        super(other_object) || @symbol == other_object
    end

    def to_genre
        self
    end

end
