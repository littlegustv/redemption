class Game

	def initialize( ip_address, port )
		puts "Opening server on #{ip_address}:#{port}"
		@server = TCPServer.open( ip_address, port )
		@players = Hash.new

		@start_time = Time.now
		@interval = 0
		@clock = 0

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
						broadcast "#{name} has joined the world.", target
						@players[name] = Player.new( name, self, @rooms.first, client, thread )
						client.puts "Users Online: [#{ @players.keys.join(', ') }]"
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
			# each update FRAME
			if @interval > ( 1.0 / Constants::FPS )
				@interval = 0
				@clock += 1

				update( 1.0 / Constants::FPS )
				send_to_client

				# each combat ROUND
				if @clock % Constants::ROUND == 0
					combat
				end
			end
		end
	end

	# eventually, this will handle all game logic
	def update( elapsed )
		@players.each do | username, player |
			player.update elapsed
		end
	end

	def send_to_client
		@players.each do | username, player |
			player.send_to_client
		end
	end

	def combat
		@players.each do | username, player |
			player.combat
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
		targets = targets.select { |t| query[:room].to_a.include? t.room }							if query[:room]
		targets = targets.select { |t| !query[:not].to_a.include? t } 									if query[:not]
		targets = targets.select { |t| query[:attacking].to_a.include? t.attacking } 		if query[:attacking]
		targets = targets.select { |t| t.name.start_with? query[:name] } 								if query[:name]
		targets = targets[0...query[:limit].to_i] if query[:limit]
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