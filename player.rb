class Player < Mobile

    def initialize( name, game, room, client, thread )
        @buffer = ""
        @delayed_buffer = ""
        @scroll = 40
	    @lag = 0
        @client = client
        @thread = thread
        @commands = []
        super({ keywords: [name], short_description: name, long_description: "#{name} the Master Rune Maker is here.", race: "Troll" }, game, room)
    end

    def input_loop
        loop do
            raw = @client.gets
            if raw.nil?
                quit
            else
                message = raw.chomp.to_s
                if @delayed_buffer.length > 0 && message.length > 0
                    @delayed_buffer = ""
                end
                @commands.push message
            end
        end
    end

    def output( message, objects = [] )
        if objects.count > 0
            @buffer += "#{ message % objects.map{ |obj| obj.show( self ) } }\n".capitalize_first
        else
            @buffer += "#{message}\n".capitalize_first
        end
    end

    def delayed_output
        if @delayed_buffer.length > 0
            @buffer += @delayed_buffer
            @delayed_buffer = ""
        else
            @buffer += " "
        end
    end

    def prompt
        "{c<#{@hitpoints}/#{maxhitpoints}hp #{@manapoints}/#{maxmanapoints}mp #{@movepoints}/#{maxmovepoints}mv>{x"
    end

    def color_replace( message )
        Constants::COLOR_CODE_REPLACEMENTS.each { |r| message = message.gsub("#{r[0]}", "#{r[1]}") }
        return message
    end

    def send_to_client
        if @buffer.length > 0
            lines = @buffer.split("\n", 1 + @scroll)
            @delayed_buffer = (lines.count > @scroll ? lines.pop : @delayed_buffer)
            out = lines.join("\n\r")
            @client.puts color_replace( out )
            @buffer = ""

            @client.puts color_replace( @attacking.condition ) if @attacking
            if @delayed_buffer.length == 0
                @client.puts color_replace( "\n#{prompt}" )
            else
                @client.puts( "\n\r[Hit Return to continue]")
            end
        end
    end

    def die( killer )
        output "You have been KILLED!"
        broadcast "%s has been KILLED.", target({ not: [ self ] }), [self]
        stop_combat
    end

    def who
        "[#{@level.to_s.rjust(2)} #{@race.ljust(7)} #{@class.rjust(7)}] #{@short_description}"
    end

    def quit
        Thread.kill( @thread )
        @buffer = ""
        @client.close
        @game.disconnect @short_description
    end

    def update( elapsed )
    	if @lag > 0
    		@lag -= elapsed
    	elsif @commands.length > 0
    		do_command @commands.shift
    	end
        super( elapsed )
    end

end
