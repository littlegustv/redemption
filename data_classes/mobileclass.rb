class MobileClass

    attr_reader :id
    attr_reader :name
    attr_reader :symbol
    attr_reader :starter_class
    attr_reader :casting_multiplier
    attr_reader :main_stat
    attr_reader :main_stat_bonus
    attr_reader :main_stat_max_stat_bonus

    attr_reader :genres
    attr_reader :equip_slot_infos
    attr_reader :affect_models
    attr_reader :skills
    attr_reader :spells


    def initialize(row)
        @id = row[:id]
        @name = row[:name].gsub(/_/, " ")
        @symbol = (row[:symbol] || row[:name].gsub(/ /, "_")).to_sym
        @starter_class = row[:starter_class]
        @casting_multiplier = row[:casting_multiplier]
        @main_stat = Game.instance.stats.dig(row[:main_stat_id])
        @main_stat_bonus = row[:main_stat_bonus]
        @main_stat_max_stat_bonus = row[:main_stat_max_stat_bonus]

        @genres = Array.new
        @equip_slot_infos = Array.new
        @affect_models = Array.new
        @skills = Array.new
        @spells = Array.new
    end

    def ==(other_object)
        super(other_object) || @symbol == other_object
    end

    def helpfile

    end

end
