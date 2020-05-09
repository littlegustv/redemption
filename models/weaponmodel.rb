class WeaponModel < ItemModel

    attr_reader :noun
    attr_reader :genre
    attr_reader :dice_count
    attr_reader :dice_sides

    def initialize(id, row)
        super(id, row)
        @dice_count = row[:dice_count]
        @dice_sides = row[:dice_sides]

        # noun
        if row.dig(:noun_id)
            @noun = Game.instance.nouns[row[:noun_id]]
        elsif row.dig(:noun)
            @noun = row[:noun]
        else
            @noun = Game.instance.nouns.values.first
        end

        # genre
        if row.dig(:genre_id)
            @genre = Game.instance.genres[row[:genre_id]]
        elsif row.dig(:genre)
            @genre = row[:genre]
        else
            @genre = Game.instance.genres.values.first
        end
    end
    
    def self.item_class_name
        "weapon".freeze
    end

    def self.item_class
        return Weapon
    end

end
