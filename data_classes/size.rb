#
# The Size data class.
#
class Size < DataObject

    # @return [Integer] An arbitrary integer to represent the size. Generally, a number from `0` to `6`.
    attr_reader :value

    def initialize(row)
        super(row[:id], row[:name], row[:symbol])
        @value = row[:value]
    end

    #
    # Returns `self` to allow `Symbol#to_size` to be called safely without knowing the type.
    #
    # @return [Size] `self`.
    #
    def to_size
        self
    end
end
