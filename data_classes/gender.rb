#
# The Gender data class.
#
class Gender < DataObject

    # @return [String] The Gender's personal objective pronoun (`"it"`, `"him"`, `"her"`).
    attr_reader :personal_objective

    # @return [String] The Gender's peronal subjectibe pronoun (`"it"`, `"he"`, `"she"`)
    attr_reader :personal_subjective

    # @return [String] The Gender's possessive pronoun (`"its"`, `"his"`, `"her"`)
    attr_reader :possessive

    # @return [String] The Gender's reflexive pronoun (`"itself"`, `"himself"`, `"herself"`)
    attr_reader :reflexive

    def initialize(row) 
        super(row[:id], row[:name], row[:symbol])
        @personal_objective = row[:personal_objective]
        @personal_subjective = row[:personal_subjective]
        @possessive = row[:possessive]
        @reflexive = row[:reflexive]
    end

    #
    # Returns `self` to allow `Symbol#to_gender` to be called safely without knowing the type.
    #
    # @return [Gender] `self`.
    #
    def to_gender
        self
    end

end
