require 'socket'                 # Get sockets from stdlib

class GameObject

	attr_accessor :name

	def initialize( name, game )
		@name = name
		@game = game
	end

end

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

class Game

	def initialize( ip_address, port )
		puts "Opening server on #{ip_address}:#{port}"
		@server = TCPServer.open( ip_address, port )
		@players = Hash.new

		loop do
			thread = Thread.start(@server.accept) do |client|

				name = nil
				while name.nil?
					client.puts "By what name do you wish to be known?"
					name = client.gets.chomp.to_s

					if name.length <= 2
						client.puts "Your name must be at least three characters."
						name = nil
					elsif @players.has_key? name
						client.puts "That name is already in use, try another."
						name = nil
					else
						client.puts "Welcome, #{name}."
						client.puts "Users Online: [#{ @players.keys.join(', ') }]"
						broadcast "#{name} has joined the world."
						@players[name] = Player.new( name, self, client, thread )
						@players[name].input_loop
					end
				end

			end
		end
	end

	def broadcast( message )
		@players.each do | username, player |
			player.output( message )
		end
	end

	def disconnect( name )
		@players.delete( name )
		broadcast "#{name} has disconnected."
	end

end

game = Game.new( ARGV[0] || "127.0.0.1", ARGV[1] || 2000 )