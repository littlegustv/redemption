class GameObject

	attr_accessor :name

	def initialize( name, game )
		@name = name
		@game = game
	end

	def update
	end

	def output( message )
	end

end