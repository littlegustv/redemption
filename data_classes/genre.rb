class Genre

    attr_reader :id
    attr_reader :name
    attr_reader :symbol
    attr_reader :affect_models

    def initialize(row)
        @id = row[:id]
        @name = row[:name]
        @symbol = row[:name].to_s.to_sym
        @affect_models = Array.new
    end

    def ==(other_object)
        super(other_object) || @symbol == other_object
    end

    def to_genre
        self
    end

end
