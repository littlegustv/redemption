module GameSave

    # Main save method for the game. This saves all active players.
    def save
        @players.each do |name, player|                       # save each player
            save_player(player)
        end
    end

    # delete saved_player_affect row and relevant rows in subtables for a player with a given name
    def delete_database_player_affects(name)
        player_data = @db[:saved_player_base].where(name: name).first
        if !player_data
            log "deleting database affects for a player not in the database? #{name}"
            return
        end
        old_affect_data = @db[:saved_player_affect].where(saved_player_id: player_data[:id])
        old_affect_data.all.each do |row| # Delete old modifier rows
            @db[:saved_player_affect_modifier].where(saved_player_affect_id: row[:id]).delete
        end
        old_affect_data.delete # delete old affect rows
    end

    # delete saved_player_item row and relevant rows in subtables for a player with a given name
    def delete_database_player_items(name)
        player_data = @db[:saved_player_base].where(name: name).first
        if !player_data
            log "deleting database items for a player not in the database? #{name}"
            return
        end
        old_item_data = @db[:saved_player_item].where(saved_player_id: player_data[:id])
        old_item_data.all.each do |item_row|
            old_item_affect_rows = @db[:saved_player_item_affect].where(saved_player_item_id: item_row[:id])
            old_item_affect_rows.all.each do |item_affect_row|
                old_item_affect_modifiers = @db[:saved_player_item_affect_modifier].where(saved_player_item_affect_id: item_affect_row[:id])
                old_item_affect_modifiers.delete
            end
            old_item_affect_rows.delete
        end
        old_item_data.delete
    end

    # save a player and their items. saves md5 password hash if passed in.
    # returns the database id of the player
    def save_player(player, md5 = nil)
        single_call = !md5.nil?
        md5 = @db[:saved_player_base].where(name: player.name).first[:md5] if md5.nil?
        saved_player_id = nil
        old_row = @db[:saved_player_base].where(name: player.name).first
        saved_player_id = old_row.dig(:id) if old_row
        player_data = {
            name: player.name,
            level: player.level,
            experience: player.experience,
            room_id: player.room.id,
            race_id: player.race_id,
            class_id: player.class_id,
            str: player.stats[:str],
            int: player.stats[:int],
            dex: player.stats[:dex],
            con: player.stats[:con],
            wis: player.stats[:wis],

            wealth: player.wealth,
            quest_points: player.quest_points,
            position: player.position,
            alignment: player.alignment
        }
        if md5
            player_data[:md5] = md5
        end
        if saved_player_id && @db[:saved_player_base].where(id:saved_player_id).first
            @db[:saved_player_base].where(id:saved_player_id).update(player_data)
        else
            saved_player_id = @db[:saved_player_base].insert(player_data)
        end

        # Affects
        # delete existing database affects
        delete_database_player_affects(player.name)

        # save current affects
        player.affects.select{ |affect| affect.savable }.each do |affect|
            save_player_affect(affect, saved_player_id)
        end

        # Items
        # delete existing database items
        delete_database_player_items(player.name)

        #save current items
        player.items.each do |item|
            save_player_item(item, saved_player_id)
        end

        # save if single_call
        return saved_player_id
    end

    #save one player affect
    def save_player_affect(affect, saved_player_id)
        affect_data = {
            saved_player_id: saved_player_id,
            name: affect.name,
            level: affect.level,
            duration: affect.duration,
            source_type: "None",
            data: affect.data.to_json
        }
        if affect.source
            affect_data.merge!(affect.source.db_source_fields)
        end
        saved_player_affect_id = @db[:saved_player_affect].insert(affect_data)
        affect.modifiers.each do |key, value|
            modifier_data = {
                saved_player_affect_id: saved_player_affect_id,
                field: key.to_s,
                value: value
            }
            @db[:saved_player_affect_modifier].insert(modifier_data)
        end
    end

    # save one item
    def save_player_item(item, saved_player_id)
        item_data = {
            saved_player_id: saved_player_id,
            item_id: item.id
        }
        if EquipSlot === item.parent_inventory
            item_data[:equipped] = "1"
        end
        saved_player_item_id = @db[:saved_player_item].insert(item_data)
        item.affects.select{ |affect| affect.savable }.each do |affect|
            save_player_item_affect(affect, item, saved_player_id, saved_player_item_id)
        end
    end


    # save one item affect
    def save_player_item_affect(affect, item, saved_player_id, saved_player_item_id)
        affect_data = {
            saved_player_item_id: saved_player_item_id,
            name: affect.name,
            level: affect.level,
            duration: affect.duration,
            source_type: "None",
            data: affect.data.to_json
        }
        if affect.source
            affect_data.merge!(affect.source.db_source_fields)
        end
        saved_player_item_affect_id = @db[:saved_player_item_affect].insert(affect_data)
        affect.modifiers.each do |key, value|
            modifier_data = {
                saved_player_item_affect_id: saved_player_item_affect_id,
                field: key.to_s,
                value: value
            }
            @db[:saved_player_item_affect_modifier].insert(modifier_data)
        end
    end

    # Load a player from the database. Returns the player object.
    def load_player(name, client, thread)
        player_data = @db[:saved_player_base].where(name: name).first
        if !player_data
            log "Trying to load invalid player: \"#{name}\""
            return
        end
        player = Player.new( { id: player_data[:id],
                               alignment: player_data[:alignment],
                               name: player_data[:name],
                               race_id: player_data[:race_id],
                               class_id: player_data[:class_id],
                               wealth: player_data[:wealth],
                               level: player_data[:level]
                             },
                             self,
                             @rooms[player_data[:room_id]] || @starting_room,
                             client,
                             thread )
        player.experience = player_data[:experience]

        player.stats[:str] = player_data[:str]
        player.stats[:int] = player_data[:int]
        player.stats[:dex] = player_data[:dex]
        player.stats[:con] = player_data[:con]
        player.stats[:wis] = player_data[:wis]

        player.quest_points = player_data[:quest_points]
        player.position = player_data[:position]

        item_saved_id_hash = Hash.new
        # load items
        item_rows = @db[:saved_player_item].where(saved_player_id: player_data[:id]).all
        item_rows.each do |row|
            item = load_item(row[:item_id], player.inventory)
            if row[:equipped] == 1
                player.wear(item: item, silent: true)
            end
            item_saved_id_hash[row[:id]] = item
        end

        # load player affects
        affect_rows = @db[:saved_player_affect].where(saved_player_id: player_data[:id]).all
        affect_rows.each do |affect_row|
            affect_class = Constants::AFFECT_CLASS_HASH[affect_row[:name]]
            if affect_class
                source = find_affect_source(affect_row, player, player.items)
                if source != false # source can be nil, just not false - see find_affect_source
                    affect = affect_class.new(source: source, target: player, level: affect_row[:level], game: self)
                    affect.duration = affect_row[:duration]
                    modifiers = {}
                    modifier_rows = @db[:saved_player_affect_modifier].where(saved_player_affect_id: affect_row[:id]).all
                    modifier_rows.each do |modifier_row|
                        modifiers[modifier_row[:field].to_sym] = modifier_row[:value]
                    end
                    affect.overwrite_modifiers(modifiers)
                    affect.overwrite_data(JSON.parse(affect_row[:data], symbolize_names: true))
                    player.apply_affect(affect, silent: true)
                end
            end
        end

        # apply affects to items
        item_saved_id_hash.each do |saved_player_item_id, item|
            item_affect_rows = @db[:saved_player_item_affect].where(saved_player_item_id: saved_player_item_id).all
            item_affect_rows.each do |affect_row|
                affect_class = Constants::AFFECT_CLASS_HASH[affect_row[:name]]
                if affect_class
                    source = find_affect_source(affect_row, player, player.items)
                    if source != false # source can be nil, just not false - see find_affect_source
                        affect = affect_class.new(source: source, target: item, level: affect_row[:level], game: self)
                        affect.duration = affect_row[:duration]
                        modifiers = {}
                        modifier_rows = @db[:saved_player_item_affect_modifier].where(saved_player_item_affect_id: affect_row[:id]).all
                        modifier_rows.each do |modifier_row|
                            modifiers[modifier_row[:field].to_sym] = modifier_row[:value]
                        end
                        affect.overwrite_modifiers(modifiers)
                        affect.overwrite_data(JSON.parse(affect_row[:data], symbolize_names: true))
                        item.apply_affect(affect, silent: true)
                    end
                end
            end
        end

        return player

    end

    # Find/load a source for an affect.
    # Returns the source (or nil if that was the affect's source) or false for a failure to find the source
    def find_affect_source(data, player, items)
        targets = items.to_a
        source = nil
        if data[:source_type] == "Player"
            source = player if player.id == data[:source_id]
        else
            source = items.select{ |i| i.uuid == data[:source_uuid] }.first
        end
        if source
            return source   # source was an item on the player or the player itself? - return it!
        end
        case data[:source_type]
        when "None"
            return nil
        when "Continent"
            source = @continents[data[:source_id]]
        when "Area"
            source = @areas[data[:source_id]]
        when "Room"
            source = @rooms[data[:source_id]]
        when "Player"
            # check active players
            source = @players.values.select { |p| p.id == data[:source_id] }.first
            if source # online player has been found
                return source
            end
            # check inactive players
            source = @inactive_players.values.select { |p| p.weakref_alive? && p.id == data[:source_id] }.first
            if source # inactive player found as source
                return source.__getobj__ # get actual reference from the WeakRef
            end
            # check database players
            player_data = @db[:saved_player_base].where(id: data[:source_id]).first
            if player_data # source exists in the database
                source = load_player(player_data[:name], nil, nil)
                source.quit(silent: true) # removes affects from master lists, puts into inactive players
            end
        when "Mobile"
            source = @mobiles.select{ |m| m.uuid == data[:source_uuid] }.first
            if source               # found the mobile with that uuid - great!
                return source
            end
            source = load_mob(data[:source_id], nil)
            if (source)
                source.destroy # mark as inactive, remove affects, etc
            end
        when "Item"
            source = @items.select{ |i| i.uuid = data[:source_uuid] }.first
            if source               # found the item with that uuid - :)
                return source
            end
            source = load_item(data[:source_id], nil)
            if (source)
                source.destroy
            end
        else
            log "Unknown source_type in find_affect_source"
            log "data"
            return false
        end
        if source
            return source
        end
        return false
    end

    def new_uuid
        uuid = @next_uuid
        @next_uuid += 1
        return uuid
    end

end
