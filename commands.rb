module BasicCommands
	
	def self.included (base)
		base.append_whitelist [ "kill", "say", "look", "quit", "help", "who", "north", "south", "east", "west", "up", "down" ]
	end

	def cmd_kill( args )
		if @target
			output "But you are already fighting someone else!"
		elsif ( target = @game.target({ room: @room, not: self, name: args.first.to_s }).first )
			@target = target
			@target.fight self
		else
			output "I can't find anyone with that name #{args}"
		end
	end

	def cmd_say( args )
		if args.length <= 0
			output 'Say what?'
		else
			output "You say '#{args.join(' ')}'"
			@game.broadcast "#{@name} says '#{args.join(' ')}'", @game.target( { :not => self, :room => @room } )
		end
	end

	def cmd_look( args = [] )
		output @room.show
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
			@game.broadcast "#{@name} leaves #{direction}.", @game.target({ :not => self, :room => @room })
			output "You leave #{direction}."
			@room = @room.exits[ direction.to_sym ]
			@game.broadcast "#{@name} has arrived.", @game.target({ :not => self, :room => @room })
			cmd_look
		end
	end

end