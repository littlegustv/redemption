# This module contains methods relevant to Game's initial setup.
module GameSetup

    # The main setup method for game.
    #
    # Calling this method will (in order):
    # 1. Open the TCP Server for the game.
    # 2. Open a connection to the database.
    # 3. Load database tables
    # 4. construct continents, areas, rooms
    # 5. construct skills, spells, commands
    # 6. perform a game.repop
    # 7. set start_time to now
    # 8. start the game_loop thread
    # 9. begin a loop, creating threads for incoming clients
    # +ip+:: The IP address of the server. (Optional, can pass +nil+)
    # +port+:: The port the server uses.
    public def start(ip, port)
        if @started
            log("This game object has already been started!")
            return
        end
        @started = true

        # start TCPServer
        start_server(ip, port)
        # Open database connection
        connect_database

        # load database tables
        load_game_settings
        load_race_data
        load_class_data
        load_equip_slot_data
        load_continent_data
        load_area_data
        load_room_data
        load_mobile_data
        load_item_data
        load_shop_data
        load_reset_data
        load_help_data

        # construct objects
        make_continents
        make_areas
        make_rooms
        make_skills
        make_spells
        make_commands

        # perform a repop to populate the world with items and mobiles
        repop

        @start_time = Time.now
        log( "Redemption is ready to rock on port #{port}!" )

        # game update loop runs on a single thread
        Thread.start do
            game_loop
        end

        # each client runs on its own thread as well
        loop do
            thread = Thread.start(@server.accept) do |client|
                login client, thread
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
        log( "Database connection established." )
    end

    # Load the game_settings table from the database and apply its values where necessary.
    protected def load_game_settings
        @game_settings = @db[:game_settings].all.first
        @next_uuid = [1, @game_settings[:next_uuid].to_i].max
        log ( "Database load complete: Game settings" )
    end

    # Load the race_base table
    protected def load_race_data
        @race_data = @db[:race_base].to_hash(:id)
        @race_data.each do |key, value|
            value[:skills] = value[:skills].split(",")
            value[:spells] = value[:spells].split(",")
            value[:affect_flags] = value[:affect_flags].split(",")
            value[:immune_flags] = value[:immune_flags].split(",")
            value[:resist_flags] = value[:resist_flags].split(",")
            value[:vuln_flags] = value[:vuln_flags].split(",")
            value[:part_flags] = value[:part_flags].split(",")
            value[:form_flags] = value[:form_flags].split(",")
            value[:equip_slots] = value[:equip_slots].split(",")
        end
        log ( "Database load complete: Race data" )
    end

    # Load the class_base table
    protected def load_class_data
        @class_data = @db[:class_base].to_hash(:id)
        @class_data.each do |key, value|
            value[:skills] = value[:skills].to_s.split(",")
            value[:spells] = value[:spells].to_s.split(",")
            value[:affect_flags] = value[:affect_flags].to_s.split(",")
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
            row[:affect_flags] = row[:affect_flags].split(",")
            row[:off_flags] = row[:off_flags].split(",")
            row[:act_flags] = row[:act_flags].split(",")
            row[:immune_flags] = row[:immune_flags].split(",")
            row[:resist_flags] = row[:resist_flags].split(",")
            row[:vuln_flags] = row[:vuln_flags].split(",")
            row[:part_flags] = row[:part_flags].split(",")
            row[:form_flags] = row[:form_flags].split(",")
        end
        log("Database load complete: Mobile data")
    end

    # Load the item tables from database
    protected def load_item_data
        @item_data = @db[:item_base].to_hash(:id)
        @item_modifiers = @db[:item_modifier].to_hash_groups(:item_id)
        @ac_data = @db[:item_armor].to_hash(:item_id)
        @weapon_data = @db[:item_weapon].to_hash(:item_id)
        log("Database load complete: Item data")
    end

    # Load shop table from database
    protected def load_shop_data
        @shop_data = @db[:shop_base].to_hash(:mobile_id)
        log("Database load complete: Shop data")
    end

    # load reset tables from database
    protected def load_reset_data
        # @base_resets = @db[:reset_base].where( area_id: [17, 23] ).to_hash(:id)
        @base_resets = @db[:reset_base].to_hash(:id)
        @mob_resets = @db[:reset_mobile].to_hash(:reset_id)
        @inventory_resets = @db[:reset_inventory_item].to_hash(:reset_id)
        @equipment_resets = @db[:reset_equipped_item].to_hash(:reset_id)
        @room_item_resets = @db[:reset_room_item].to_hash(:reset_id)
        @base_mob_resets = @base_resets.select{ |key, value| value[:type] == "mobile" }
        @base_room_item_resets = @base_resets.select{ |key, value| value[:type] == "room_item" }
        log("Database load complete: Resets")
    end

    # load helpfiles
    protected def load_help_data
        @help_data = @db[:help_base].to_hash(:id)
        @help_data.each { |id, help| help[:keywords] = help[:keywords].split(" ") }
        log ( "Database load complete: Helpfiles" )
    end

    # Construct Continent objects
    protected def make_continents
        @continent_data.each do |id, row|
            @continents[id] = Continent.new(row, self)
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
                },
                self
            )
        end
        log("Areas constructed.")
    end

    # Construct room objects
    protected def make_rooms
        @room_data.each do |id, row|
            @rooms[id] = Room.new(
                row[:id],
                row[:name],
                row[:description],
                row[:sector],
                @areas[row[:area_id]],
                row[:flags].to_s.split(" "),
                row[:hp_regen].to_i,
                row[:mana_regen].to_i,
                self
            )
            area = @areas[row[:area_id]]
            area.rooms << @rooms[row[:id]] if area
        end
        # assign each exit to its room in the hash (if the destination exists)
        @exit_data.each do |id, row|
            if @rooms[row[:room_id]] && @rooms[row[:to_room_id]]
                @rooms[row[:room_id]].exits[row[:direction].to_sym] = @rooms[row[:to_room_id]]
            end
        end
        @starting_room = @rooms[@db[:continent_base].to_hash(:id)[2][:starting_room_id]]
        log("Rooms constructed.")
    end

    # Construct Skill objects
    protected def make_skills
        Constants::SKILL_CLASSES.each do |skill_class|
            @skills.push skill_class.new(self)
        end
        log("Skills constructed.")
    end

    # Construct Spell objects
    protected def make_spells
        Constants::SPELL_CLASSES.each do |spell_class|
            @spells.push spell_class.new(self)
        end
        log("Spells constructed.")
    end

    # Construct Command objects
    protected def make_commands
        Constants::COMMAND_CLASSES. each do |command_class|
            @commands.push command_class.new(self)
        end
        log("Commands constructed.")
    end
end