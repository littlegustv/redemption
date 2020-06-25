#
# The Element class.
#
class Element < DataObject

    # @return [Stat] The Stat used to resist this element.
    attr_reader :resist_stat

    def initialize(row)
        super(row[:id], row[:name], row[:symbol])
        @resist_stat = Game.instance.stats.dig(row[:resist_stat_id])
    end

    #
    # Returns `self` to allow Symbol#to_element to be called safely without knowing the type.
    #
    # @return [Element] `self`.
    #
    def to_element
        self
    end

end
