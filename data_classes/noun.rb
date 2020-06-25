#
# The Noun data class.
#
class Noun < DataObject

    # @return [Element] The Element for this Noun.
    attr_reader :element

    # @return [Boolean] Whether or not this Noun is magic.
    attr_reader :magic

    def initialize(row)
        super(row[:id], row[:name], row[:symbol])
        @element = Game.instance.elements[row[:element_id]]
        @magic = row[:magic]
    end

    #
    # Returns `self` to allow `Symbol#to_noun` to be called safely without knowing the type.
    #
    # @return [Noun] `self`.
    #
    def to_noun
        self
    end

end
