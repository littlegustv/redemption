class Player < Mobile

    def initialize( name, game, room, client, thread )
        @buffer = ""
	    @lag = 0
        @client = client
        @thread = thread
        @commands = []
        super({ keywords: [name], short_description: name, long_description: "#{name} the Master Rune Maker is here." }, game, room)
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

    def output( message, objects = [] )
        @buffer += "#{ message % objects.map{ |obj| obj.show( self ) } }\n"
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
        Thread.kill( @thread )
        @buffer = ""
        @client.close
        @game.disconnect @short_description
    end

    def update( elasped )
    	if @lag > 0
    		@lag -= elasped
    	elsif @commands.length > 0
    		do_command @commands.shift
    	end
    end

end