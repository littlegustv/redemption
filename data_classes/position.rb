#
# The Position data class.
#
class Position < DataObject

    # @return [Integer] An arbitrary value associated with the position to allow for comparisons,
    #    eg: :sleeping < :resting < :standing
    attr_reader :value

    # @return [Float] The multipler given by this position for normal regeneration.
    attr_reader :regen_multiplier

    def initialize(row)
        super(row[:id], row[:name], row[:symbol])
        @value = row[:value]
        @regen_multiplier = row[:regen_multiplier]
    end

    def <(other_object)
        @value < other_object.value
    end

    def >(other_object)
        @value > other_object.value
    end

    #
    # Returns `self` to allow `Symbol#to_position` to be called safely without knowing the type.
    #
    # @return [Position] `self`.
    #
    def to_position
        self
    end
end
