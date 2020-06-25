#
# The Stat Data class.
#
class Stat < DataObject

    # @return [Stat, nil] Another Stat which limits the value for this stat, or nil.
    attr_reader :max_stat

    # @return [Integer] The cap for this stat before modifiers from affects or items are applied.
    attr_reader :base_cap

    # @return [Integer] The final hard cap. This value cannot be exceeded.
    attr_reader :hard_cap

    # @return [Boolean] Whether or not the stat is percent-based.
    attr_reader :percent_based

    def initialize(row)
        super(row[:id], row[:name], row[:symbol])
        @max_stat = nil
        @base_cap = row[:base_cap]
        @hard_cap = row[:hard_cap]
        @percent_based = row[:percent_based]
    end

    #
    # Returns `self` to allow `Symbol#to_stat` to be called safely without knowing the type.
    #
    # @return [Stat] `self`.
    #
    def to_stat
        return self
    end

    #
    # Set the Stat which will serve as a limit for this Stat.
    #
    # @param [Stat] max_stat The Stat which will serve as a cap for this stat.
    #
    # @return [void]
    #
    def set_max_stat(max_stat)
        @max_stat = max_stat
        return
    end

    def percent?
        if @percent_based
            return "%"
        else
            return ""
        end
    end

end
