class Player < Mobile

    def initialize( name, game, room, client, thread )
        @buffer = ""
	    @lag = 0
        @client = client
        @thread = thread
        @commands = []
        super name, game, room
    end

    def input_loop
        loop do
            raw = @client.gets
            if raw.nil?
                quit
            else
                message = raw.chomp.to_s
                @commands.push message
            end
        end
    end

    def do_command( input )
        cmd, args = input.split " ", 2
        @game.do_command( self, cmd, args.to_s.split(" ") )
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
            @client.puts @attacking.condition if @attacking
            @buffer = ""
            @client.puts "\n#{prompt}"
        end
    end

    def quit
        @client.close
        @game.disconnect @name
        Thread.kill( @thread )
    end

    def update( elasped )
    	if @lag > 0
    		@lag -= elasped
    	elsif @commands.length > 0
    		do_command @commands.shift
    	end
    end

end
