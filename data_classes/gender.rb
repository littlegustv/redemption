class Gender

    attr_reader :id
    attr_reader :name
    attr_reader :symbol
    attr_reader :personal_objective
    attr_reader :personal_subjective
    attr_reader :possessive
    attr_reader :reflexive

    def initialize(row)
        @id = row[:id]
        @name = row[:name]
        @symbol = row[:name].to_s.to_sym
        @personal_objective = row[:personal_objective]
        @personal_subjective = row[:personal_subjective]
        @possessive = row[:possessive]
        @reflexive = row[:reflexive]
    end

    def ==(other_object)
        super(other_object) || @symbol == other_object
    end

    def to_gender
        self
    end

end
