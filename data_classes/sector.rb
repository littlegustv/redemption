#
# The Sector data class.
#
class Sector < DataObject

    # @return [Boolean] Whether or not there is water in this sector.
    attr_reader :water

    # @return [Boolean] Whether or not the sector is underwater.
    attr_reader :underwater

    # @return [Boolean] Whether or not this sector requires flight for movement.
    attr_reader :requires_flight

    def initialize(row)
        super(row[:id], row[:name], row[:symbol])
        @water = row[:water].to_i.to_b
        @underwater = row[:underwater].to_i.to_b
        @requires_flight = row[:requires_flight].to_i.to_b
    end

    #
    # Returns `self` to allow `Symbol#to_sector` to be called safely without knowing the type.
    #
    # @return [Sector] `self`.
    #
    def to_sector
        self
    end
end
