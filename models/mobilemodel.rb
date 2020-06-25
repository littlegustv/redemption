#
# The Model for mobiles. 
# Some of the mobile's attributes just link back to this to save on memory, like name and descriptions.
#
class MobileModel < KeywordedModel

    # @return [Integer] The mobile's ID.
    attr_reader :id

    # @return [Integer] The mobile's level, eg. 5
    attr_reader :level
    
    # @return [String] Name of the mobile, eg. `"a fungusaur"`.
    attr_reader :name
    
    # @return [String] Short description of the mobile, eg. `"A man-sized fungusaur prowls the walls."`.
    attr_reader :short_description
    
    # @return [String] Long description of the mobile,  
    #   eg. `"The strange beast stands just over six feet tall. It seems..."`
    attr_reader :long_description
    
    # @return [Race]
    attr_reader :race

    # @return [MobileClass, nil] The MobileClass of the mobile, or nil if there is none.
    attr_reader :mobile_class
    
    # @return [Integer]
    attr_reader :alignment

    # @return [Integer] Dice count for hand to hand damage.
    attr_reader :hand_to_hand_dice_sides
    
    # @return [Integer] Dice sides for hand to hand damage.
    attr_reader :hand_to_hand_dice_count
    
    # @return [Noun] The noun used for hand to hand.
    attr_reader :hand_to_hand_noun
    
    # @return [Position] The starting position for the mobile.
    attr_reader :position

    # @return [Integer]
    attr_reader :wealth

    # @return [Size, nil] The natural size of the mobile, or nil if there is none.
    attr_reader :size

    # @return [Material]
    attr_reader :material

    # @return [Integer, nil] The mobile's base health. If nil, mobile will use max_health formula instead.
    attr_reader :base_health
    
    # @return [Integer, nil] The mobile's base mana. If nil, the mobile will use max_mana formula instead.
    attr_reader :base_mana

    # @return [Integer, nil] The mobile's base movement. If nil, the mobile will use max_movement formula instead.
    attr_reader :base_movement

    # @return [Integer] Natural armor class.
    attr_reader :base_armor_class

    # @return [Integer] Natural hit roll.
    attr_reader :base_hit_roll
    
    # @return [Integer] Natural damage roll.
    attr_reader :base_damage_roll

    # @return [Hash{Stat => Integer}, nil] Natural stats, or nil if there are none.
    attr_reader :stats
    
    # @return [Array<AffectModel>, nil] Array of mobile affect models, or nil if there are none.
    attr_reader :affect_models
    
    # @return [Array<Gender>, nil] The possible genders for this mobile, or nil if there are none.
    attr_reader :genders

    # @return [Array<AffectModel>, nil] Array of hand to hand affect models, or nil if there are none.
    attr_reader :hand_to_hand_affect_models

    # @return [Array<Skill>, nil] Array of learned skills, or nil if there are none.
    attr_reader :learned_skills
    
    # @return [Array<Spell>, nil] Array of learned spells, or nil if there are none.
    attr_reader :learned_spells

    def initialize(id, row, temporary = true)
        super(temporary, row[:keywords].split(","))
        @id = id
        @level = row[:level] || 1
        @name = row[:name].to_s
        @short_description = row[:short_description].to_s.chomp
        @long_description = row[:long_description].to_s.chomp

        @alignment = row[:alignment] || 0
        @hand_to_hand_dice_sides = row.dig(:hand_to_hand_dice_sides)
        @hand_to_hand_dice_count = row.dig(:hand_to_hand_dice_count)
        @wealth = row[:wealth] || 0
        @stats = nil
        @base_health = row.dig(:max_health)
        @base_mana = row.dig(:max_mana)
        @base_movement = row.dig(:max_movement)
        @base_armor_class = row.dig(:armor_class).to_i
        @base_hit_roll = row.dig(:hit_roll)
        @base_damage_roll = row.dig(:damage_roll)

        # race
        if row.dig(:race_id)
            @race = Game.instance.races[row[:race_id]]
        elsif row.dig(:race)
            @race = row[:race].to_race
        else
            @race = Game.instance.races.values.first
        end

        # mobile_class
        if row.dig(:mobile_class_id)
            @mobile_class = Game.instance.mobile_classes[row[:mobile_class_id]]
        elsif row.dig(:mobile_class)
            @mobile_class = row[:mobile_class]
        else
            @mobile_class = Game.instance.mobiles_classes.values.find { |mc| mc.name == "none" }
        end

         # h2h noun
        if row.dig(:hand_to_hand_noun_id)
            @hand_to_hand_noun = Game.instance.nouns[row[:hand_to_hand_noun_id]]
        elsif row.dig(:hand_to_hand_noun)
            @hand_to_hand_noun = row[:hand_to_hand_noun]
        else
            @hand_to_hand_noun = :hit.to_noun
        end

        # position
        if row.dig(:position_id)
            @position = Game.instance.positions[row[:position_id]]
        elsif row.dig(:position)
            @position = row[:position]
        else
            @position = :standing.to_position
        end

        # size
        if row.dig(:size_id)
            @size = Game.instance.sizes[row[:size_id]]
        elsif row.dig(:size)
            @size = row[:size]
        else
            @size = nil
        end

        # material
        if row.dig(:material_id)
            @material = Game.instance.materials[row[:material_id]]
        elsif row.dig(:material)
            @material = row[:material]
        else
            @material = Game.instance.materials.values.first
        end

        # stats to pull from row
        stats = [
            :strength,
            :dexterity,
            :intelligence,
            :wisdom,
            :constitution,
            :max_strength,
            :max_dexterity,
            :max_intelligence,
            :max_wisdom,
            :max_constitution,
        ]
        
        stats.each do |stat|
            add_stat(stat, row[stat]) if row.dig(stat)
        end

        # affect models
        if row.dig(:affect_models)
            @affect_models = row[:affect_models]
        else
            @affect_models = nil
        end

        # genders
        if row.dig(:genders)
            @genders = row[:genders]
        else
            @genders = nil
        end

        # h2h affect models
        if row.dig(:hand_to_hand_affect_models)
            @hand_to_hand_affect_models = row[:hand_to_hand_affect_models]
        else
            @hand_to_hand_affect_models = nil
        end

        # learned skills
        if row.dig(:learned_skill_ids)
            @learned_skills = Game.instance.skills.select{ |skill| row[:learned_skill_ids].include?(skill.id) }
        elsif row.dig(:learned_skills)
            @learned_skills = row[:learned_skills]
        else
            @learned_skills = nil
        end

        # learned spells
        if row.dig(:learned_spell_ids)
            @learned_spells = Game.instance.spells.select{ |spell| row[:learned_spell_ids].include?(spell.id) }
        elsif row.dig(:learned_spells)
            @learned_spells = row[:learned_spells]
        else
            @learned_spells = nil
        end
    end
  
    #
    # Adds a stat modifier to this mobile model.
    #
    # @param [Stat] stat The Stat to modify.
    # @param [Integer] value The value of the stat modifier.
    #
    # @return [nil]
    #
    def add_stat(stat, value)
        if !@stats
            @stats = {}
        end
        @stats[stat.to_stat] = value
        return
    end

end
