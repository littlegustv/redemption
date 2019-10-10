module GameSave

    # save an account info to the database, then update account table
    def save_new_account(account_data)
        account_id = @db[:account_base].insert(account_data)
        @account_data = @db[:account_base].to_hash(:id)
        return account_id
    end

    # save an account info to the database, then update account table
    def save_new_player(player_data)
        player_data[:position] = Constants::Position::STAND
        player_data[:room_id] = @starting_room.id
        player_data[:level] = 1
        player_id = @db[:saved_player_base].insert(player_data)
        @saved_player_data = @db[:saved_player_base].to_hash(:id)
        return player_id
    end

    # Main save method for the game. This saves all active players.
    def save

        # before_save = Time.now
        if @players.empty? # if nobody's online, there's no need to save.
            return
        end
        @db.transaction do
            delete_old_player_data
            query_hash = {
                player_base: [],
                player_affect: [],
                player_affect_modifier: [],
                player_item: [],
                player_item_affect: [],
                player_item_affect_modifier: []
            }
            @players.each do |player|           # remove old row and generate "insert query"
                save_player(player, query_hash) # data for each player
            end
            if query_hash[:player_base].length > 0 # player table
                query = "INSERT INTO `saved_player_base` " +
                "(`id`, `account_id`, `name`, `level`, `experience`, `room_id`, `race_id`, " +
                "`class_id`, `str`, `dex`, `int`, `wis`, `con`, `hp`, `mana`, `current_hp`, " +
                "`current_mana`, `wealth`, `quest_points`, `position`, `alignment`) " +
                "VALUES #{query_hash[:player_base].join(", ")};"
                @db.run(query)
            end
            if query_hash[:player_affect].length > 0 # player affects
                query = "INSERT INTO `saved_player_affect` " +
                "(`id`, `saved_player_id`, `name`, `level`, `duration`, `source_uuid`, " +
                "`source_id`, `source_type`, `data`) " +
                "VALUES #{query_hash[:player_affect].join(", ")};"
                @db.run(query)
            end
            if query_hash[:player_affect_modifier].length > 0 # player affect modifiers
                query = "INSERT INTO `saved_player_affect_modifier` " +
                "(`saved_player_affect_id`, `field`, `value`) " +
                "VALUES #{query_hash[:player_affect_modifier].join(", ")};"
                @db.run(query)
            end
            if query_hash[:player_item].length > 0 # player items
                query = "INSERT INTO `saved_player_item` " +
                "(`id`, `saved_player_id`, `equipped`, `item_id`) " +
                "VALUES #{query_hash[:player_item].join(", ")};"
                @db.run(query)
            end
            if query_hash[:player_item_affect].length > 0 # player item affects
                query = "INSERT INTO `saved_player_item_affect` " +
                "(`id`, `saved_player_item_id`, `name`, `level`, `duration`, `source_uuid`, " +
                "`source_id`, `source_type`, `data`) " +
                "VALUES #{query_hash[:player_item_affect].join(", ")};"
                @db.run(query)
            end
            if query_hash[:player_item_affect_modifier].length > 0 # player item affect modifiers
                query = "INSERT INTO `saved_player_item_affect_modifier` " +
                "(`saved_player_item_affect_id`, `field`, `value`) " +
                "VALUES #{query_hash[:player_item_affect_modifier].join(", ")};"
                @db.run(query)
            end
            @saved_player_data = @db[:saved_player_base].to_hash(:id)
        end
        # after_save = Time.now
        # log "{rSave time:{x #{after_save - before_save}"
    end

    # delete saved player database entries for online players
    protected def delete_old_player_data
        player_ids = @players.map(&:id)
        # delete player_base rows
        @db[:saved_player_base].where(id: player_ids).delete
        # get affects
        old_affect_dataset = @db[:saved_player_affect].where(saved_player_id: player_ids)
        # delete affect modifiers
        @db[:saved_player_affect_modifier].where(saved_player_affect_id: old_affect_dataset.map(:id)).delete
        # delete affects
        old_affect_dataset.delete
        # get items
        old_item_dataset = @db[:saved_player_item].where(saved_player_id: player_ids)
        # get item affects
        old_item_affect_dataset = @db[:saved_player_item_affect].where(saved_player_item_id: old_item_dataset.map(:id))
        # delete item affect modifiers
        @db[:saved_player_item_affect_modifier].where(saved_player_item_affect_id: old_item_affect_dataset.map(:id)).delete
        # delete item affects
        @db[:saved_player_item_affect].where(saved_player_item_id: old_item_dataset.map(:id)).delete
        # delete items
        @db[:saved_player_item].where(saved_player_id: player_ids).delete
    end

    # delete saved_player_affect row and relevant rows in subtables for a player with a given name
    protected def delete_database_player_affects(id)
        if !id
            log "Deleting database affects for a player not in the database: #{id}"
            return
        end
        old_affect_data = @db[:saved_player_affect].where(saved_player_id: id)
        old_affect_data.all.each do |row| # Delete old modifier rows
            @db[:saved_player_affect_modifier].where(saved_player_affect_id: row[:id]).delete
        end
        old_affect_data.delete # delete old affect rows
    end

    # delete saved_player_item row and relevant rows in subtables for a player with a given name
    protected def delete_database_player_items(id)
        if !id
            log "Deleting database items for a player not in the database? #{id}"
            return
        end
        old_item_data = @db[:saved_player_item].where(saved_player_id: id)
        old_item_data.all.each do |item_row|
            old_item_affect_rows = @db[:saved_player_item_affect].where(saved_player_item_id: item_row[:id])
            old_item_affect_rows.all.each do |item_affect_row|
                @db[:saved_player_item_affect_modifier].where(saved_player_item_affect_id: item_affect_row[:id]).delete
                # old_item_affect_modifiers.delete
            end
            old_item_affect_rows.delete
        end
        old_item_data.delete
    end

    # save a player and their items. saves md5 password hash if passed in.
    # returns the database id of the player
    protected def save_player(player, query_hash)
        player_data = { # order is important
            id: player.id,
            account_id: player.account_id,
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
            hp: player.maxhitpoints,
            mana: player.maxmanapoints,
            current_hp: player.hitpoints,
            current_mana: player.manapoints,
            wealth: player.wealth,
            quest_points: player.quest_points,
            position: player.position,
            alignment: player.alignment
        }

        # update player_base row for this player
        # query_hash[:player_base] << "UPDATE `saved_player_base` SET #{hash_to_update_query_values(player_data)} WHERE (`id` = #{player.id});\n"
        query_hash[:player_base] << hash_to_insert_query_values(player_data)

        # save current affects
        player.affects.select{ |affect| affect.savable }.each do |affect|
            save_player_affect(affect, player.id, query_hash).to_s
        end

        #save current items
        player.items.each do |item|
            save_player_item(item, player.id, query_hash)
        end
    end

    #save one player affect
    protected def save_player_affect(affect, saved_player_id, query_hash)
        @saved_player_affect_id_max += 1
        affect_data = { # The order of this is important!
            id: @saved_player_affect_id_max,
            saved_player_id: saved_player_id,
            name: affect.name,
            level: affect.level,
            duration: affect.duration,
            source_uuid: 0,
            source_id: 0,
            source_type: "None",
            data: affect.data.to_json
        }
        if affect.source
            affect_data.merge!(affect.source.db_source_fields)
        end
        query_hash[:player_affect] << hash_to_insert_query_values(affect_data)
        affect.modifiers.each do |key, value|
            modifier_data = {
                saved_player_affect_id: @saved_player_affect_id_max,
                field: key.to_s,
                value: value
            }
            query_hash[:player_affect_modifier] << hash_to_insert_query_values(modifier_data)
        end
    end

    # save one item
    protected def save_player_item(item, saved_player_id, query_hash)
        @saved_player_item_id_max += 1
        item_data = { # The order of this is important!
            id: @saved_player_item_id_max,
            saved_player_id: saved_player_id,
            equipped: (EquipSlot === item.parent_inventory) ? 1 : 0,
            item_id: item.id
        }
        query_hash[:player_item] << hash_to_insert_query_values(item_data)
        item.affects.select{ |affect| affect.savable }.each do |affect|
            save_player_item_affect(affect, item, saved_player_id, @saved_player_item_id_max, query_hash)
        end
    end

    # save one item affect
    protected def save_player_item_affect(affect, item, saved_player_id, saved_player_item_id, query_hash)
        @saved_player_item_affect_id_max += 1
        affect_data = { # The order of this is important!
            id: @saved_player_item_affect_id_max,
            saved_player_item_id: saved_player_item_id,
            name: affect.name,
            level: affect.level,
            duration: affect.duration,
            source_uuid: 0,
            source_id: 0,
            source_type: "None",
            data: affect.data.to_json
        }
        if affect.source
            affect_data.merge!(affect.source.db_source_fields)
        end
        query_hash[:player_item_affect] << hash_to_insert_query_values(affect_data)
        affect.modifiers.each do |key, value|
            modifier_data = {
                saved_player_item_affect_id: @saved_player_item_affect_id_max,
                field: key.to_s,
                value: value
            }
            query_hash[:player_item_affect_modifier] << hash_to_insert_query_values(modifier_data)
        end
    end

    # Load a player from the database. Returns the player object.
    def load_player(id, client)
        player_data = @db[:saved_player_base].where(id: id).first
        if !player_data
            log "Trying to load invalid player: \"#{id}\""
            return
        end
        player = Player.new( { id: player_data[:id],
                               account_id: player_data[:account_id],
                               name: player_data[:name],
                               level: player_data[:level],
                               alignment: player_data[:alignment],
                               race_id: player_data[:race_id],
                               class_id: player_data[:class_id],
                               wealth: player_data[:wealth],
                             },
                             self,
                             @rooms[player_data[:room_id]] || @starting_room,
                             client)
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
    protected def find_affect_source(data, player, items)
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
            source = @players.select { |p| p.id == data[:source_id] }.first
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
                source = load_player(player_data[:id], nil)
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

    # takes a hash and turns it into the values section of an INSERT sql query
    #  {a: 1, b: 961}
    #  becomes
    #  "('1', '961')"
    def hash_to_insert_query_values(hash)
        values = []
        hash.each do |k, v|
            values << "'#{v.to_s.gsub(/'/, "''")}'"
        end
        return "(#{values.join(", ")})"
    end

end
