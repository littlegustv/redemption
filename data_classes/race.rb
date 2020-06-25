#
# The Race data class.
#
class Race < DataObject

    # @return [Boolean] Whether or not this race is available at character creation.
    attr_reader :starter_race

    # @return [Boolean] Whether or not this race is a playable by player characters.
    attr_reader :player_race

    # @return [String] The display name for this race.
    attr_reader :display_name

    # @return [Hash{Stat => Integer}] The Stats for this race as a Hash.
    attr_reader :stats

    # @return [Size] The Size for the class.
    attr_reader :size

    # @return [Noun] The noun for this race's hand to hand.
    attr_reader :hand_to_hand_noun

    # @return [Array<Genre>] The weapon genres available to this race.
    attr_reader :genres

    # @return [Array<EquipSlotInfo>] The equip slot infos for this race as an Array.
    attr_reader :equip_slot_infos

    # @return [Array<AffectModel>] The affect models associated with this race as an Array.
    attr_reader :affect_models

    # @return [Array<AffectModel>] The affect models associated with this race's hand to hand as an Array.
    attr_reader :hand_to_hand_affect_models

    # @return [Array<Skill>] The skills available to this race.
    attr_reader :skills

    # @return [Array<Spell>] The spells available to this race.
    attr_reader :spells

    def initialize(row)
        super(row[:id], row[:name], row[:symbol])
        @starter_race = row[:starter_race]
        @player_race = row[:player_race]
        @display_name = row[:display_name]
        @stats = {}
        stats = [ # stats to pull from the table
            :strength,
            :intelligence,
            :wisdom,
            :dexterity,
            :constitution,
            :max_strength,
            :max_intelligence,
            :max_wisdom,
            :max_dexterity,
            :max_constitution,
        ]
        stats.each do |stat|
            add_stat(stat, row[stat])
        end
        @hand_to_hand_noun = Game.instance.nouns[row[:hand_to_hand_noun_id]]

        @genres = []
        @equip_slot_infos = []
        @affect_models = []
        @hand_to_hand_affect_models = []
        @skills = []
        @spells = []
    end

    #
    # Adds a stat modifier to this Race.
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
    # Get the value for a given Stat as modified by this Race.
    #
    #   race.stat(:dexterity) # => 16
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
    # Returns `self` to allow `Symbol#to_race` to be called safely without knowing the type.
    #
    # @return [Race] `self`.
    #
    def to_race
        return self
    end

end
