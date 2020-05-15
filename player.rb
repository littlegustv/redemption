class Player < Mobile

    attr_reader :client
    attr_reader :account_id

    def initialize( player_model, room, client )
        super(player_model, room)
        @name = player_model.name
        @creation_points = player_model.creation_points
        @account_id = player_model.account_id
        @learned_skills = player_model.learned_skills
        @learned_spells = player_model.learned_spells
        @buffer = ""
        @delayed_buffer = ""
        @scroll = 60
        @client = client
        @commands = []
    end

    #
    def destroy
        super
        if @client
            @client.player = nil
            @client = nil
        end
        Game.instance.destroy_player(self)
    end

    # this method basically has to undo a Game.instance.destroy_player(self) call
    def reconnect( client )
        if @client
            @client.disconnect
        end
        if !@active
            @affects.each do |affect|
                affect.active = true
                Game.instance.add_global_affect(affect)
            end
            self.items.each do |item|
                Game.instance.add_global_item(item)
                item.affects.each do |affect|
                    affect.active = true
                    Game.instance.add_global_affect(affect)
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
        s = s.sanitize
        cmd_keyword = s.to_args[0].to_s
        command = Game.instance.find_commands( self, cmd_keyword ).last
        @commands.push([command, s])
    end

    # Called when a player first logs in.
    def login
        output "Welcome, #{@name}."
        move_to_room(@room)
        (@room.occupants - [self]).each_output("0<N> has entered the game.", [self])
    end

    # send output to player. this is where
    def output( message, objects = [] )
        if !@active
            return
        end
        message = message.dup
        # verb conjugation replacement
        #
        # [0] => entire match                   "0{drop, drops}"
        # [1] => object index                   "0"
        # [2] => first person result            "drop"
        # [3] => third person result            "drops"
        message.scan(/((\d+)<\s*([^<>]*)\s*,\s*([^<>]*)\s*>)/i).each do |match_group|
            index = match_group[1].to_i
            to_replace = match_group[0]
            replacement = match_group[3] # default to second option
            if index < objects.length && index >= 0
                obj = objects[index]
                if obj == self # replace with first string if object in question is self
                    replacement = match_group[2]
                end
            end
            message.sub!(to_replace, replacement)
        end

        # noun/pronoun replacement
        #
        # [0] => entire match                   "0{An}'s'"
        # [1] => object index                   "0"
        # [2] => aura option                    "A"
        # [3] => replacement option             "n"
        # [4] => possessive                     "'s"
        message.scan(/((\d+)<([Aa]?)([#{Constants::OutputFormat::REPLACE_HASH.keys.join}])>('s)?)/i).each do |match_group|
            index = match_group[1].to_i
            to_replace = match_group[0]
            replacement = "~" # default replacement - SHOULD get swapped with something!
            if index < objects.length && index >= 0
                obj = objects[index]
                replacement = ""
                case match_group[2]
                when "a"
                    replacement.concat(obj.short_auras)
                when "A"
                    replacement.concat(obj.long_auras)
                end
                noun = self.send(Constants::OutputFormat::REPLACE_HASH[match_group[3].downcase], obj).dup
                if match_group[3] == match_group[3].upcase
                    noun.capitalize_first!
                end
                replacement.concat(noun)
                possessive = match_group[4] # match on possessive! ("'s")
                if obj == self && match_group[3].downcase == "n" && possessive == "'s"
                    possessive = "r"
                end
                if possessive
                    replacement.concat(possessive)
                end
            end
            message.sub!(to_replace, replacement)
        end

        message.gsub!(/>>/, ">")
        message.gsub!(/<</, "<")
        @buffer += message.capitalize_first + "\n"
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
        "{c<#{@health}/#{max_health}hp #{@mana}/#{max_mana}mp #{@movement}/#{max_movement}mv>{x"
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
        (@room.occupants - [self]).each_output "0<N> has been KILLED.", [self]
        Game.instance.fire_event(self, :event_on_die, {} )
        stop_combat
        @affects.each do |affect|
            affect.clear(true) if !affect.permanent
        end
        room = @room.continent.recall_room
        move_to_room( room )
        @health = 10
        @position = :resting.to_position
    end

    def quit(silent = false, save = true)
        if save
            Game.instance.save
        end
        stop_combat
        if !silent
            (@room.occupants - [self]).each_output "0<N> has left the game.", self
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

    def process_commands
        frame_time = Game.instance.frame_time
        if @lag && @lag <= frame_time
            @lag = nil
        end
        if @casting
            if rand(1..100) <= stat(:success)
                @casting.execute( self, @casting.name, @casting_args, @casting_input )
                @casting = nil
                @casting_args = []
            else
                output "You lost your concentration."
                @casting = nil
                @casting_args = []
            end
        end

        @commands.each_with_index do |cmd_array, index|            
            if !cmd_array[0] || cmd_array[0].lag == 0 || (!@lag)
                do_command(cmd_array[1])
                @commands[index] = nil
            end
        end
        @commands.reject!(&:nil?)
    end

    def is_player?
        return true
    end

    def db_source_type_id
        return 8
    end

end
