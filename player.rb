class Player < Mobile

    attr_reader :client

    def initialize( data, game, room, client )
        data[:keywords] = data[:name].to_a
        data[:short_description] = data[:name]
        data[:long_description] = "#{data[:name]} the Master Rune Maker is here."
        super(data, game, room)
        @buffer = ""
        @delayed_buffer = ""
        @scroll = 60
	    @lag = 0
        @client = client
        @commands = []
    end

    # Player destroy works a little differently from other gameobjects.
    # Player destroy just marks it for destruction in the main thread so you can call it
    # from the client's own thread.
    def destroy
        if @client
            @client.player = nil
            @client = nil
        end
        @game.destroy_player(self)
    end

    # this method basically has to undo a @game.destroy_player(self) call
    def reconnect( client )
        if @client
            @client.disconnect
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
        @active = true
    end

    # this is a client thread method!
    def input(s)
        s = s.chomp.to_s
        if @delayed_buffer.length > 0 && s.length > 0
            @delayed_buffer = ""
        end
        @commands.push(s)
    end

    # Called when a player first logs in.
    def login
        output "Welcome, #{@name}."
        move_to_room(@room)
        broadcast("%s has entered the game.", target({not: [self], list: @room.occupants}), [self])
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

    def send_to_client
        if @buffer.length > 0
            @buffer += @attacking.condition if @attacking
            lines = @buffer.split("\n", 1 + @scroll)
            @delayed_buffer = (lines.count > @scroll ? lines.pop : @delayed_buffer)
            out = lines.join("\n")
            if @delayed_buffer.length == 0
                out += "\n#{prompt}"
            else
                out += "\n\n[Hit Return to continue]"
            end
            @client.send_output(out)
            @buffer = ""
        end
    end

    def die( killer )
        output "You have been KILLED!"
        broadcast "%s has been KILLED.", target({ not: [ self ] }), [self]
        @game.fire_event( :event_on_die, {}, self )
        stop_combat
        @affects.each do |affect|
            affect.clear(silent: true) if !affect.permanent
        end
        room = @game.recall_room( @room.continent )
        move_to_room( room )
        @hitpoints = 10
        @position = Constants::Position::REST
    end

    def quit(silent: false)
        @game.save
        stop_combat
        if !silent
            broadcast "%s has left the game.", @game.target({not: [self], list: @room.occupants}), self
        end
        @buffer = ""
        if @client
            if !silent
                @client.send_output("Alas, all good things must come to an end.\n")
                @client.list_characters
            end
            @client.player = nil
            @client = nil
        end
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

    def process_commands(elapsed)
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
    end

    def is_player?
        return true
    end

    def db_source_type
        return "Player"
    end

end
