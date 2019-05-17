class Item < GameObject

	attr_accessor :room, :wear_location

    def initialize( data, game, room )
        @short_description = data[:short_description]
        @keywords = data[:keywords]
        @level = data[:level]
        @weight = data[:weight]
        @cost = data[:cost]
        @long_description = data[:long_description]
        @type = data[:type]
        @wear_location = data[:wear_location]
   
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

end

class Weapon < Item

	attr_accessor :noun

	def initialize( data, game, room )
		super data, game, room

		@noun = data[:noun] || "pierce"
		@flags = data[:flags] || []
		@element = data[:element] || "iron"
		@dice_count = data[:dice_count] || 2
		@dice_sides = data[:dice_sides] || 6
	end

	def damage
		@dice_count.to_i.times.collect { |i| rand(1...@dice_sides.to_i) }.sum
	end

end