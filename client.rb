#
# The Client is where all player input comes from. Clients exist on their own threads,
# so extra care must be taken to ensure methods marked `CLIENT METHOD` are only
# ever called from the Client's thread, and not the main game logic thread.
#
class Client

    #
    # The different states clients can exist in.
    #
    module ClientState
        LOGIN = 0
        ACCOUNT = 1
        CREATION = 2
        PLAYER = 3
    end

    # default sleep time for the client between various actions (creating new accounts/players, etc)
    @@sleep_time = 0.005

    # @return [Player, nil] The Player object this client is controlling, or nil if there is no player currently.
    attr_accessor :player

    # @return [TCPSocket] The client's socket connection.
    attr_accessor :client_connection

    #
    # Client initializer.
    #
    # @param [TCPSocket] client_connection The client's socket connection.
    # @param [Thread] thread The thread this client is running on.
    #
    def initialize(client_connection, thread)
        # @type [TCPSocket]
        @client_connection = client_connection
        # @type [Thread]
        @thread = thread
        @quit = false
        @account_id = nil
        @client_state = ClientState::LOGIN
        @player = nil
        @tries = 0
        @scroll = 60 # unused?
        @name = nil
    end

    # Main input loop

    #
    # `CLIENT METHOD`
    #
    # The client's main input loop.
    #
    # @return [nil] 
    #
    def input_loop
        send_output(Game.instance.game_settings[:login_splash])
        loop do
            case @client_state
            when ClientState::LOGIN
                do_login
            when ClientState::ACCOUNT
                do_account
            when ClientState::CREATION
                do_creation
            when ClientState::PLAYER
                do_player
            end
            if @tries > 2
                @quit = true
            end
            break if @quit
        end
        send_output("Goodbye.")
        disconnect
        return
    end

    #
    # `CLIENT METHOD`
    #
    # Log into an account.
    # When successful, `@client_state` will be set to `ClientState::ACCOUNT`,
    # and account management will commence.
    #
    # @return [nil]
    #
    def do_login
        account_row = nil
        name = nil
        while name.nil?
            send_output("Enter your account name or \"new\" for a new account.")
            name = get_input
            return if name.nil?
            if name != name.gsub(/[^0-9A-Za-z]/, '')
                send_output("Illegal account name. Alphanumeric characters only, please.")
                name = nil
            end
        end
        if "new" == name.downcase # new account
            name = nil
            while name.nil?
                send_output("Please choose your account name or \"back\" to cancel.")
                name = get_input
                if name.downcase == "back"
                    return
                elsif name != name.gsub(/[^0-9A-Za-z]/, '')
                    send_output("Illegal account name. Alphanumeric characters only, please.")
                    name = nil
                elsif Game.instance.account_data.find{ |id, row| row[:name] == name }
                    send_output("That account name is already taken.")
                    name = nil
                end
            end
            md5 = nil
            password = nil
            while md5.nil?
                send_output("Please choose a password.")
                password = get_input
                if password.length < 6
                    send_output("Passwords must be at least 6 characters long.")
                    password = nil
                elsif password != password.gsub(/[^0-9A-Za-z]/, '')
                    send_output("Illegal password. Alphanumeric characters only, please.")
                    password = nil
                else
                    md5 = Digest::MD5.hexdigest(password)
                end
                if md5
                    send_output("Re-enter password:")
                    password2 = get_input
                    if password2 != password
                        send_output("Passwords don't match.")
                        md5 = nil
                    end
                end
            end
            # name and md5 for a new account have now been input
            account_data = {name: name, md5: md5}
            Game.instance.new_accounts.push(account_data) # add this account data to the list of accounts to be created
            while (account_row = Game.instance.account_data.values.find{ |row| row[:name] == name }).nil?
                sleep(@@sleep_time) # wait until the account exists in the database and has been loaded
            end
        else # try existing account
            send_output("Password:")
            password = get_input
            md5 = Digest::MD5.hexdigest(password)
            if (account_row = Game.instance.account_data.values.find{ |row| row[:name].downcase == name.downcase && row[:md5] == md5}).nil?
                send_output("Login credentials incorrect.")
                @tries += 1
                return
            end
            # check for already logged in accounts!
            if Game.instance.client_account_ids.include?(account_row[:id])
                send_output("That account is already logged in.")
                @tries += 1
                return
            end
        end
        @account_id = account_row[:id]
        @name = account_row[:name]
        Game.instance.client_account_ids.push(@account_id)
        @client_state = ClientState::ACCOUNT
        send_output("\nWelcome, #{@name}.\n")
        list_characters
        return
    end

    #
    # `CLIENT METHOD`
    #
    # Handle account management.
    #
    # @param [String, nil] input 
    #
    # @return [nil]
    #
    def do_account(input = nil)
        send_output("{c<#{@name}>{x")
        if !input
            input = get_input
        end
        words = input.split
        word1 = words.dig(0).to_s
        word2 = words.dig(1).to_s
        if word1 == ""
            send_output("What's that? Try \"help\" to see what you can do from here.")
            return
        end
        if "new".fuzzy_match(word1)
            @client_state = ClientState::CREATION
            return
        elsif "play".fuzzy_match(word1)
            if word2.length < 1
                send_output("Who did you want to play?")
                return
            end
            c_row = Game.instance.saved_player_data.values.find{ |row| row[:account_id] == @account_id.to_i && row[:name].downcase == word2.downcase }
            if !c_row
                send_output("You don't have a character with that name.")
                return
            end
            send_output("Logging in as #{c_row[:name]}.")
            Game.instance.logging_players.push([c_row[:id], self])
            while (@player = Game.instance.players.find{ |p| p.id == c_row[:id] }).nil?
                sleep(@@sleep_time) # wait until the player has been loaded by the game thread
            end
            @player.login
            @client_state = ClientState::PLAYER
        elsif "quit".fuzzy_match(word1) || "exit".fuzzy_match(word1)
            @quit = true
        elsif "list".fuzzy_match(word1)
            list_characters
        elsif "help".fuzzy_match(word1)
            width = 24
            out = "\n#{"new".rpad(width)} Create a new character.\n" +
            "#{"play <character name>".rpad(width)} Play an existing character.\n" +
            "#{"list".rpad(width)} List your available characters.\n" +
            "#{"settings".rpad(width)} View and modify account settings.\n" +
            "#{"quit".rpad(width)} Log out\n"
            send_output(out)
        elsif "settings".fuzzy_match(word1)
            send_output("There are no settings just yet.")
        else
            send_output("What's that? Try \"help\" to see what you can do from here.")
        end
        return
    end

    #
    # `CLIENT METHOD`
    #
    # Handle creation of a new character.
    #
    # @return [nil]
    #
    def do_creation
        send_output("Type \"back\" at any point to abandon character creation.\n")
        name = nil
        @client_state = ClientState::ACCOUNT # the only way out of this is back to account management
        while name.nil?
            send_output("By what name do you wish to be known?")
            name = get_input.capitalize
            if name.downcase == "back"
                return
            end
            if name.length < 3 || name.length > 10
                send_output("Your name must be between three and ten characters.")
                name = nil
            elsif name != name.gsub(/[^A-Za-z]/, '')
                send_output("Illegal character name. No spaces, only letters.")
                name = nil
            elsif Game.instance.saved_player_data.values.find{ |row| row[:name] == name }
                send_output("That name is already taken.")
                name = nil
            end
        end

        race_id = nil
        races = Game.instance.races.values.select{ |race| race.player_race && race.starter_race }
        race_names = races.map{ |race| race.name }
        send_output("The following races are available:\n" +
        "#{race_names.map{ |n| n.rpad(10) }.each_slice(5).to_a.map(&:join).join("\r\n")}\n")
        while race_id.nil?
            send_output("What is your race (help for more information)?")
            race_input = get_input
            if race_input.downcase == "back"
                return
            end
            race = races.find{ |race| race.name.fuzzy_match(race_input) }
            if race
                race_id = race.id
            elsif race_input.fuzzy_match("help")
                send_output("Placeholder race help - p2implement")
            else
                send_output("You must choose a valid race!")
            end
        end

        mobile_class_id = nil
        classes = Game.instance.mobile_classes.values.select{ |c| c.starter_class }
        class_names = classes.map{ |c| c.name }
        send_output("Select a class:\n--------------\n" +
        "#{class_names.join("\n")}\n")
        while mobile_class_id.nil?
            send_output("What is your class (help for more information)?")
            class_input = get_input
            if class_input.downcase == "back"
                return
            end
            mobile_class = classes.find{ |c| c.name.fuzzy_match(class_input) }
            if mobile_class
                mobile_class_id = mobile_class.id
            elsif class_input.fuzzy_match("help")
                send_output("Placeholder class help - p2implement")
            else
                send_output("You must choose a valid class!")
            end
        end

        alignment = nil
        while alignment.nil?
            send_output("You may be good, neutral, or evil.\nWhat is your alignment?")
            align_input = get_input
            if align_input.downcase == "back"
                return
            end
            if "good".fuzzy_match(align_input)
                alignment = 1000
            elsif "neutral".fuzzy_match(align_input)
                alignment = 0
            elsif "evil".fuzzy_match(align_input)
                alignment = -1000
            else
                send_output("Please a valid alignment")
            end
        end

        gender_id = nil
        genders = Game.instance.genders.values

        if genders.length > 1
            while gender_id.nil?
                send_output("You may be #{genders[0..-2].map{|g| g.name }.join(", ")}#{genders.size > 2 ? "," : ""} or #{genders[-1].name}.\nWhat is your gender?")
                gender_input = get_input
                if gender_input.downcase == "back"
                    return
                end
                gender = genders.find{ |g| g.name.fuzzy_match(gender_input) }
                if gender
                    gender_id = gender.id
                else
                    send_output("Please enter a valid gender.")
                end
            end
        else
            gender = genders.first.id
        end

        player_data = {
            account_id: @account_id,
            name: name,
            race_id: race_id,
            mobile_class_id: mobile_class_id,
            alignment: alignment,
            gender_id: gender_id,
            creation_points: 5,
        }
        send_output("Creating #{name}...")
        Game.instance.new_players.push(player_data)
        while (Game.instance.saved_player_data.values.find{ |row| row[:name] == name }).nil?
            sleep(@@sleep_time)
        end
        list_characters
    end

    #
    # `CLIENT METHOD`
    #
    # Play a character. This is where gameplay inputs are received.
    #
    # @return [nil]
    #
    def do_player
        input = get_input
        if @player
            @player.input(input)
        else
            @client_state = ClientState::ACCOUNT
            list_characters
            do_account(input)
        end
        return
    end

    #
    # `CLIENT METHOD`
    #
    # List characters for a given player account and give some instructions on how to proceed.
    #
    # @return [nil]
    #
    def list_characters
        c_rows = Game.instance.saved_player_data.values.select{ |row| row[:account_id] == @account_id.to_i }
        c_rows = c_rows.sort_by{ |row| row[:name] }
        lines = []
        c_rows.each do |c_row|
            level = c_row[:level]
            race_name = Game.instance.races[c_row[:race_id]].display_name
            class_name = Game.instance.mobile_classes[c_row[:mobile_class_id]].name
            name = c_row[:name]
            lines << "[#{level.to_s.lpad(2)} #{race_name.rpad(8)} #{class_name.capitalize.lpad(8)}] #{name}"
        end
        if lines.length > 0
            send_output("Your characters:\n")
            send_output(lines.join("\n"))
            send_output("\nLog in with a character by typing \"play <character name>\",\ncreate a new character with \"new\". \"Quit\" to exit.")
        else
            send_output("You have no characters.")
            send_output("Create a new character with \"new\". \"Quit\" to exit.")
        end
        return
    end

    # basic input/output

    #
    # `CLIENT METHOD`
    #
    # Get a single input.
    #
    # @return [String, nil] The input from the client, or `nil`.
    #
    def get_input
        if !@client_connection
            return
        end
        raw = nil
        begin
            raw = @client_connection.gets.chomp.to_s.sanitize
        rescue StandardError => msg
            if "#{msg}" != "stream closed in another thread"
                log "Client #{@account_id} get_input: #{msg}"
            end
            log "Client #{@account_id} get_input: #{msg}"
            disconnect
        end
        if !raw
            disconnect
        end
        return raw
    end

    #
    # Do a single output.
    #
    # @param [String] s The string to output.
    #
    # @return [nil]
    #
    def send_output(s)
        if !@client_connection
            return
        end
        if s[-1] != "\n"
            s += "\n"
        end
        s = s.gsub(/\n/, "\r\n")
        begin
            @client_connection.print s.replace_color_codes
        rescue StandardError => msg
            log "Client #{@account_id} send_output: #{msg}"
            disconnect
        end
        return
    end

    #
    # Handle a disconnect.
    #
    # @return [nil]
    #
    def disconnect
        Game.instance.client_account_ids.delete(@account_id)
        if @client_connection
            begin
                @client_connection.close
            rescue StandardError => msg
                log(msg)
            end
            @client_connection = nil
        end
        # log("Disconnected client with account_id #{@account_id}")
        if @thread
            begin
                Thread.kill(@thread)
            rescue
            end
            @thread = nil
        end
        @quit = true
        return
    end

end
