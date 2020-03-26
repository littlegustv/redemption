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

        profile "{M", "MAKE SKILLS, SPELLS, COMMANDS" do
            make_skills
            make_spells
            make_commands
        end

        clear_tables

        profile "{G", "REPOP", true do

            # perform a repop to populate the world with items and mobiles
            10.times do
                repop
            end

        end

        @start_time = Time.now
        log( "Redemption is ready to rock on port #{port}!" )

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
        sql_host, sql_port, sql_username, sql_password = File.read( "server_config.txt" ).split("\n").map{ |line| line.split(" ")[1] }
        @db = Sequel.mysql2( :host => sql_host,
                             :port => sql_port,
                             :username => sql_username,
                             :password => sql_password,
                             :database => "redemption" )

        # @db.loggers << Logger.new($stdout)
        log( "Database connection established." )
    end

    # clear some rows that were valid on the last time the game was running but are now errant data
    protected def clean_database
        @db[:saved_player_affect].update(source_uuid: 0)
        @db[:saved_player_item_affect].update(source_uuid: 0)
        log ( "Database cleaned." )
    end

    # Load the game_settings table from the database and apply its values where necessary.
    protected def load_game_settings
        @game_settings = @db[:game_settings].all.first
        log ( "Database load complete: Game settings" )
    end

    # Load the race_base table
    protected def load_race_data
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
        log ( "Database load complete: Race data" )
    end

    # Load the class_base table
    protected def load_class_data
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
        log ( "Database load complete: Class data" )
    end

    # Load the equip_slot_base table
    protected def load_equip_slot_data
        @equip_slot_data = @db[:equip_slot_base].to_hash(:id)
        log ("Database load complete: Equip slot data")
    end

    # Load the continent_base table
    protected def load_continent_data
        @continent_data = @db[:continent_base].to_hash(:id)
        log ( "Database load complete: Continents" )
    end

    # Load the area_base table
    protected def load_area_data
        @area_data = @db[:area_base].to_hash(:id)
        log ( "Database load complete: Areas" )
    end

    # Load the room_base table
    protected def load_room_data
        @room_data = @db[:room_base].to_hash(:id)
        @exit_data = @db[:room_exit].to_hash(:id)
        @room_description_data = @db[:room_description].to_hash(:id)
        log ( "Database load complete: Rooms" )
    end

    # Load the mobile_base table
    protected def load_mobile_data
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
        log("Database load complete: Mobile data")
    end

    # Load the item tables from database and merge them together
    protected def load_item_data
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
        log("Database load complete: Item data")
    end

    # Load shop table from database
    protected def load_shop_data
        @shop_data = @db[:shop_base].to_hash(:mobile_id)
        log("Database load complete: Shop data")
    end

    protected def load_portal_data
        @portal_data = @db[:item_portal].to_hash(:item_id)
        log("Database load complete: Portal data")
    end

    protected def load_social_data
        @social_data = @db[:social_base].to_hash(:id)
        log("Database load complete: Social data")
    end

    protected def load_gender_data
        @gender_data = @db[:gender_base].to_hash(:id)
        if @gender_data.size == 0
            @gender_data[Constants::Gender::DEFAULT[:id]] = Constants::Gender::DEFAULT
        end
        log("Database load complete: Gender data")
    end

    # load reset tables from database
    protected def load_reset_data( areas )
        if areas == "lite"
            @base_reset_data = @db[:reset_base].where( area_id: [17, 23] ).to_hash(:id)
        else
            @base_reset_data = @db[:reset_base].to_hash(:id)
        end
        @mob_reset_data = @db[:reset_mobile].to_hash(:reset_id)
        @inventory_reset_data = @db[:reset_inventory_item].to_hash(:reset_id)
        @equipment_reset_data = @db[:reset_equipped_item].to_hash(:reset_id)
        @container_reset_data = @db[:reset_container_item].to_hash(:reset_id)
        @room_item_reset_data = @db[:reset_room_item].to_hash(:reset_id)
        @base_mob_reset_data = @base_reset_data.select{ |key, value| value[:type] == "mobile" }
        @base_room_item_reset_data = @base_reset_data.select{ |key, value| value[:type] == "room_item" }
        log("Database load complete: Resets")
    end

    # load helpfiles
    protected def load_help_data
        @help_data = @db[:help_base].to_hash(:id)
        @help_data.each { |id, help| help[:keywords] = help[:keywords].split(" ") }
        log ( "Database load complete: Helpfiles" )
    end

    # load account data = this will be continually updated
    protected def load_account_data
        @account_data = @db[:account_base].to_hash(:id)
        log ( "Database load complete: Account data" )
    end

    # load player data - this will be continually updated in the main thread
    protected def load_saved_player_data
        @saved_player_data = @db[:saved_player_base].to_hash(:id)
        log ( "Database load complete: Saved player data" )
    end

    # load skill data from database
    protected def load_skill_data
        @skill_data = @db[:skill_base].to_hash(:id)
        log ( "Database load complete: Skill data" )
    end

    # load spell data from database
    protected def load_spell_data
        @spell_data = @db[:spell_base].to_hash(:id)
        log ( "Database load complete: Spell data" )
    end

    # load command data from database
    protected def load_command_data
        @command_data = @db[:command_base].to_hash(:id)
        log ( "Database load complete: Command data" )
    end

    # load max ids for saved_player tables
    protected def load_max_ids
        @saved_player_id_max = @db[:saved_player_base].max(:id).to_i
        @saved_player_affect_id_max = @db[:saved_player_affect].max(:id).to_i
        @saved_player_item_id_max = @db[:saved_player_item].max(:id).to_i
        @saved_player_item_affect_id_max = @db[:saved_player_item_affect].max(:id).to_i
        log ( "Database load complete: Saved player id max values" )
    end

    # Construct Continent objects
    protected def make_continents
        @continent_data.each do |id, row|
            @continents[id] = Continent.new(row)
        end
        log("Continents constructed.")
    end

    # Construct Continent objects
    protected def make_areas
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
        log("Areas constructed.")
    end

    # Construct room objects
    protected def make_rooms
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
        log("Rooms constructed.")
    end

    # Construct Skill objects
    protected def make_skills
        Constants::SKILL_CLASSES.each do |skill_class|
            skill = skill_class.new
            row = @skill_data.values.select{ |row| row[:name] == skill.name }.first
            if row
                skill.overwrite_attributes(row)
            else
                log "{ySkill not found in database: \"#{skill.name}\" {x"
            end
            @skills.push skill
            @abilities[ skill.name ] = skill
        end
        log("Skills constructed.")
    end

    # Construct Spell objects
    protected def make_spells
        Constants::SPELL_CLASSES.each do |spell_class|
            spell = spell_class.new
            row = @spell_data.values.select{ |row| row[:name] == spell.name }.first
            if row
                spell.overwrite_attributes(row)
            else
                log "{ySpell not found in database: \"#{spell.name}\"{x"
            end
            @spells.push spell
            @abilities[ spell.name ] = spell
        end
        log("Spells constructed.")
    end

    # Construct Command objects
    protected def make_commands
        Constants::COMMAND_CLASSES. each do |command_class|
            command = command_class.new
            row = @command_data.values.select{ |row| row[:name] == command.name }.first
            if row
                command.overwrite_attributes(row)
            else
                log "{yCommand not found in database: \"#{command.name}\"{x"
            end
            @commands.push command
        end
        log("Commands constructed.")
    end

    # release unnecessary tables (already been populated, etc)
    protected def clear_tables
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
