class Player < Mobile

    # @return [TCPSocket, nil] The Client Connection.
    attr_reader :client
    
    # @return [Integer] The account ID associated with this player.
    attr_reader :account_id

    #
    # Player Initializer.
    #
    # @param [PlayerModel] player_model The model used to generate this player object.
    # @param [Room] room The room this player is going into.
    # @param [TCPSocket] client The client connection for the player.
    #
    def initialize( player_model, room, client )
        super(player_model, room)
        @name = player_model.name
        @creation_points = player_model.creation_points
        @account_id = player_model.account_id
        @buffer = ""
        @delayed_buffer = ""
        @scroll = 60
        @client = client

        # @type [Array<Array<Command, String>>]
        # The array of inputs for this player to execute.
        @commands = []
    end

    #
    # Destroys this player.
    # Disconnects it from its client.
    # Calls Game#remove_player to remove the player from global lists.
    #
    # @return [nil]
    #
    def destroy
        Game.instance.remove_player(self)
        if @client
            @client.player = nil
            @client = nil
        end
        super
    end

    # this method basically has to undo a Player#destroy call
    def reconnect( client )
        if @client
            @client.disconnect
        end
        if !@active
            @affects.each do |affect|
                affect.active = true
                # Game.instance.add_global_affect(affect)
            end
            self.items.each do |item|
                Game.instance.add_global_item(item)
                if item.affects
                    item.affects.each do |affect|
                        affect.active = true
                        # Game.instance.add_global_affect(affect)
                    end
                end
            end
        end
        @client = client
        @active = true
    end
    
    #
    # Receive input from the client. What this method does is add the input and its associated
    # Command to @commands. Next time `process_commands` is called ( _not_ a client method),
    # all valid commands will be executed.
    # 
    # __This is a client thread method__
    #
    # @param [String] s The input for this player.
    #
    # @return [nil]
    #
    def input(s)
        s = s.chomp.to_s
        if @delayed_buffer.length > 0 && s.length > 0
            @delayed_buffer = ""
        end
        s = s.sanitize
        cmd_keyword = s.to_args[0].to_s
        command = Game.instance.find_commands( self, cmd_keyword ).last
        @commands.push([command, s])
        return
    end

    # Called when a player first logs in.
    def login
        output "Welcome, #{@name}."
        move_to_room(@room)
        (@room.occupants - [self]).each_output("0<N> has entered the game.", [self])
    end

    #
    # Player output actually does the parsing of formats and replacement of object pronouns.
    #
    # @param [String] message The message format.
    # @param [Array<GameObject>, GameObject] objects The GameObjects to use in the format.
    #
    # @return [nil]
    #
    def output( message, objects = [] )
        if !@active
            return
        end
        objects = [objects].flatten
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
        return
    end

    #
    # Delayed output is how text gets broken up when it's too long and sent in chunks.
    # This method is only called from the WhiteSpace command.
    #
    # @return [nil]
    #
    def delayed_output
        if @delayed_buffer.length > 0
            @buffer += @delayed_buffer
            @delayed_buffer = ""
        else
            @buffer += " "
        end
        return
    end

    #
    # The player's prompt.
    #
    # @return [String] The prompt.
    #
    def prompt
        "{c<#{@health.to_i}/#{max_health}hp #{@mana.to_i}/#{max_mana}mp #{@movement.to_i}/#{max_movement}mv>{x"
    end

    #
    # Sends the current output (or some portion of it) to the Client.
    # If the output buffer is too large, the extra portion will be saved in @delayed_buffer
    # to be output later (or not, if the client opts out).
    #
    # @return [nil]
    #
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

    #
    # Override of Mobile#die because player death is handled differently (respawning!).
    #
    # @param [GameObject] killer The killer.
    #
    # @return [nil]
    #
    def die( killer )
        super(killer)
        @affects.each do |affect|
            affect.clear(true) if !affect.permanent
        end
        room = @room.continent.recall_room
        move_to_room( room )
        @health = 10
        @position = :resting.to_position
    end

    #
    # Quit the player.
    #
    # @param [Boolean] silent True if the quitting should be silent.
    # @param [Boolean] save True if the player should trigger a game-wide save. (default: true)
    #
    # @return [Boolean] True if the player was quit successfully.
    #
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

    #
    # Process commands.
    # 
    # Any zero lag commands are processed instantly. Up to one non-zero lag command will
    #  be processed if the player is not currently lagged from some other cause.
    #
    # @return [nil]
    #
    def process_commands
        frame_time = Game.instance.frame_time
        if @lag && @lag <= frame_time
            @lag = nil
        end
        if @casting
            if rand(1..100) > stat(:failure)
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
        return
    end

    #
    # Override of Mobile#is_player? to return true.
    #
    # @return [Boolean] True.
    #
    def is_player?
        return true
    end

end
