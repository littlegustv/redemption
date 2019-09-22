class Player < Mobile

    def initialize( data, game, room, client, thread )
        @buffer = ""
        @delayed_buffer = ""
        @scroll = 40
	    @lag = 0
        @client = client
        @thread = thread
        @commands = []
        super({
          keywords: [data[:name]],
          short_description: data[:name],
          long_description: "#{data[:name]} the Master Rune Maker is here.",
          race_id: data[:race_id],
          alignment: data[:alignment],
          class_id: data[:class_id]
        }, game, room)
    end

    def reconnect( client, thread )
        @client = client
        @thread = thread
        @active = true

        @affects.each do |affect|
            @game.add_affect(affect)
        end
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
            @buffer += "#{ message }\n".capitalize_first
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
            @buffer += @attacking.condition if @attacking
            lines = @buffer.split("\n", 1 + @scroll)
            @delayed_buffer = (lines.count > @scroll ? lines.pop : @delayed_buffer)
            out = lines.join("\n\r")
            if @delayed_buffer.length == 0
                out += "\n\r#{prompt}"
            else
                out += "\n\r\n\r[Hit Return to continue]"
            end

            @client.print color_replace( "\n"+ out )
            @buffer = ""
        end
    end

    def move_to_room( room )
        @room&.players&.delete(self)
        @room = room
        @room.players.push(self)
        @game.do_command self, "look"
    end

    def die( killer )
        output "You have been KILLED!"
        broadcast "%s has been KILLED.", target({ not: [ self ] }), [self]
        stop_combat
        @affects.each do |affect|
            affect.clear(call_complete: false) if !affect.permanent
        end
        room = @game.recall_room( @room.continent )
        move_to_room( room )
        @hitpoints = 10
        @position = Position::REST
    end

    def quit
        Thread.kill( @thread )
        @buffer = ""
        @client.close
        @game.disconnect @short_description
        @room.remove_player(self)
        @affects.each do |affect|
            @game.remove_affect(affect)
        end
        @active = false
    end

    def update( elapsed )
        if @lag > 0
            @lag -= elapsed
        elsif @casting
            if rand(1..100) <= stat(:success)
                @casting.execute( self, @casting.name, @casting_args )
                @casting = nil
                @casting_args = []
            else
                output "You lost your concentration."
                @casting = nil
                @casting_args = []
            end
        elsif @commands.length > 0
            do_command @commands.shift
        end
        super( elapsed )
    end

    def is_player?
        return true
    end

end
