class Item < GameObject

	attr_accessor :wear_location, :weight

    def initialize( data, game, room )
        @short_description = data[:short_description]
        @keywords = data[:keywords]
        @level = data[:level]
        @weight = data[:weight]
        @cost = data[:cost]
        @long_description = data[:long_description]
        @type = data[:type]
        @wear_location = data[:wear_location]
        @material = data[:material]
        @extraFlags = data[:extraFlags]
        @modifiers = data[:modifiers].merge( data[:ac] )
        # @ac = data[:ac] || [0,0,0,0]
   
        @room = room
        @game = game
    end

    def to_s
    	@short_description
    end

    def to_someone
        "something"
    end

    def long
    	@long_description
    end

    def modifier( key )
        return @modifiers[ key ].to_i
    end

=begin
Object 'A Quicksilver Katar named "Eye-Sting"' is of type weapon. [Clanner Only]
Description: A punch dagger made of quicksilver is here.
Keywords 'quicksilver katar punch dagger eye sting Laika'
Weight 2 lbs, Value 5000 silver, level is 51, Material is quicksilver.
Extra flags: hum
    Item is wielded as a weapon.
    Item belongs to Kite.
    Item has been magically crafted.
    Item is level 8 and has 15013 xp.
    Weapon type is dagger.
    Damage is 6d6 (average 21).
    Weapons flags: vorpal shocking intelligent
Object modifies saves by -2.
Object modifies max dexterity by 2.
Object modifies constitution by 1.
Object modifies hit roll by 5.
Object modifies damage roll by 7.
Object modifies mana by 40.
Object modifies wisdom by 1.
=end

    def lore
%Q(
Object '#{ @short_description }' is of type #{ @type }. [Clanner Only]
Description: #{ @long_description }
Keywords '#{ @keywords.join(' ') }'
Weight #{ @weight } lbs, Value #{ @cost } silver, level is #{ @level }, Material is #{ @material }.
Extra flags: #{ @extraFlags }
#{ @modifiers.map { |key, value| "Object modifies #{key} by #{value}" }.join("\n\r") }
)
    end

end

class Weapon < Item

	attr_accessor :noun, :element

	def initialize( data, game, room )
		super data, game, room

		@noun = data[:noun] || "pierce"
		@flags = data[:flags] || []
		@element = data[:element] || "iron"
		@dice_count = data[:dice_count] || 2
		@dice_sides = data[:dice_sides] || 6
	end

	def damage
        dice( @dice_count, @dice_sides )
	end

end
