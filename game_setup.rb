# This module contains methods relevant to Game's initial setup.
module GameSetup

    # The main setup method for game.
    #
    # Calling this method will (in order):
    # 1. Open the TCP Server for the game.
    # 2. Open a connection to the database.
    # 3. Cleans up database rows that were only relevant to the last instance of the game running
    # 4. Load database tables
    # 5. Load max ids for saved_player tables
    # 6. construct continents, areas, rooms
    # 7. construct skills, spells, commands
    # 8. perform game.repop
    # 9. set start_time to now
    # 10. start the game_loop thread
    # 11. begin a loop, creating threads for incoming clients
    # +ip+:: The IP address of the server. (Optional, can pass +nil+)
    # +port+:: The port the server uses.
    public def start(ip, port, areas = "all")
        if @started
            log("This game object has already been started!")
            return
        end
        @started = true

        # MemoryProfiler.start

        # start TCPServer
        start_server(ip, port)
        # Open database connection
        connect_database
        clean_database
        # load database tables
        load_game_settings
        load_race_data
        load_class_data
        load_equip_slot_data
        load_continent_data
        load_area_data

        profile "{c", "ROOM DATA" do

            load_room_data

        end

        profile "{c", "MOBILE DATA" do

            load_mobile_data

        end

        profile "{c", "ITEM (AND MISC) DATA" do

            load_item_data
            load_shop_data
            load_reset_data( areas )
            load_help_data
            load_account_data
            load_saved_player_data
            load_skill_data
            load_spell_data
            load_command_data
            load_portal_data
            load_social_data
            load_gender_data

            load_max_ids

        end

        profile "{M", "'MAKE CONTINENTS'" do

            # construct objects
            make_continents
            make_areas

        end

        profile "{M", "MAKE ROOMS" do

            make_rooms

        end

        profile "{M", "MAKE RESETS" do

            make_resets

        end

        profile "{M", "MAKE SKILLS, SPELLS, COMMANDS" do
            make_skills
            make_spells
            make_commands
        end

        clear_tables

        profile "{G", "HANDLE RESETS", true do

            # perform resets to populate the world with items and mobiles
            handle_resets(100000)

        end

        @start_time = Time.now
        log( "Redemption is ready to rock on port #{port}!" )
        log( "Starting initial resets." )

        # binding.pry

        # game update loop runs on a single thread
        Thread.start do
            game_loop
        end

        # each client runs on its own thread as well

        loop do
            thread = Thread.start(@server.accept) do |client_connection|
                client = Client.new(client_connection, thread)
                client.input_loop
            end
        end
    end

    # Opens the TCPServer at ip (optional) and port (required)
    protected def start_server(ip, port)
        if ip
            @server = TCPServer.open( ip, port )
        else
            @server = TCPServer.open( port )
        end
        log "Server opened on port #{port}."
    end

    # Open up the connection to the database.
    protected def connect_database
        log( "Connecting to database... ", false)
        sql_host, sql_port, sql_username, sql_password = File.read( "server_config.txt" ).split("\n").map{ |line| line.split(" ")[1] }
        @db = Sequel.mysql2( :host => sql_host,
                             :port => sql_port,
                             :username => sql_username,
                             :password => sql_password,
                             :database => "redemption" )

        # @db.loggers << Logger.new($stdout)
        log( "done." )
    end

    # clear some rows that were valid on the last time the game was running but are now errant data
    protected def clean_database
        log( "Cleaning database... ", false)
        @db[:saved_player_affect].update(source_uuid: 0)
        @db[:saved_player_item_affect].update(source_uuid: 0)
        log( "done." )
    end

    # Load the game_settings table from the database and apply its values where necessary.
    protected def load_game_settings
        log("Database load: Game settings... ", false)
        @game_settings = @db[:game_settings].all.first
        log( "done." )
    end

    # Load the race_base table
    protected def load_race_data
        log("Database load: Race data... ", false)
        @race_data = @db[:race_base].to_hash(:id)
        @race_data.each do |key, value|
            value[:skills] = value[:skills].split(",")
            value[:spells] = value[:spells].split(",")
            value[:weapons] = value[:weapons].to_s.split(",")
            value[:affect_flags] = value[:affect_flags].split(",")
            value[:immune_flags] = value[:immune_flags].split(",")
            value[:resist_flags] = value[:resist_flags].split(",")
            value[:vuln_flags] = value[:vuln_flags].split(",")
            value[:part_flags] = value[:part_flags].split(",")
            value[:form_flags] = value[:form_flags].split(",")
            value[:equip_slots] = value[:equip_slots].split(",")
            value[:h2h_flags] = value[:h2h_flags].split(",")
        end
        log( "done." )
    end

    # Load the class_base table
    protected def load_class_data
        log("Database load: Class data... ", false)
        @class_data = @db[:class_base].to_hash(:id)
        @class_data.each do |key, value|
            value[:skills] = value[:skills].to_s.split(",")
            value[:spells] = value[:spells].to_s.split(",")
            value[:weapons] = value[:weapons].to_s.split(",")
            value[:affect_flags] = value[:affect_flags].to_s.split(",")
            value[:immune_flags] = value[:immune_flags].to_s.split(",")
            value[:resist_flags] = value[:resist_flags].to_s.split(",")
            value[:vuln_flags] = value[:vuln_flags].to_s.split(",")
            value[:equip_slots] = value[:equip_slots].to_s.split(",")
        end
        log( "done." )
    end

    # Load the equip_slot_base table
    protected def load_equip_slot_data
        log("Database load: Equip slot data... ", false)
        @equip_slot_data = @db[:equip_slot_base].to_hash(:id)
        log( "done." )
    end

    # Load the continent_base table
    protected def load_continent_data
        log("Database load: Continent data... ", false)
        @continent_data = @db[:continent_base].to_hash(:id)
        log( "done." )
    end

    # Load the area_base table
    protected def load_area_data
        log("Database load: Area data... ", false)
        @area_data = @db[:area_base].to_hash(:id)
        log( "done." )
    end

    # Load the room_base table
    protected def load_room_data
        log("Database load: Room data... ", false)
        @room_data = @db[:room_base].to_hash(:id)
        @exit_data = @db[:room_exit].to_hash(:id)
        @room_description_data = @db[:room_description].to_hash(:id)
        log( "done." )
    end

    # Load the mobile_base table
    protected def load_mobile_data
        log("Database load: Mobile data... ", false)
        @mob_data = @db[:mobile_base].to_hash(:id)
        @mob_data.each do |id, row|
            row[:keywords] = row[:keywords].split(" ")
            row[:affect_flags] = row[:affect_flags].split(",")
            row[:off_flags] = row[:off_flags].split(",")
            row[:act_flags] = row[:act_flags].split(",")
            row[:immune_flags] = row[:immune_flags].split(",")
            row[:resist_flags] = row[:resist_flags].split(",")
            row[:vuln_flags] = row[:vuln_flags].split(",")
            row[:part_flags] = row[:part_flags].split(",")
            row[:form_flags] = row[:form_flags].split(",")
            row[:hand_to_hand_noun] = "pound" if row[:hand_to_hand_noun] == "none"
        end
        log( "done." )
    end

    # Load the item tables from database and merge them together
    protected def load_item_data
        log("Database load: Item data... ", false)
        @item_data = @db[:item_base].to_hash(:id)
        @item_modifiers = @db[:item_modifier].to_hash_groups(:item_id)
        @ac_data = @db[:item_armor].to_hash(:item_id)
        @weapon_data = @db[:item_weapon].to_hash(:item_id)
        @item_spells = @db[:item_spell].to_hash_groups(:item_id)

        @weapon_data.each do |id, row|
            row[:flags] = row[:flags].to_s.split(",")
        end
        @container_data = @db[:item_container].to_hash(:item_id)
        @item_data.each do |id, row|
            row[:keywords] = row[:keywords].split(" ")
            row[:extra_flags] = row[:extra_flags].to_s.split(",")
            row[:wear_flags] = row[:wear_flags].split(",")
            row[:modifiers] = Hash.new
            @item_modifiers[ id ].to_a.each do |modifier|
                row[:modifiers][ modifier[:field].to_sym ] = modifier[:value]
            end
            row[:modifiers].merge(@ac_data[ id ].to_h.reject{ |k, v| [:id, :item_id].include?(k) })
            if row[:type] == "weapon"
                row.merge!( @weapon_data[ id ].reject!{ |k, v| k == :id } )
            elsif row[:type] == "container"
                row.merge!(@container_data[ id ])
            end
        end
        log( "done." )
    end

    # Load shop table from database
    protected def load_shop_data
        log("Database load: Shop data... ", false)
        @shop_data = @db[:shop_base].to_hash(:mobile_id)
        log( "done." )
    end

    protected def load_portal_data
        log("Database load: Portal data... ", false)
        @portal_data = @db[:item_portal].to_hash(:item_id)
        log( "done." )
    end

    protected def load_social_data
        log("Database load: Social data... ", false)
        @social_data = @db[:social_base].to_hash(:id)
        log( "done." )
    end

    protected def load_gender_data
        log("Database load: Gender data... ", false)
        @gender_data = @db[:gender_base].to_hash(:id)
        if @gender_data.size == 0
            @gender_data[Constants::Gender::DEFAULT[:id]] = Constants::Gender::DEFAULT
        end
        log( "done." )
    end

    # load reset tables from database
    protected def load_reset_data( areas )
        log("Database load: Reset data... ", false)
        @reset_mobile_data = @db[:new_reset_mobile].to_hash(:id)
        log( "done." )
    end

    # load helpfiles
    protected def load_help_data
        log("Database load: Helpfile data... ", false)
        @help_data = @db[:help_base].to_hash(:id)
        @help_data.each { |id, help| help[:keywords] = help[:keywords].split(" ") }
        log( "done." )
    end

    # load account data = this will be continually updated
    protected def load_account_data
        log("Database load: Account data... ", false)
        @account_data = @db[:account_base].to_hash(:id)
        log( "done." )
    end

    # load player data - this will be continually updated in the main thread
    protected def load_saved_player_data
        log("Database load: Player data... ", false)
        @saved_player_data = @db[:saved_player_base].to_hash(:id)
        log( "done." )
    end

    # load skill data from database
    protected def load_skill_data
        log("Database load: Skill data... ", false)
        @skill_data = @db[:skill_base].to_hash(:id)
        log( "done." )
    end

    # load spell data from database
    protected def load_spell_data
        log("Database load: Spell data... ", false)
        @spell_data = @db[:spell_base].to_hash(:id)
        log( "done." )
    end

    # load command data from database
    protected def load_command_data
        log("Database load: Command data... ", false)
        @command_data = @db[:command_base].to_hash(:id)
        log( "done." )
    end

    # load max ids for saved_player tables
    protected def load_max_ids
        log("Database load: Player id max values... ", false)
        @saved_player_id_max = @db[:saved_player_base].max(:id).to_i
        @saved_player_affect_id_max = @db[:saved_player_affect].max(:id).to_i
        @saved_player_item_id_max = @db[:saved_player_item].max(:id).to_i
        @saved_player_item_affect_id_max = @db[:saved_player_item_affect].max(:id).to_i
        log( "done." )
    end

    # Construct Continent objects
    protected def make_continents
        log("Building continents... ", false)
        @continent_data.each do |id, row|
            @continents[id] = Continent.new(row)
        end
        log( "done." )
    end

    # Construct Continent objects
    protected def make_areas
        log("Building areas... ", false)
        @area_data.each do |id, row|
            @areas[id] = Area.new(
                {
                    id: row[:id],
                    name: row[:name],
                    continent: @continents[row[:continent_id]],
                    age: row[:age],
                    builders: row[:builders],
                    credits: row[:credits],
                    questable: row[:questable],
                    gateable: row[:gateable],
                    security: row[:security],
                    control: row[:control]
                }
            )
        end
        log( "done." )
    end

    # Construct room objects
    protected def make_rooms
        log("Building rooms... ", false)
        exit_inverse_list = {}
        @room_data.each do |id, row|
            @rooms[id] = Room.new(
                row[:id],
                row[:name],
                row[:description],
                row[:sector],
                @areas[row[:area_id]],
                row[:flags].split(" "),
                row[:hp_regen].to_i,
                row[:mana_regen].to_i
            )
            area = @areas[row[:area_id]]
            area.rooms << @rooms[row[:id]] if area
        end
        # assign each exit to its room in the hash (if the destination exists)
        @exit_data.each do |id, row|
            if @rooms[row[:room_id]] && @rooms[row[:to_room_id]]
                exit = Exit.new(    row[:direction],
                                    @rooms[row[:room_id]],
                                    @rooms[row[:to_room_id]],
                                    row[:flags].split(" "),
                                    row[:key_id],
                                    row[:keywords].split + [ row[:direction] ], # i.e. [oak,door,north]
                                    row[:description] )
                @rooms[row[:room_id]].exits[row[:direction].to_sym] = exit

                # adds the exit to this list with the key :inverse-direction_room-origin-id
                #
                # this is the direction/room pair that the exit on the "other side" will have
                #
                # all of this is so that exits have 'paired' actions - a door is opened or closed at both ends

                exit_inverse_list[ "#{Constants::Directions::INVERSE[ row[:direction].to_sym ]}_#{row[:room_id]}".to_sym ] = exit
                if (pair = exit_inverse_list[ "#{row[:direction]}_#{row[:to_room_id]}".to_sym ])
                    exit.add_pair( pair )
                end
            end
        end
        @starting_room = @rooms[@db[:continent_base].to_hash(:id)[2][:starting_room_id]]
        log( "done." )
    end

    # Construct Reset objects
    protected def make_resets
        log("Building resets... ", false)
        @reset_mobile_data.values.each do |row|
            row[:quantity].times do
                reset = ResetMobile.new( row[:room_id], row[:mobile_id], row[:timer], row[:chance])
                @mobile_resets << reset
                reset.activate(true)
            end
        end
        log( "done." )
    end

    # Construct Skill objects
    protected def make_skills
        log("Building skills... ", false)
        missing = []
        Constants::SKILL_CLASSES.each do |skill_class|
            skill = skill_class.new
            row = @skill_data.values.find{ |row| row[:name] == skill.name }
            if row
                skill.overwrite_attributes(row)
            else
                missing << skill.name
            end
            @skills.push skill
            @abilities[ skill.name ] = skill
        end
        log( "done." )
        if missing.size > 0
            log "Skills not found in database: {y\"#{missing.join("\n\r#{" " * 51}")}\" {x"
        end
    end

    # Construct Spell objects
    protected def make_spells
        log("Building spells... ", false)
        missing = []
        Constants::SPELL_CLASSES.each do |spell_class|
            spell = spell_class.new
            row = @spell_data.values.find{ |row| row[:name] == spell.name }
            if row
                spell.overwrite_attributes(row)
            else
                missing << spell.name
            end
            @spells.push spell
            @abilities[ spell.name ] = spell
        end
        log( "done." )
        if missing.size > 0
            log "Spells not found in database: {y#{missing.join("\n\r#{" " * 51}")}{x"
        end
    end

    # Construct Command objects
    protected def make_commands
        log("Building commands... ", false)
        missing = []
        Constants::COMMAND_CLASSES. each do |command_class|
            command = command_class.new
            row = @command_data.values.find{ |row| row[:name] == command.name }
            if row
                command.overwrite_attributes(row)
            else
                missing << command.name
            end
            @commands.push command
        end
        log( "done." )
        if missing.size > 0
            log "Commands not found in database: {y#{missing.join("\n\r#{" " * 53}")}{x"
        end
    end

    # release unnecessary tables (already been populated, etc)
    protected def clear_tables
        @new_reset_mobile_data = nil
        @continent_data = nil
        @area_data = nil
        @room_data = nil
        @exit_data = nil
        @room_description_data = nil
        @item_modifiers = nil
        @ac_data = nil
        @weapon_data = nil
        @container_data = nil
    end
end
