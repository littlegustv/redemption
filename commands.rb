module BasicCommands
	
	def self.included (base)
		base.append_whitelist [ "say", "look", "quit", "help", "who" ]
	end

	def cmd_say( args )
		if args.count <= 0
			output 'Say what?'
		else
			@game.broadcast "#{@name} says '#{args}'"
		end
	end

	def cmd_look( args = "" )
		output @room.show
	end

	def cmd_quit( args = "" )
		quit
	end

	def cmd_help( args = "" )
		output "The available commands are [say], [look], [help], [who], the 6 directions and [quit]"
	end

	def cmd_who( args = "" )
		output @game.show_who
	end

	def cmd_north( args = "" )
		move( "north" )
	end

	def cmd_south( args = "" )
		move( "south" )
	end

	def cmd_east( args = "" )
		move( "east" )
	end

	def cmd_west( args = "" )
		move( "west" )
	end

	def cmd_up( args = "" )
		move( "up" )
	end

	def cmd_down( args = "" )
		move( "down" )
	end

	def move( direction )
		if @room.exits[ direction ].nil?
			output( "There is no exit [#{direction}].")
		else
			@room = @room.exits[ direction ]
			broadcast( "#{@name} leaves #{direction}.")
			cmd_look
		end
	end

end