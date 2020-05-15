

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
        @starter_race = row[:starter_race]
        @player_race = row[:player_race]
        @name = row[:name].gsub(/_/, " ")
        @symbol = row[:name].to_s.to_sym
        @display_name = row[:display_name]
        @stats = {
            :strength.to_stat => row[:strength],
            :intelligence.to_stat => row[:intelligence],
            :wisdom.to_stat => row[:wisdom],
            :dexterity.to_stat => row[:dexterity],
            :constitution.to_stat => row[:constitution],
            :max_strength.to_stat => row[:max_strength],
            :max_intelligence.to_stat => row[:max_intelligence],
            :max_wisdom.to_stat => row[:max_wisdom],
            :max_dexterity.to_stat => row[:max_dexterity],
            :max_constitution.to_stat => row[:max_constitution],
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

    def stat(s)
        @stats.dig(s).to_i
    end

    def add_stat(stat, value)
        if !@stats.dig(stat)
            @stats[stat] = 0
        end
        @stats[stat] += value
    end

end
