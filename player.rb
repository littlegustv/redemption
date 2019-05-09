class Player < GameObject

	def initialize( name, game, client, thread )
		@client = client
		@thread = thread
		super name, game
	end

	def input_loop
		loop do
			raw = @client.gets
			if raw.nil?
				@game.disconnect @name
				Thread.kill( @thread )
			else
				message = raw.chomp.to_s
				@game.broadcast "#{@name} :: #{message}"
			end
		end
	end

	def output( message )
		@client.puts message
	end

end