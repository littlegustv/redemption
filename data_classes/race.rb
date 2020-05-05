

class Race

    attr_reader :id
    attr_reader :starter_race
    attr_reader :player_race
    attr_reader :name
    attr_reader :symbol
    attr_reader :display_name
    attr_reader :stats
    attr_reader :size
    attr_reader :hand_to_hand_noun

    attr_reader :genres
    attr_reader :equip_slot_infos
    attr_reader :affect_models
    attr_reader :hand_to_hand_affect_models
    attr_reader :skills
    attr_reader :spells

    def initialize(row)
        @id = row[:id]
        @starter_race = row[:starter_race].to_i.to_b
        @player_race = row[:player_race].to_i.to_b
        @name = row[:name]
        @symbol = row[:name].to_s.to_sym
        @display_name = row[:display_name]
        @stats = {
            :str => row[:str],
            :int => row[:int],
            :wis => row[:wis],
            :dex => row[:dex],
            :con => row[:con],
            :max_str => row[:max_str],
            :max_int => row[:max_int],
            :max_wis => row[:max_wis],
            :max_dex => row[:max_dex],
            :max_con => row[:max_con],
        }
        @size = Game.instance.sizes[row[:size_id]]
        @hand_to_hand_noun = Game.instance.nouns[row[:hand_to_hand_noun_id]]

        @genres = Array.new
        @equip_slot_infos = Array.new
        @affect_models = Array.new
        @hand_to_hand_affect_models = Array.new
        @skills = Array.new
        @spells = Array.new
    end

    def ==(other_object)
        super(other_object) || @symbol == other_object
    end

end
