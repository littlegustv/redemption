#
# The Model for Weapon items.
#
class WeaponModel < ItemModel

    # @return [Noun] The Noun of the weapon.
    attr_reader :noun

    # @return [Genre] The Genre of the weapon.
    attr_reader :genre

    # @return [Integer] The number of dice used for the weapon's damage.
    attr_reader :dice_count

    # @return [Integer] The number of sides of the weapon's damage dice.
    attr_reader :dice_sides

    def initialize(id, row, temporary = true)
        super(id, row, temporary)
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
