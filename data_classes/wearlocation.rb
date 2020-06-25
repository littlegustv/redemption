#
# The Wear Location data class.
#
class WearLocation < DataObject

    # @return [String] The string representing what can be done with an item with this wear_location, eg: `"be worn on finger"`.
    attr_reader :display_string

    def initialize(row)
        super(row[:id], row[:name], row[:symbol])
        @display_string = row[:display_string]
    end

    #
    # Returns `self` to allow `Symbol#to_wear_location` to be called safely without knowing the type.
    #
    # @return [WearLocation] `self`.
    #
    def to_wear_location
        self
    end

end
