class Client

    @@sleep_time = 0.005

    attr_accessor :player
    attr_accessor :client_connection

    def initialize(client_connection, thread)
        @client_connection = client_connection
        @thread = thread
        @quit = false
        @account_id = nil
        @client_state = Constants::ClientState::LOGIN
        @player = nil
        @tries = 0
        @scroll = 60 # unused?
        @name = nil
    end

    # Main input loop
    def input_loop
        send_output(Game.instance.game_settings[:login_splash])
        loop do
            case @client_state
            when Constants::ClientState::LOGIN
                do_login
            when Constants::ClientState::ACCOUNT
                do_account
            when Constants::ClientState::CREATION
                do_creation
            when Constants::ClientState::PLAYER
                do_player
            end
            if @tries > 2
                @quit = true
            end
            break if @quit
        end
        send_output("Goodbye.")
        disconnect

    end

    # Log into an account.
    # When successful, +@client_state+ will be set to +Constants::ClientState::ACCOUNT+,
    # and account management will commence.
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
        if "new".fuzzy_match(name) # new account
            name = nil
            while name.nil?
                send_output("Please choose your account name or \"back\" to cancel.")
                name = get_input
                if name.downcase == "back"
                    return
                elsif name != name.gsub(/[^0-9A-Za-z]/, '')
                    send_output("Illegal account name. Alphanumeric characters only, please.")
                    name = nil
                elsif Game.instance.account_data.select{ |id, row| row[:name] == name }.first
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
            while (account_row = Game.instance.account_data.values.select{ |row| row[:name] == name }.first).nil?
                sleep(@@sleep_time) # wait until the account exists in the database and has been loaded
            end
        else # try existing account
            send_output("Password:")
            password = get_input
            md5 = Digest::MD5.hexdigest(password)
            if (account_row = Game.instance.account_data.values.select{ |row| row[:name].downcase == name.downcase && row[:md5] == md5}.first).nil?
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
        @client_state = Constants::ClientState::ACCOUNT
        send_output("\nWelcome, #{@name}.\n")
        list_characters
    end

    # Account management
    def do_account(input = nil)
        send_output("{c<#{@name}>{x")
        if !input
            input = get_input
        end
        words = input.split(" ").to_a
        word1 = words.dig(0).to_s
        word2 = words.dig(1).to_s
        if word1 == ""
            send_output("What's that? Try \"help\" to see what you can do from here.")
            return
        end
        if "new".fuzzy_match(word1)
            @client_state = Constants::ClientState::CREATION
            return
        elsif "play".fuzzy_match(word1)
            if word2.length < 1
                send_output("Who did you want to play?")
                return
            end
            c_row = Game.instance.saved_player_data.values.select{ |row| row[:name].downcase == word2.downcase }.first
            if !c_row
                send_output("You don't have a character with that name.")
                return
            end
            send_output("Logging in as #{c_row[:name]}.")
            Game.instance.logging_players.push([c_row[:id], self])
            while (@player = Game.instance.players.select{ |p| p.id == c_row[:id] }.first).nil?
                sleep(@@sleep_time) # wait until the player has been loaded by the game thread
            end
            @player.login
            @client_state = Constants::ClientState::PLAYER
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
    end

    # create a new character
    def do_creation
        send_output("Type \"back\" at any point to abandon character creation.\n")
        name = nil
        @client_state = Constants::ClientState::ACCOUNT # the only way out of this is back to account management
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
            elsif Game.instance.saved_player_data.values.select{ |row| row[:name] == name }.first
                send_output("That name is already taken.")
                name = nil
            end
        end

        race_id = nil
        race_rows = Game.instance.race_data.values.select{ |row| row[:player_race] == 1 && row[:starter_race] == 1 }
        race_names = race_rows.map{ |row| row[:name] }
        send_output("The following races are available:\n" +
        "#{race_names.map{ |n| n.rpad(10) }.each_slice(5).to_a.map(&:join).join("\n\r")}\n")
        while race_id.nil?
            send_output("What is your race (help for more information)?")
            race_input = get_input
            if race_input.downcase == "back"
                return
            end
            race_row = race_rows.select{ |row| row[:name].fuzzy_match(race_input) }.first
            if race_row
                race_id = race_row[:id]
            elsif race_input.fuzzy_match("help")
                send_output("Placeholder race help - p2implement")
            else
                send_output("You must choose a valid race!")
            end
        end

        class_id = nil
        class_rows = Game.instance.class_data.values.select{ |row| row[:starter_class] == 1 }
        class_names = class_rows.map{ |row| row[:name] }
        send_output("Select a class:\n--------------\n" +
        "#{class_names.join("\n")}\n")
        while class_id.nil?
            send_output("What is your class (help for more information)?")
            class_input = get_input
            if class_input.downcase == "back"
                return
            end
            class_row = class_rows.select{ |row| row[:name].fuzzy_match(class_input) }.first
            if class_row
                class_id = class_row[:id]
            elsif class_input.fuzzy_match("help")
                send_output("Placeholder class help - p2implement")
            else
                send_output("You must choose a valid class!")
            end
        end

        alignment = nil
        while alignment.nil?
            send_output("You may be good, neutral, of evil.\nWhat is your alignment?")
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

        player_data = {
            account_id: @account_id,
            name: name,
            race_id: race_id,
            class_id: class_id,
            alignment: alignment,
            creation_points: 5
        }
        send_output("Creating #{name}...")
        Game.instance.new_players.push(player_data)
        while (Game.instance.saved_player_data.values.select{ |row| row[:name] == name }.first).nil?
            sleep(@@sleep_time)
        end
        list_characters
    end

    # play a character
    def do_player
        input = get_input
        if @player
            @player.input(input)
        else
            @client_state = Constants::ClientState::ACCOUNT
            list_characters
            do_account(input)
        end
    end

    # list characters for a given player account and give some instructions on how to proceed
    def list_characters
        c_rows = Game.instance.saved_player_data.values.select{ |row| row[:account_id] == @account_id.to_i }
        c_rows = c_rows.sort_by{ |row| row[:name] }
        lines = []
        c_rows.each do |c_row|
            level = c_row[:level]
            race_name = Game.instance.race_data.dig(c_row[:race_id], :display_name).to_s
            class_name = Game.instance.class_data.dig(c_row[:class_id], :name).to_s
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
    end

    # basic input/output

    # get a single input
    def get_input
        raw = nil
        begin
            raw = @client_connection.gets.chomp.to_s.sanitize
        rescue StandardError => msg
            log "Client #{@account_id} get_input: #{msg}"
            disconnect
        end
        if !raw
            disconnect
        end
        return raw
    end

    # do a single output
    def send_output(s)
        if s[-1] != "\n"
            s += "\n"
        end
        s = s.gsub(/\n/, "\n\r")
        begin
            @client_connection.print s.replace_color_codes
        rescue StandardError => msg
            log "Client #{@account_id} send_output: #{msg}"
            disconnect
        end
    end

    # handle an early disconnect (not an actual quit/exit)
    def disconnect
        Game.instance.client_account_ids.delete(@account_id)
        begin
            @client_connection.close
        rescue StandardError => msg
            log(msg)
        end
        @client_connection = nil
        log("Disconnected client with account_id #{@account_id}")
        begin
            Thread.kill(@thread)
        rescue
        end
        @thread = nil
    end

end
