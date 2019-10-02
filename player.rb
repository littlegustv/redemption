class Player < Mobile

    def initialize( data, game, room, client, thread )
        @buffer = ""
        @delayed_buffer = ""
        @scroll = 60
	    @lag = 0
        @client = client
        @thread = thread
        @commands = []
        data[:keywords] = data[:name].to_a
        data[:short_description] = data[:name]
        data[:long_description] = "#{data[:name]} the Master Rune Maker is here."
        super(data, game, room)
    end

    # alias for @game.destroy_player(self)
    def destroy
        @game.save
        @game.destroy_player(self)
    end

    # this method basically has to undo a @game.destroy_player(self)
    def reconnect( client, thread )
        if @client
            @client.close
        end
        if @thread
            Thread.kill( @thread )
        end
        if !@active
            @affects.each do |affect|
                @game.add_affect(affect)
            end
            @inventory.items.each do |item|
                @game.items << item
                item.affects.each do |affect|
                    @game.add_affect(affect)
                end
            end
            equipment.each do |item|
                @game.items << item
                item.affects.each do |affect|
                    @game.add_affect(affect)
                end
            end
        end
        @client = client
        @thread = thread
        @active = true
    end

    def input_loop
        loop do
            begin
                raw = @client.gets
            rescue StandardError => msg
                log "Player #{self.name} disconnected: #{msg}"
                quit
            end
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
        if !@active
            return
        end
        objects = objects.to_a
        if objects.count > 0
            @buffer += "#{ message % objects.map{ |obj| (obj.respond_to?(:show)) ? obj.show( self ) : obj.to_s } }\n".capitalize_first
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
            begin
                @client.print color_replace( "\n"+ out )
            rescue
                log "Error in player.send_to_client #{self.name}"
                quit
            end
            @buffer = ""
        end
    end

    def die( killer )
        output "You have been KILLED!"
        broadcast "%s has been KILLED.", target({ not: [ self ] }), [self]
        stop_combat
        @affects.each do |affect|
            affect.clear(silent: true) if !affect.permanent
        end
        room = @game.recall_room( @room.continent )
        move_to_room( room )
        @hitpoints = 10
        @position = Position::REST
    end

    def quit(silent: false)
        stop_combat
        if !silent
            broadcast "%s has left the game.", @game.target({not: [self], list: @room.occupants}), self
        end
        if @thread
            Thread.kill( @thread )
        end
        @buffer = ""
        if @client
            begin
                if !silent
                    @client.print "Alas, all good things must come to an end.\n\r"
                end
            rescue
                log "Error on player quitting."
            end
            @client.close
        end
        @client = nil
        @thread = nil
        destroy
        return true
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

    def db_source_type
        return "Player"
    end

end
