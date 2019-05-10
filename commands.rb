module BasicCommands
	
	def self.included (base)
		base.append_whitelist [ "flee", "kill", "say", "look", "quit", "help", "who", "north", "south", "east", "west", "up", "down" ]
	end

	def cmd_kill( args )
		if @position < Position::STAND
			output "You have to stand up first."
		elsif @position >= Position::FIGHT
			output "You are already fighting!"
		elsif ( kill_target = target({ room: @room, not: self, name: args.first.to_s }).first )
			start_combat kill_target
			kill_target.start_combat self
		else
			output "I can't find anyone with that name #{args}"
		end
	end

	def cmd_flee( args )
		if @position < Position::FIGHT
			output "But you aren't fighting anyone!"
		elsif rand(0..10) < 5
			output "You flee from combat!"
			broadcast "#{@name} has fled!", target({ room: @room })

			stop_combat
			send "cmd_#{@room.exits.select{ |k, v| not v.nil? }.keys.sample}"
		else
			output "PANIC! You couldn't escape!"
		end
	end

	def cmd_say( args )
		if args.length <= 0
			output 'Say what?'
		else
			output "You say '#{args.join(' ')}'"
			broadcast "#{@name} says '#{args.join(' ')}'", target( { :not => self, :room => @room } )
		end
	end

	def cmd_look( args = [] )
		output @room.show self
	end

	def cmd_quit( args = [] )
		quit
	end

	def cmd_help( args = [] )
		output "The available commands are [say], [look], [help], [who], the 6 directions and [quit]"
	end

	def cmd_who( args = [] )
		output @game.show_who
	end

	def cmd_north( args = [] )
		move( "north" )
	end

	def cmd_south( args = [] )
		move( "south" )
	end

	def cmd_east( args = [] )
		move( "east" )
	end

	def cmd_west( args = [] )
		move( "west" )
	end

	def cmd_up( args = [] )
		move( "up" )
	end

	def cmd_down( args = [] )
		move( "down" )
	end

	def move( direction )
		if @room.exits[ direction.to_sym ].nil?
			output "There is no exit [#{direction}]."
		else
			broadcast "#{@name} leaves #{direction}.", target({ :not => self, :room => @room })
			output "You leave #{direction}."
			@room = @room.exits[ direction.to_sym ]
			broadcast "#{@name} has arrived.", target({ :not => self, :room => @room })
			cmd_look
		end
	end

end