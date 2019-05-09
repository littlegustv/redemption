require 'socket'
require_relative 'constants'
require_relative 'commands'
require_relative 'gameobject'
require_relative 'room'
require_relative 'mobile'
require_relative 'player'

class Game

	def initialize( ip_address, port )
		puts "Opening server on #{ip_address}:#{port}"
		@server = TCPServer.open( ip_address, port )
		@players = Hash.new

		@start_time = Time.now
		@interval = 0

		make_rooms

		# game update loop runs on a single thread
		Thread.start do
			game_loop
		end

		# each client runs on its own thread as well
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
						broadcast "#{name} has joined the world.", target
						@players[name] = Player.new( name, self, @rooms.first, client, thread )
						@players[name].input_loop
					end
				end

			end
		end
	end

	def game_loop
		loop do
			new_time = Time.now
			dt = new_time - @start_time
			@start_time = new_time

			@interval += dt
			if @interval > ( 1.0 / Constants::FPS )
				@interval = 0
				update
			end
		end
	end

	# eventually, this will handle all game logic
	def update
		@players.each do | username, player |
			player.update
		end
	end

	def broadcast( message, targets )
		targets.each do | player |
			player.output( message )
		end
	end

	# right now this is just for players??
	def target( query = {} )
		targets = @players.values
		if query[:room]
			targets = targets.select { |t| t.room == query[:room] }
		end
		if query[:not]
			targets = targets.select { |t| t != query[:not] }
		end
		return targets
	end

	def disconnect( name )
		@players.delete( name )
		broadcast "#{name} has disconnected.", target
	end

	# temporary content-creation
	def make_rooms
		@rooms = []
		10.times do |i|
			@rooms.push Room.new( "Room no. #{i}", self )
		end

		@rooms.each_with_index do |room, index|
			room.exits[:north] = @rooms[ (index + 1) % @rooms.count ]
			@rooms[ (index + 1) % @rooms.count ].exits[:south] = room
		end
	end

	def show_who
		%Q(
#{ @players.map{ |name, player| "[#{name}]" }.join( "\n" ) }
		)
	end

end

game = Game.new( ARGV[0] || "127.0.0.1", ARGV[1] || 2000 )