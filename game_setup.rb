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
    public def start(ip, port)
        if @started
            log("This game object has already been started!")
            return
        end
        @started = true

        # MemoryProfiler.start

        # start TCPServer
        start_server(ip, port)
        # Open database connection
        reload

        log( "Redemption is ready to rock on port #{port}!" )
        log( "Starting initial resets." )

        # binding.pry

        # game update loop runs on a single thread
        game_loop_thread = Thread.start do
            game_loop
        end

        # each client runs on its own thread as well
        @client_accept_thread = Thread.start do
            loop do
                client_thread = Thread.start(@server.accept) do |client_connection|
                    client = Client.new(client_connection, client_thread)
                    @clients << client
                    client.input_loop
                end
            end
        end
        @server_input_thread = Thread.start do
            server_input_loop
        end

        game_loop_thread.join
        log "Server shutdown complete."
    end

    protected def reload

        @clients.each do |client|
            client.paused = true
        end

        @players.dup.each do |player|
            @logging_players << [player.id, player.client]
            client = player.client
            client.paused = true
            # client.player = nil
            player.destroy
            # player.quit(true)
        end
        @players.clear
        @initial_reset = true

        @game_settings = {}
        @item_model_classes = {}
        @affect_class_hash = {}
        @commands = []
        @server_commands = []
        @skills = []
        @spells = []
        @abilities = {}
        @elements = {}
        @equip_slot_infos = {}
        @genders = {}
        @genres = {}
        @materials = {}
        @mobile_classes = {}
        @nouns = {}
        @positions = {}
        @races = {}
        @sectors = {}
        @sizes = {}
        @stats = {}
        @wear_locations = {}

        @inactive_player_source_affects = {}
        @mobile_models = {}
        @item_models = {}
        @help_data = {}

        @combat_mobs = Set.new
        @regen_mobs = Set.new

        @new_periodic_affects.clear
        @timed_affects.clear
        @periodic_affects.clear
        @responders.clear

        @mobile_keyword_map.clear
        @item_keyword_map.clear


        mobiles = @mobiles.dup
        @mobiles.clear
        mobiles.each do |mobile|
            mobile.destroy
        end
        items = @items.dup
        @items.clear
        items.each do |item|
            item.destroy
        end
        @continents.values.each do |continent|
            continent.destroy
        end
        @areas.values.each do |area|
            area.destroy
        end
        @rooms.values.each do |room|
            room.destroy
        end
        @active_resets = []
        @item_resets = []
        @mobile_resets = []

        @inactive_player_source_affects.clear

        connect_database
        clean_database
        # load database tables
        load_game_settings
        load_item_types
        load_affects

        load_help_data
        load_social_data

        load_stats
        load_elements
        load_positions
        load_commands
        load_server_commands
        load_abilities
        load_wear_locations
        load_equip_slots
        load_genders
        load_genres
        load_materials
        load_mobile_classes
        load_nouns
        load_races
        load_sectors
        load_sizes


        load_continents
        load_areas

        load_rooms

        load_mobiles

        load_item_data
        load_shop_data
        load_reset_data
        load_account_data
        load_saved_player_data
        load_portal_data

        load_max_ids

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
        log( "Connecting to database... ", false, 70)
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
        log( "Cleaning database... ", false, 70)
        @db[:saved_player_affect].update(source_uuid: 0)
        @db[:saved_player_item_affect].update(source_uuid: 0)
        log( "done." )
    end

    # Load the game_settings table from the database and apply its values where necessary.
    protected def load_game_settings
        log("Loading game settings... ", false, 70)
        @game_settings = @db[:game_settings].all.first
        log( "done." )
    end

    protected def load_item_types
        log("Loading Item Type tables... ", false, 70)
        item_type_rows = @db[:item_type_base].to_hash(:id)

        item_type_rows.each do |id, row|
            model_class = Constants::ITEM_MODEL_CLASSES.find{ |model_class| model_class.item_class_name == row[:name] }
            if !model_class
                model_class = ItemModel
            end
            @item_model_classes[id] = model_class
        end
        log("done")
    end

    # Load the affect_base table and link its ids to affect classes
    protected def load_affects
        log("Loading Affect tables... ", false, 70)
        affect_data = @db[:affect_base].all

        Constants::AFFECT_CLASSES.each do |aff_class|
            row = affect_data.find { |row| row[:name] == aff_class.affect_info[:name] }
            if row
                id = row[:id]
                aff_class.set_id(id)
                aff_class.set_data(JSON.parse(row[:data], symbolize_names: true)) if row.dig(:data)
                @affect_class_hash[id] = aff_class
            end
        end
        log("done.")
        # log list of affects that didn't get an id set
        missing = Constants::AFFECT_CLASSES.select { |aff_class| aff_class.id == nil }.map { |aff_class| aff_class.affect_info[:name] }
        if missing.size > 0
            log "Affects not found in database: {y#{missing.join("\n\r#{" " * 52}")}{x"
        end
    end

    # load command data from database
    protected def load_commands
        log("Loading Command tables... ", false, 70)
        command_data = @db[:command_base].to_hash(:id)

        # Construct Command objects
        missing = []
        Constants::COMMAND_CLASSES.each do |command_class|
            command = command_class.new
            row = command_data.values.find{ |row| row[:name] == command.name }
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

    protected def load_server_commands
        log("Loading Server Commands...", false, 70)

        Constants::SERVER_COMMAND_CLASSES.each do |command_class|
            command = command_class.new
            @server_commands.push command
        end
        log("done")
    end

    # load skill data from database
    protected def load_abilities
        log("Loading Ability tables... ", false, 70)
        ability_data = @db[:ability_base].to_hash(:id)

        missing = []
        Constants::SKILL_CLASSES.each do |skill_class|
            skill = skill_class.new
            row = ability_data.values.find{ |row| row[:name] == skill.name }
            if row
                skill.overwrite_attributes(row)
            else
                missing << skill.name
            end
            @skills.push skill
            @abilities[ skill.id ] = skill
        end
        Constants::SPELL_CLASSES.each do |spell_class|
            spell = spell_class.new
            row = ability_data.values.find{ |row| row[:name] == spell.name }
            if row
                spell.overwrite_attributes(row)
            else
                missing << spell.name
            end
            @spells.push spell
            @abilities[ spell.id ] = spell
        end
        log( "done." )
        if missing.size > 0
            log "Abilities not found in database: {y#{missing.join("\n\r#{" " * 51}")}{x"
        end
    end

    protected def load_elements
        log("Loading Element tables... ", false, 70)
        element_data = @db[:element_base].to_hash(:id)

        element_data.each do |id, row|
            @elements[id] = Element.new(row)
        end
        log ("done.")
    end

    # Load the equip_slot_base table
    protected def load_equip_slots
        log("Loading Equip slot tables... ", false, 70)
        equip_slot_rows = @db[:equip_slot_base].all
        equip_slot_wear_loc_rows = @db[:equip_slot_wear_location].all

        # make EquipSlotInfo objects
        equip_slot_rows.each do |eq_slot_row|
            eq_slot_id = eq_slot_row[:id]
            @equip_slot_infos[eq_slot_id] = EquipSlotInfo.new(eq_slot_row)
        end
        # add WearLocations
        equip_slot_wear_loc_rows.each do |wear_loc_row|
            wear_loc = @wear_locations[wear_loc_row[:wear_location_id]]
            if wear_loc
                @equip_slot_infos[wear_loc_row[:equip_slot_id]].wear_locations << wear_loc
            end
        end
        log("done.")
    end

    protected def load_genres
        log("Loading Genre tables... ", false, 70)
        genre_data = @db[:genre_base].to_hash(:id)
        genre_affect_data = @db[:genre_affect].all

        genre_data.each do |id, row|
            @genres[id] = Genre.new(row)
        end
        genre_affect_data.each do |aff_row|
            @genres[aff_row[:genre_id]].affect_models << AffectModel.new(aff_row)
        end
        log ("done.")
    end

    protected def load_genders
        log("Loading Gender tables... ", false, 70)
        gender_data = @db[:gender_base].to_hash(:id)

        gender_data.each do |id, row|
            @genders[id] = Gender.new(row)
        end
        if @genders.size == 0
            @genders[Constants::Gender::DEFAULT[:id]] = Gender.new(Constants::Gender::DEFAULT)
        end
        log ("done.")
    end

    protected def load_materials
        log("Loading Material tables... ", false, 70)
        material_data = @db[:material_base].to_hash(:id)

        material_data.each do |id, row|
            @materials[id] = Material.new(row)
        end
        log ("done.")
    end

    # Load the class_base table
    protected def load_mobile_classes
        log("Loading Class tables... ", false, 70)

        class_rows = @db[:class_base].to_hash(:id)
        affect_rows = @db[:class_affect].all
        genre_rows = @db[:class_genre].all
        equip_slot_rows = @db[:class_equip_slot].all
        skill_rows = @db[:class_skill].all
        spell_rows = @db[:class_spell].all
        stat_rows = @db[:class_stat].all

        class_rows.each do |id, row|
            @mobile_classes[id] = MobileClass.new(row)
        end
        genre_rows.each do |genre_row|
            genre = @genres[genre_row[:genre_id]]
            if genre
                @mobile_classes[genre_row[:class_id]].genres << genre
            end
        end
        equip_slot_rows.each do |eq_slot_row|
            eq_slot_info = @equip_slot_infos[eq_slot_row[:equip_slot_id]]
            if eq_slot_info
                @mobile_classes[eq_slot_row[:class_id]].equip_slot_infos << eq_slot_info
            end
        end
        affect_rows.each do |aff_row|
            @mobile_classes[aff_row[:class_id]].affect_models << AffectModel.new(aff_row)
        end
        skill_rows.each do |skill_row|
            skill = @skills.find { |skill| skill.id == skill_row[:skill_id] }
            if skill
                @mobile_classes[skill_row[:class_id]].skills << skill
            end
        end
        spell_rows.each do |spell_row|
            spell = @spells.find { |spell| spell.id == spell_row[:spell_id] }
            if spell
                @mobile_classes[spell_row[:class_id]].spells << spell
            end
        end
        stat_rows.each do |stat_row|
            stat = @stats[stat_row[:stat_id]]
            if stat
                @mobile_classes[stat_row[:class_id]].add_stat(stat, stat_row[:value])
            end
        end
        log( "done." )
    end

    protected def load_nouns
        log("Loading Noun tables... ", false, 70)
        noun_data = @db[:noun_base].to_hash(:id)

        noun_data.each do |id, row|
            @nouns[id] = Noun.new(row)
        end
        log ("done.")
    end

    protected def load_positions
        log("Loading Position tables... ", false, 70)
        position_data = @db[:position_base].to_hash(:id)

        position_data.each do |id, row|
            @positions[id] = Position.new(row)
        end
        log ("done.")
    end

    # Load the race_base table
    protected def load_races
        log("Loading Race tables... ", false, 70)
        race_rows = @db[:race_base].to_hash(:id)
        affect_rows = @db[:race_affect].all
        genre_rows = @db[:race_genre].all
        equip_slot_rows = @db[:race_equip_slot].all
        h2h_affect_rows = @db[:race_hand_to_hand_affect].all
        skill_rows = @db[:race_skill].all
        spell_rows = @db[:race_spell].all
        stat_rows = @db[:race_stat].all

        # Make Race objects
        race_rows.each do |id, race_row|
            @races[id] = Race.new(race_row)
        end
        genre_rows.each do |genre_row|
            genre = @genres[genre_row[:genre_id]]
            if genre
                @races[genre_row[:race_id]].genres << genre
            end
        end
        equip_slot_rows.each do |eq_slot_row|
            eq_slot_info = @equip_slot_infos[eq_slot_row[:equip_slot_id]]
            if eq_slot_info
                @races[eq_slot_row[:race_id]].equip_slot_infos << eq_slot_info
            end
        end
        affect_rows.each do |aff_row|
            @races[aff_row[:race_id]].affect_models << AffectModel.new(aff_row)
        end
        h2h_affect_rows.each do |aff_row|
            @races[aff_row[:race_id]].hand_to_hand_affect_models << AffectModel.new(aff_row)
        end
        skill_rows.each do |skill_row|
            skill = @skills.find { |skill| skill.id == skill_row[:skill_id] }
            if skill
                @races[skill_row[:race_id]].skills << skill
            end
        end
        spell_rows.each do |spell_row|
            spell = @spells.find { |spell| spell.id == spell_row[:spell_id] }
            if spell
                @races[spell_row[:race_id]].spells << spell
            end
        end
        stat_rows.each do |stat_row|
            stat = @stats[stat_row[:stat_id]]
            if stat
                @races[stat_row[:race_id]].add_stat(stat, stat_row[:value])
            end
        end
        log( "done." )
    end

    protected def load_sectors
        log("Loading Sector tables... ", false, 70)
        sector_data = @db[:sector_base].to_hash(:id)

        sector_data.each do |id, row|
            @sectors[id] = Sector.new(row)
        end
        log ("done.")
    end

    protected def load_sizes
        log("Loading Size tables... ", false, 70)
        size_data = @db[:size_base].to_hash(:id)

        size_data.each do |id, row|
            @sizes[id] = Size.new(row)
        end
        log ("done.")
    end

    protected def load_stats
        log("Loading Stat tables... ", false, 70)
        stat_data = @db[:stat_base].to_hash(:id)

        stat_data.each do |id, row|
            @stats[id] = Stat.new(row)
        end
        stat_data.each do |id, row|
            if row.dig(:max_stat_id)
                @stats[id].set_max_stat(@stats[row[:max_stat_id]])
            end
        end
        log ("done.")
    end

    protected def load_wear_locations
        log("Loading Wear location tables... ", false, 70)
        wear_loc_rows = @db[:wear_location_base].to_hash(:id)

        wear_loc_rows.each do |id, row|
            @wear_locations[id] = WearLocation.new(row)
        end
        log("done.")
    end

    # Load the continent_base table
    protected def load_continents
        log("Loading Continent tables... ", false, 70)

        continent_data = @db[:continent_base].to_hash(:id)

        continent_data.each do |id, row|
            @continents[id] = Continent.new(
                row[:id],
                row[:name],
                row[:preposition],
                row[:recall_room_id],
                row[:starting_room_id]
            )
        end
        log( "done." )
    end

    # Load the area_base table
    protected def load_areas
        log("Loading Area tables... ", false, 70)
        area_data = @db[:area_base].to_hash(:id)

        area_data.each do |id, row|
            @areas[id] = Area.new(row[:id], row[:name], row[:age], @continents[row[:continent_id]], row[:credits], row[:gateable], row[:questable], row[:security])
        end
        log( "done." )
    end

    # Load the room_base table
    protected def load_rooms
        log("Loading Room tables... ", false, 70)
        room_data = @db[:room_base].to_hash(:id)
        exit_data = @db[:room_exit].all
        room_affect_data = @db[:room_affect].all
        room_description_data = @db[:room_description].all
        room_affect_data.each do |row|
            if row[:data]
                row[:data] = JSON.parse(row[:data], symbolize_names: true)
            end
        end

        exit_inverse_list = {}
        room_data.each do |id, row|
            area = @areas[row[:area_id]]
            @rooms[id] = Room.new(
                row[:id],
                row[:name],
                row[:short_description],
                @sectors[row[:sector_id]],
                @areas[row[:area_id]],
                row[:hp_regen],
                row[:mana_regen]
            )
            area.rooms << @rooms[id] if area
        end
        # assign each exit to its room in the hash (if the destination exists)
        exit_data.each do |row|
            if @rooms[row[:room_id]] && @rooms[row[:to_room_id]]
                exit = Exit.new(    row[:direction],
                                    @rooms[row[:room_id]],
                                    @rooms[row[:to_room_id]],
                                    row[:flags].split(" "),
                                    row[:key_id],
                                    row[:keywords].split + [ row[:direction] ], # i.e. [oak,door,north]
                                    row[:short_description] )
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
        room_affect_data.each do |row|
            room = @rooms.dig(row[:room_id])
            if room
                room.apply_affect_with_id(row[:affect_id], true)
            else
                log "Invalid room_affect row #{row}"
            end
        end
        @starting_room = @rooms[@game_settings[:starting_room_id]]
        log( "done." )
    end

    # Load the mobile_base table
    protected def load_mobiles
        log("Loading Mobile tables... ", false, 70)
        mob_rows = @db[:mobile_base].to_hash(:id)
        mob_affect_rows = @db[:mobile_affect].to_hash_groups(:mobile_id)
        mob_gender_rows = @db[:mobile_gender].to_hash_groups(:mobile_id)
        mob_h2h_affect_rows = @db[:mobile_hand_to_hand_affect].all

        mob_rows.each do |id, row|

            if mob_affect_rows.dig(id)
                row[:affect_models] = mob_affect_rows[id].map { |aff_row| AffectModel.new(aff_row) }
                @mobile_models[id]
            end
            if mob_gender_rows.dig(id)
                row[:genders] = mob_gender_rows[id].map { |gender_row| Game.instance.genders.dig(row[:gender_id]) }
            end
            @mobile_models[id] = MobileModel.new(id, row)
        end
        log( "done." )
    end

    # Load the item tables from database and merge them together
    protected def load_item_data
        log("Loading Item tables... ", false, 70)
        item_rows = @db[:item_base].to_hash(:id)
        weapon_rows = @db[:item_weapon].to_hash(:item_id)
        container_rows = @db[:item_container].to_hash(:item_id)

        ability_rows = @db[:item_ability].to_hash_groups(:item_id)
        item_modifier_rows = @db[:item_modifier].to_hash_groups(:item_id)
        item_wear_locations = @db[:item_wear_location].to_hash_groups(:item_id)
        item_affect_rows = @db[:item_affect].to_hash_groups(:item_id)

        item_rows.each do |id, row|
            row.merge!(weapon_rows[id]) if weapon_rows.dig(id)
            row.merge!(container_rows[id]) if container_rows.dig(id)


            row[:modifiers] = {}
            if item_modifier_rows.dig(id)
                row[:modifiers] = item_modifier_rows[id].map { |row| [@stats[row[:stat_id]].to_stat, row[:value]] }.to_h
            end
            if item_wear_locations.dig(id)
                row[:wear_locations] = item_wear_locations[id].map { |row| @wear_locations.dig(row[:wear_location_id]) }
            end
            if item_affect_rows.dig(id)
                row[:affect_models] = item_affect_rows[id].map { |row| AffectModel.new(row) }
            end
            if ability_rows.dig(id)
                row[:ability_instances] = ability_rows[id].map { |row| [@abilities[row[:ability_id]], row[:level].to_i] }
                row[:ability_instances].reject! { |ability, level| ability.nil? }
            end

            @item_models[id] = @item_model_classes[row[:item_type_id]].new(id, row)
        end
        log( "done." )
    end

    # Load shop table from database
    protected def load_shop_data
        log("Loading Shop tables... ", false, 70)
        @shop_data = @db[:shop_base].to_hash(:mobile_id)
        log( "done." )
    end

    protected def load_portal_data
        log("Loading portal table... ", false, 70)
        @portal_data = @db[:item_portal].to_hash(:item_id)
        log( "done." )
    end

    protected def load_social_data
        log("Loading Social table... ", false, 70)
        @social_data = @db[:social_base].to_hash(:id)
        log( "done." )
    end

    # load reset tables from database
    protected def load_reset_data
        log("Loading Reset tables... ", false, 70)
        reset_mobile_data = @db[:reset_mobile].all
        reset_mobile_itemgroups = @db[:reset_mobile_itemgroup].to_hash_groups(:mobile_reset_id)
        reset_itemgroup_item_data = @db[:reset_itemgroup_item].to_hash_groups(:itemgroup_id)

        reset_room_itemgroups = @db[:reset_room_itemgroup].all
        reset_room_itemgroups.each do |row|
            timer = row[:timer]
            room_id = row[:room_id]
            itemgroup_id = row[:itemgroup_id]
            itemgroup_rows = reset_itemgroup_item_data[itemgroup_id]
            if itemgroup_rows
                itemgroup_rows.each do |item_row|
                    item_id = item_row[:item_id]
                    child_itemgroup_id = item_row[:child_itemgroup_id]
                    item_row[:quantity].times do
                        item_reset = ItemReset.new(item_id, timer, nil, room_id)
                        @item_resets << item_reset
                        item_reset.activate(true)
                        if child_itemgroup_id
                            build_child_item_resets(item_reset, child_itemgroup_id, reset_itemgroup_item_data, [itemgroup_id])
                        end
                    end
                end

            end
        end

        reset_mobile_data.each do |row|

            mob_itemgroup_rows = reset_mobile_itemgroups[row[:id]]
            row[:quantity].times do
                timer = row[:timer]
                reset = MobileReset.new( row[:room_id], row[:mobile_id], row[:timer])

                if mob_itemgroup_rows
                    mob_item_resets = (reset.item_resets = [])
                    mob_itemgroup_rows.each do |mob_itemgroup_row|
                        equipped = mob_itemgroup_row[:equipped]
                        mob_itemgroup_id = mob_itemgroup_row[:itemgroup_id]
                        itemgroup_rows = reset_itemgroup_item_data[mob_itemgroup_id]
                        itemgroup_rows.each do |item_row|
                            item_id = item_row[:item_id]
                            child_itemgroup_id = item_row[:child_itemgroup_id]

                            item_row[:quantity].times do
                                item_reset = ItemReset.new(item_id, timer, equipped)
                                mob_item_resets << item_reset
                                @item_resets << item_reset
                                if child_itemgroup_id
                                    build_child_item_resets(item_reset, child_itemgroup_id, reset_itemgroup_item_data, [mob_itemgroup_id])
                                end
                            end
                        end

                    end
                end
                @mobile_resets << reset
                reset.activate(true)
            end
        end
        log( "done." )
    end

    protected def build_child_item_resets(reset, child_itemgroup_id, reset_itemgroup_item_data, id_history)
        if id_history.include?(child_itemgroup_id)
            log "Recursive child_itemgroup_id: #{child_itemgroup_id} history: [#{id_history}]"
            return
        end
        id_history << child_itemgroup_id
        itemgroup_rows = reset_itemgroup_item_data.dig(child_itemgroup_id)
        if !itemgroup_rows
            return
        end
        timer = reset.timer
        itemgroup_rows.each do |item_row|
            child_item_id = item_row[:item_id]
            child_item_child_resetgroup_id = item_row[:child_itemgroup_id]
            item_row[:quantity].times do
                child_reset = ItemReset.new(child_item_id, timer)
                reset.add_child_reset(child_reset)
                @item_resets << child_reset
                if child_item_child_resetgroup_id
                    build_child_item_resets(child_reset, child_item_child_resetgroup_id, reset_itemgroup_item_data, id_history)
                end
            end
        end
    end

    # load helpfiles
    protected def load_help_data
        log("Loading Helpfile table... ", false, 70)
        @help_data = @db[:help_base].to_hash(:id)
        # @help_data.each { |id, help| help[:keywords] = help[:keywords].split(" ") }
        log( "done." )
    end

    # load account data = this will be continually updated
    protected def load_account_data
        log("Loading Account table... ", false, 70)
        @account_data = @db[:account_base].to_hash(:id)
        log( "done." )
    end

    # load player data - this will be continually updated in the main thread
    protected def load_saved_player_data
        log("Loading Player table... ", false, 70)
        @saved_player_data = @db[:saved_player_base].to_hash(:id)
        log( "done." )
    end

    # load max ids for saved_player tables
    protected def load_max_ids
        log("Loading Player id max values... ", false, 70)
        @saved_player_id_max = @db[:saved_player_base].max(:id).to_i
        @saved_player_affect_id_max = @db[:saved_player_affect].max(:id).to_i
        @saved_player_item_id_max = @db[:saved_player_item].max(:id).to_i
        @saved_player_item_affect_id_max = @db[:saved_player_item_affect].max(:id).to_i
        log( "done." )
    end

end
