class MobileModel

    attr_reader :id
    attr_reader :level
    attr_reader :keywords
    attr_reader :name
    attr_reader :short_description
    attr_reader :long_description
    attr_reader :race
    attr_reader :mobile_class
    attr_reader :alignment
    attr_reader :hand_to_hand_dice_sides
    attr_reader :hand_to_hand_dice_count
    attr_reader :hand_to_hand_noun
    attr_reader :position
    attr_reader :wealth
    attr_reader :size
    attr_reader :material

    attr_reader :stats
    attr_reader :affect_models
    attr_reader :genders
    attr_reader :hand_to_hand_affect_models
    attr_reader :learned_skills
    attr_reader :learned_spells

    def initialize(id, row)
        @id = id
        @level = row[:level] || 1
        @keywords = row[:keywords].to_s.split(" ")
        @name = row[:name].to_s
        @short_description = row[:short_description].to_s
        @long_description = row[:long_description].to_s
        @alignment = row[:alignment] || 0
        @hand_to_hand_dice_sides = row.dig(:hand_to_hand_dice_sides)
        @hand_to_hand_dice_count = row.dig(:hand_to_hand_dice_count)
        @wealth = row[:wealth] || 0

        # race
        if row.dig(:race_id)
            @race = Game.instance.races[row[:race_id]]
        elsif row.dig(:race)
            @race = row[:race]
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

        # stats
        add_stat(:strength, row[:strength]) if row.dig(:strength)
        add_stat(:dexterity, row[:dexterity]) if row.dig(:dexterity)
        add_stat(:intelligence, row[:intelligence]) if row.dig(:intelligence)
        add_stat(:wisdom, row[:wisdom]) if row.dig(:wisdom)
        add_stat(:constitution, row[:constitution]) if row.dig(:constitution)
        add_stat(:max_strength, row[:max_strength]) if row.dig(:max_strength)
        add_stat(:max_dexterity, row[:max_dexterity]) if row.dig(:max_dexterity)
        add_stat(:max_intelligence, row[:max_intelligence]) if row.dig(:max_intelligence)
        add_stat(:max_wisdom, row[:max_wisdom]) if row.dig(:max_wisdom)
        add_stat(:max_constitution, row[:max_constitution]) if row.dig(:max_constitution)
        add_stat(:armor_class, row[:armor_class]) if row.dig(:armor_class)
        add_stat(:hit_roll, row[:hit_roll]) if row.dig(:hit_roll)
        add_stat(:damage_roll, row[:damage_roll]) if row.dig(:damage_roll)

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

    def add_stat(stat, value)
        if !@stats
            @stats = {}
        end
        @stats[stat.to_stat] = value
    end

end
