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
    attr_reader :hitroll
    attr_reader :damroll
    attr_reader :hp
    attr_reader :mana
    attr_reader :movement
    attr_reader :current_hp
    attr_reader :current_mana
    attr_reader :current_movement
    attr_reader :hand_to_hand_dice_sides
    attr_reader :hand_to_hand_dice_count
    attr_reader :hand_to_hand_noun
    attr_reader :ac_pierce
    attr_reader :ac_bash
    attr_reader :ac_slash
    attr_reader :ac_magic
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
        @hitroll = row[:hitroll] || 0
        @damroll = row[:damroll] || 0
        @hp = row.dig(:hp)
        @current_hp = row.dig(:current_hp)
        @mana = row.dig(:mana)
        @current_mana = row.dig(:current_mana)
        @movement = row.dig(:movement) || 100
        @current_movement = row.dig(:current_movement)
        @hand_to_hand_dice_sides = row[:hand_to_hand_dice_sides] || 1
        @hand_to_hand_dice_count = row[:hand_to_hand_dice_count] || 1
        @ac_pierce = row[:ac_pierce] || 0
        @ac_bash = row[:ac_bash] || 0
        @ac_slash = row[:ac_slash] || 0
        @ac_magic = row[:ac_magic] || 0
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
            @hand_to_hand_noun = "hit".to_noun
        end

        # position
        if row.dig(:position_id)
            @position = Game.instance.positions[row[:position_id]]
        elsif row.dig(:position)
            @position = row[:position]
        else
            @position = "standing".to_position
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
        if row.dig(:stats)
            @stats = row[:stats]
        else
            @stats = Hash.new
        end

        # affect models
        if row.dig(:affect_models)
            @affet_models = row[:affect_models]
        else
            @affect_models = []
        end

        # genders
        if row.dig(:genders)
            @genders = row[:genders]
        else
            @genders = []
        end

        # h2h affect models
        if row.dig(:hand_to_hand_affect_models)
            @hand_to_hand_affect_models = row[:hand_to_hand_affect_models]
        else
            @hand_to_hand_affect_models = []
        end

        # learned skills
        if row.dig(:learned_skill_ids)
            @learned_skills = Game.instance.skills.select{ |skill| row[:learned_skill_ids].include?(skill.id) }
        elsif row.dig(:learned_skills)
            @learned_skills = row[:learned_skills]
        else
            @learned_skills = []
        end

        # learned spells
        if row.dig(:learned_spell_ids)
            @learned_spells = Game.instance.spells.select{ |spell| row[:learned_spell_ids].include?(spell.id) }
        elsif row.dig(:learned_spells)
            @learned_spells = row[:learned_spells]
        else
            @learned_spells = []
        end
    end

end
