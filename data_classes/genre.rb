#
# The weapon Genre data class.
#
class Genre < DataObject

    # @return [Float] The attack speed for this weapon genre. Weapon speed is defined as attacks per round.    
    attr_reader :attack_speed
    
    # @return [Array<AffectModel>] The AffectModels associate with this class, as an Array.
    attr_reader :affect_models

    def initialize(row)
        super(row[:id], row[:name], row[:symbol])
        @attack_speed = row[:attack_speed].to_f
        @affect_models = Array.new
    end

    #
    # Returns `self` to allow `Symbol#to_genre` to be called safely without knowing the type.
    #
    # @return [Genre] `self`.
    #
    def to_genre
        self
    end

end
