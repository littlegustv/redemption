# 
# Direction class. One exists for each direction in the game (North, East, South, etc). 
#
class Direction < DataObject

    # @return [Direction] The opposing direction to this one.
    attr_reader :opposite

    def initialize(row)
        super(row[:id], row[:name], row[:symbol])
        @opposite = nil
    end

    #
    # Returns `self` to allow Symbol#to_direction to be called safely without knowing the type.
    #
    # @return [Direction] `self`.
    #
    def to_direction
        self
    end

    #
    # Set the Direction opposite to this one.
    #
    #   north = Direction.new(row1)
    #   south = Direction.new(row2)
    #   north.set_opposite(south)
    #   south.set_opposite(north)
    #
    # @param [Direction] opposite The opposite direction.
    #
    # @return [Direction] The opposite direction.
    #
    def set_opposite(opposite)
        @opposite = opposite
    end

end
