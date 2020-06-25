#
# The Material data class.
#
class Material < DataObject

    # @return [Boolean] Whether or not this material is metallic.
    attr_reader :metallic

    def initialize(row)
        super(row[:id], row[:name], row[:symbol])
        @metallic = row[:metallic]
    end

    #
    # Returns `self` to allow `Symbol#to_material` to be called safely without knowing the type.
    #
    # @return [Material] `self`.
    #
    def to_material
        self
    end

end
