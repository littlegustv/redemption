#
# The MobileClass data class.
#
class MobileClass < DataObject

    # @return [Boolean] Whether or not this MobileClass is available at character creation.
    attr_reader :starter_class

    # @return [Float] The casting multiplier for this MobileClass.
    attr_reader :casting_multiplier

    # @return [Hash{Stat => Integer}] The stat modifiers for this MobileClass as a Hash.
    attr_reader :stats

    # @return [Array<Genre>] The weapon Genres available to this MobileClass.
    attr_reader :genres

    # @return [Array<EquipSlotInfo>] The EquipSlotInfos for this MobileClass as an Array.
    attr_reader :equip_slot_infos

    # @return [Array<AffectModel>] The AffectModels associated with this MobileClass
    attr_reader :affect_models

    # @return [Array<Skill>] The Skills available to this MobileClass.
    attr_reader :skills

    # @return [Array<Spell>] The Spells available to this MobileClass.
    attr_reader :spells

    def initialize(row)
        super(row[:id], row[:name], row[:symbol])
        @starter_class = row[:starter_class]
        @casting_multiplier = row[:casting_multiplier]
        @stats = Hash.new

        @genres = Array.new
        @equip_slot_infos = Array.new
        @affect_models = Array.new
        @skills = Array.new
        @spells = Array.new
    end

    #
    # Adds a stat modifier to this MobileClass.
    #
    # @param [Stat, Symbol] stat The stat to modify.
    # @param [Integer] value The integer value to modify the Stat by.
    #
    # @return [void] 
    #
    def add_stat(stat, value)
        stat = stat.to_stat
        if !@stats.dig(stat)
            @stats[stat] = 0
        end
        @stats[stat] += value
        return
    end

    #
    # Get the value for a given Stat as modified by this MobileClass.
    #
    #   mobileclass.stat(:dexterity) # => 3
    #
    # @param [Stat] s The stat to get the modified value for.
    #
    # @return [Integer] The modified value for the given stat.
    #
    def stat(s)
        s = s.to_stat
        @stats.dig(s).to_i
    end

    #
    # Returns `self` to allow `Symbol#to_mobile_class` to be called safely without knowing the type.
    #
    # @return [MobileClass] `self`.
    #
    def to_mobile_class
        self
    end

end
