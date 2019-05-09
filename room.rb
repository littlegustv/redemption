class Room < GameObject

	attr_accessor :exits

	def initialize( name, game, exits = {} )
		@exits = { north: nil, south: nil, east: nil, west: nil, up: nil, down: nil }
		@exits.each do | direction, room |
			if not exits[ direction ].nil?
				@exits[ direction ] = exits[ direction ]
			end
		end
		super name, game
	end

	def show
		%Q(
#{ @name }
[#{ @exits.select { |direction, room| not room.nil? }.keys.join(", ") }]
		)
	end

end