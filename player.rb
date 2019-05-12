class Player < Mobile

	@@whitelist = []

	def self.append_whitelist( list )
		@@whitelist += list
	end

	include BasicCommands

	def initialize( name, game, room, client, thread )
		@buffer = ""
		@client = client
		@thread = thread
		super name, game, room
	end

	def input_loop
		loop do
			raw = @client.gets
			if raw.nil?
				quit
			else
				message = raw.chomp.to_s
				do_command message
			end
		end
	end

	def do_command( input )
		cmd, args = input.split " ", 2
		if @@whitelist.include? cmd
			self.send "cmd_#{cmd.to_s}", args.to_s.split(" ")
		else
			output "Huh?"
		end
	end

	def output( message )
		@buffer += "#{message}\n"
	end

	def prompt
		"<#{@hitpoints}/500hp>"
	end

	def send_to_client
		if @buffer.length > 0
			@client.puts @buffer
			@buffer = ""
			@client.puts prompt
		end
	end

	def quit
		@client.close
		@game.disconnect @name
		Thread.kill( @thread )
	end

end
