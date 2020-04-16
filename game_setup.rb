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
        connect_database
        clean_database
        # load database tables
        load_game_settings
        load_item_types
        load_affects

        load_elements
        load_positions
        load_commands
        load_skills
        load_spells
        load_equip_slots
        load_genders
        load_genres
        load_materials
        load_mobile_classes
        load_nouns
        load_races
        load_sectors
        load_sizes
        load_wear_locations


        load_continents
        load_areas

        load_rooms

        load_mobiles

        load_item_data
        load_shop_data
        load_reset_data
        load_help_data
        load_account_data
        load_saved_player_data
        load_portal_data
        load_social_data

        load_max_ids

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
            model_class = Constants::ITEM_MODEL_CLASSES.find{|model_class| model_class.name == row[:name]}
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

        @affect_class_hash = Hash.new
        Constants::AFFECT_CLASSES.each do |aff_class|
            row = affect_data.find { |row| row[:name] == aff_class.affect_info[:name] }
            if row
                id = row[:id]
                aff_class.set_id(id)
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

    # load skill data from database
    protected def load_skills
        log("Loading Skill tables... ", false, 70)
        skill_data = @db[:skill_base].to_hash(:id)

        missing = []
        Constants::SKILL_CLASSES.each do |skill_class|
            skill = skill_class.new
            row = skill_data.values.find{ |row| row[:name] == skill.name }
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
            log "Skills not found in database: {y#{missing.join("\n\r#{" " * 51}")}{x"
        end
    end

    # load spell data from database
    protected def load_spells
        log("Loading Spell tables... ", false, 70)
        spell_data = @db[:spell_base].to_hash(:id)

        missing = []
        Constants::SPELL_CLASSES.each do |spell_class|
            spell = spell_class.new
            row = spell_data.values.find{ |row| row[:name] == spell.name }
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
                @mobile_classes[spell_row[:class_id]].skills << spell
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
                @races[spell_row[:race_id]].skills << spell
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
            @continents[id] = Continent.new(row)
        end
        log( "done." )
    end

    # Load the area_base table
    protected def load_areas
        log("Loading Area tables... ", false, 70)
        area_data = @db[:area_base].to_hash(:id)

        area_data.each do |id, row|
            @areas[id] = Area.new(row)
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
                row[:name],
                row[:id],
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
        mob_affect_rows = @db[:mobile_affect].all
        mob_gender_rows = @db[:mobile_gender].all
        mob_h2h_affect_rows = @db[:mobile_hand_to_hand_affect].all

        mob_rows.each do |id, row|
            @mobile_models[id] = MobileModel.new(id, row)
        end
        mob_affect_rows.each do |row|
            model = @mobile_models.dig(row[:mobile_id])
            if model
                model.affect_models << AffectModel.new(row)
            else
                log "Invalid mob_affect_row #{row}"
            end
        end
        mob_gender_rows.each do |row|
            model = @mobile_models.dig(row[:mobile_id])
            if model
                model.genders << Game.instance.genders.dig(row[:gender_id])
            else
                log "Invalid mob_gender_row #{row}"
            end
        end

        log( "done." )
    end

    # Load the item tables from database and merge them together
    protected def load_item_data
        log("Loading Item tables... ", false, 70)
        item_rows = @db[:item_base].to_hash(:id)
        ac_rows = @db[:item_armor].to_hash(:item_id)
        weapon_rows = @db[:item_weapon].to_hash(:item_id)
        container_rows = @db[:item_container].to_hash(:item_id)
        spell_rows = @db[:item_spell].to_hash_groups(:item_id)
        item_modifier_rows = @db[:item_modifier].to_hash_groups(:item_id)

        item_rows.each do |id, row|
            row.merge!(weapon_rows[id]) if weapon_rows.dig(id)
            row.merge!(ac_rows[id]) if ac_rows.dig(id)
            row.merge!(container_rows[id]) if container_rows.dig(id)

            @item_models[id] = @item_model_classes[row[:item_type_id]].new(id, row)
            if item_modifier_rows.dig(id)
                item_modifier_rows[id].each do |modifier_row|
                    @item_models[id].modifiers[modifier_row[:field].to_sym] = modifier_row[:value]
                end
            end
            if ac_rows.dig(id)
                @item_models[id].modifiers.merge!(ac_rows[id].reject{ |k, v| [:id, :item_id].include?(k) })
            end
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
        log("Loading reset tables... ", false, 70)
        reset_mobile_data = @db[:new_reset_mobile].to_hash(:id)

        reset_mobile_data.values.each do |row|
            row[:quantity].times do
                reset = ResetMobile.new( row[:room_id], row[:mobile_id], row[:timer], row[:chance])
                @mobile_resets << reset
                reset.activate(true)
            end
        end
        log( "done." )
    end

    # load helpfiles
    protected def load_help_data
        log("Loading Helpfile table... ", false, 70)
        @help_data = @db[:help_base].to_hash(:id)
        @help_data.each { |id, help| help[:keywords] = help[:keywords].split(" ") }
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

    # # release unnecessary tables (already been populated, etc)
    # protected def clear_tables
    #     @affect_data = nil
    #     @position_data = nil
    #     @element_data = nil
    #     @material_data = nil
    #     @genre_data = nil
    #     @genre_affect_data = nil
    #     @noun_data = nil
    #     @size_data = nil
    #     @new_reset_mobile_data = nil
    #     @continent_data = nil
    #     @area_data = nil
    #     @room_data = nil
    #     @exit_data = nil
    #     @room_affect_data = nil
    #     @room_description_data = nil
    #     @item_modifiers = nil
    #     @ac_data = nil
    #     @weapon_data = nil
    #     @container_data = nil
    # end
end
