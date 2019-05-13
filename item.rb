class Item < GameObject

	attr_accessor :room

    def initialize( data, game, room )
        @short_description = data[:short_description]
        @keywords = data[:keywords]
        @level = data[:level]
        @weight = data[:weight]
        @cost = data[:cost]
        @long_description = data[:long_description]
        @type = data[:type]
        
        @room = room
        @game = game
    end

    def to_s
    	@short_description
    end

    def long
    	@long_description
    end

end