module GameSave

    # save an account info to the database, then update account table
    def save_new_account(account_data)
        account_id = @db[:accounts].insert(account_data)
        @account_data = @db[:accounts].to_hash(:id)
        return account_id
    end

    # save an account info to the database, then update account table
    def save_new_player(player_data)
        player_data[:position_id] = :standing.to_position.id
        player_data[:room_id] = @starting_room.id
        player_data[:level] = 1
        player_id = @db[:players].insert(player_data)
        @saved_player_data = @db[:players].to_hash(:id)
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
                player_cooldown: [],
                player_learned_skill: [],
                player_learned_spell: [],
                player_affect: [],
                player_affect_modifier: [],
                player_item: [],
                player_item_cooldown: [],
                player_item_affect: [],
                player_item_affect_modifier: []
            }
            @players.each do |player|           # remove old row and generate "insert query"
                save_player(player, query_hash) # data for each player
            end
            if query_hash[:player_base].length > 0 # player table
                query = "INSERT INTO `players` " +
                "(`id`, `account_id`, `name`, `level`, `experience`, `room_id`, `race_id`, " +
                "`mobile_class_id`, `strength`, `dexterity`, `intelligence`, `wisdom`, `constitution`," +
                " `current_health`, `current_mana`, `current_movement`, " +
                " `wealth`, `quest_points`, `position_id`, `alignment`, `creation_points`, `gender_id`, `logout_time`) " +
                "VALUES #{query_hash[:player_base].join(", ")};"
                @db.run(query)
            end
            if query_hash[:player_cooldown].length > 0 # player cooldowns
                query = "INSERT INTO `player_cooldowns` " +
                "(`saved_player_id`, `symbol`, `timer`, `message`) VALUES #{query_hash[:player_cooldown].join(", ")};"
                @db.run(query)
            end
            if query_hash[:player_learned_skill].length > 0 # player skills
                query = "INSERT INTO `player_skills` " +
                "(`saved_player_id`, `skill_id`) VALUES #{query_hash[:player_learned_skill].join(", ")};"
                @db.run(query)
            end
            if query_hash[:player_learned_spell].length > 0 # player spells
                query = "INSERT INTO `player_spells` " +
                "(`saved_player_id`, `spell_id`) VALUES #{query_hash[:player_learned_spell].join(", ")};"
                @db.run(query)
            end
            if query_hash[:player_affect].length > 0 # player affects
                query = "INSERT INTO `player_affects` " +
                "(`id`, `saved_player_id`, `affect_id`, `level`, `duration`, `source_uuid`, " +
                "`source_id`, `source_type_id`, `data`) " +
                "VALUES #{query_hash[:player_affect].join(", ")};"
                @db.run(query)
            end
            if query_hash[:player_affect_modifier].length > 0 # player affect modifiers
                query = "INSERT INTO `player_affect_modifiers` " +
                "(`saved_player_affect_id`, `stat_id`, `value`) " +
                "VALUES #{query_hash[:player_affect_modifier].join(", ")};"
                @db.run(query)
            end
            if query_hash[:player_item].length > 0 # player items
                query = "INSERT INTO `player_items` " +
                "(`id`, `saved_player_id`, `equipped`, `item_id`, `container_id`) " +
                "VALUES #{query_hash[:player_item].join(", ")};"
                @db.run(query)
            end
            if query_hash[:player_item_cooldown].length > 0
                query = "INSERT INTO `player_item_cooldowns` " +
                "(`saved_player_item_id`, `symbol`, `timer`, `message) VALUES #{query_hash[:player_item_cooldown]};"
                @db.run(query)
            end
            if query_hash[:player_item_affect].length > 0 # player item affects
                query = "INSERT INTO `player_item_affects` " +
                "(`id`, `saved_player_item_id`, `affect_id`, `level`, `duration`, `source_uuid`, " +
                "`source_id`, `source_type_id`, `data`) " +
                "VALUES #{query_hash[:player_item_affect].join(", ")};"
                @db.run(query)
            end
            if query_hash[:player_item_affect_modifier].length > 0 # player item affect modifiers
                query = "INSERT INTO `player_item_affect_modifiers` " +
                "(`saved_player_item_affect_id`, `stat_id`, `value`) " +
                "VALUES #{query_hash[:player_item_affect_modifier].join(", ")};"
                @db.run(query)
            end
            @saved_player_data = @db[:players].to_hash(:id)
        end
        # after_save = Time.now
        # log "{rSave time:{x #{after_save - before_save}"
    end

    # delete saved player database entries for online players
    protected def delete_old_player_data
        player_ids = @players.map(&:id)
        # delete player_base rows
        @db[:players].where(id: player_ids).delete
        # get affects
        old_affect_dataset = @db[:player_affects].where(saved_player_id: player_ids)
        # delete affect modifiers
        @db[:player_affect_modifiers].where(saved_player_affect_id: old_affect_dataset.map(:id)).delete
        # delete affects
        old_affect_dataset.delete
        # get items
        old_item_dataset = @db[:player_items].where(saved_player_id: player_ids)
        # get item affects
        old_item_affect_dataset = @db[:player_item_affects].where(saved_player_item_id: old_item_dataset.map(:id))
        # delete item affect modifiers
        @db[:player_item_affect_modifiers].where(saved_player_item_affect_id: old_item_affect_dataset.map(:id)).delete
        # delete item affects
        @db[:player_item_affects].where(saved_player_item_id: old_item_dataset.map(:id)).delete
        # delete item cooldowns
        @db[:player_item_cooldowns].where(saved_player_item_id: old_item_dataset.map(:id)).delete
        # delete items
        @db[:player_items].where(saved_player_id: player_ids).delete
        # delete skills
        @db[:player_skills].where(saved_player_id: player_ids).delete
        # delete spells
        @db[:player_spells].where(saved_player_id: player_ids).delete
        # delete cooldowns
        @db[:player_cooldowns].where(saved_player_id: player_ids).delete
    end

    # delete saved_player_affect row and relevant rows in subtables for a player with a given name
    protected def delete_database_player_affects(id)
        if !id
            log "Deleting database affects for a player not in the database: #{id}"
            return
        end
        old_affect_data = @db[:player_affects].where(saved_player_id: id)
        old_affect_data.all.each do |row| # Delete old modifier rows
            @db[:player_affect_modifiers].where(saved_player_affect_id: row[:id]).delete
        end
        old_affect_data.delete # delete old affect rows
    end

    # delete saved_player_item row and relevant rows in subtables for a player with a given name
    protected def delete_database_player_items(id)
        if !id
            log "Deleting database items for a player not in the database? #{id}"
            return
        end
        old_item_data = @db[:player_items].where(saved_player_id: id)
        old_item_data.all.each do |item_row|
            old_item_affect_rows = @db[:player_item_affects].where(saved_player_item_id: item_row[:id])
            old_item_affect_rows.all.each do |item_affect_row|
                @db[:player_item_affect_modifiers].where(saved_player_item_affect_id: item_affect_row[:id]).delete
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
            race_id: player.race.id,
            mobile_class_id: player.mobile_class.id,
            strength: player.stats[:strength.to_stat],
            dexterity: player.stats[:dexterity.to_stat],
            intelligence: player.stats[:intelligence.to_stat],
            wisdom: player.stats[:wisdom.to_stat],
            constitution: player.stats[:constitution.to_stat],
            health: player.health,
            mana: player.mana,
            movement:player.movement,
            wealth: player.wealth,
            quest_points: player.quest_points,
            position_id: player.position.id,
            alignment: player.alignment,
            creation_points: player.creation_points,
            gender_id: player.gender.id,
            logout_time: @frame_time
        }

        # update player_base row for this player
        # query_hash[:player_base] << "UPDATE `saved_player_base` SET #{hash_to_update_query_values(player_data)} WHERE (`id` = #{player.id});\n"
        query_hash[:player_base] << hash_to_insert_query_values(player_data)

        if player.cooldowns
            player.cooldowns.each do |symbol, hash|
                cooldown_data = {
                    saved_player_id: player.id,
                    symbol: symbol.to_s,
                    timer: hash[:timer],
                    message: hash[:message]
                }
                query_hash[:player_cooldown] << hash_to_insert_query_values(cooldown_data)
            end
        end

        # skills and spells
        if player.learned_skills
            player.learned_skills.each do |s|
                query_hash[:player_learned_skill] << "(#{player.id},#{s.id})"
            end
        end

        if player.learned_spells
            player.learned_spells.each do |s|
                query_hash[:player_learned_spell] << "(#{player.id},#{s.id})"
            end
        end


        # save current affects
        if player.affects
            player.affects.select{ |affect| affect.savable }.each do |affect|
                save_player_affect(affect, player.id, query_hash).to_s
            end
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
            affect_id: affect.id,
            level: affect.level,
            duration: affect.duration,
            source_uuid: 0,
            source_id: 0,
            source_type_id: 0,
            data: affect.data.to_json
        }
        if affect.source
            affect_data.merge!(affect.source.db_source_fields)
        end
        query_hash[:player_affect] << hash_to_insert_query_values(affect_data)
        if affect.modifiers
            affect.modifiers.each do |stat, value|
                modifier_data = {
                    saved_player_affect_id: @saved_player_affect_id_max,
                    stat_id: stat.id,
                    value: value
                }
                query_hash[:player_affect_modifier] << hash_to_insert_query_values(modifier_data)
            end
        end
    end

    # save one item
    protected def save_player_item(item, saved_player_id, query_hash, container = 0)
        @saved_player_item_id_max += 1
        item_data = { # The order of this is important!
            id: @saved_player_item_id_max,
            saved_player_id: saved_player_id,
            equipped: (EquipSlot === item.parent_inventory) ? 1 : 0,
            item_id: item.id,
            container: container
        }
        query_hash[:player_item] << hash_to_insert_query_values(item_data)
        if item.affects
            item.affects.select{ |affect| affect.savable }.each do |affect|
                save_player_item_affect(affect, item, saved_player_id, @saved_player_item_id_max, query_hash)
            end
        end
        if item.cooldowns
            item.cooldowns.each do |symbol, hash|
                cooldown_data = {
                    saved_player_item_id: @saved_player_item_id_max,
                    symbol: symbol.to_s,
                    timer: hash[:timer],
                    message: hash[:message]
                }
                query_hash[:player_item_cooldown] << hash_to_insert_query_values(cooldown_data)
            end
        end
        if Container === item
            item.inventory.items.each do |contained_item|
                save_player_item(contained_item, saved_player_id, query_hash, item_data[:id])
            end
        end
    end

    # save one item affect
    protected def save_player_item_affect(affect, item, saved_player_id, saved_player_item_id, query_hash)
        @saved_player_item_affect_id_max += 1
        affect_data = { # The order of this is important!
            id: @saved_player_item_affect_id_max,
            saved_player_item_id: saved_player_item_id,
            affect_id: affect.id,
            level: affect.level,
            duration: affect.duration,
            source_uuid: 0,
            source_id: 0,
            source_type_id: 0,
            data: affect.data.to_json
        }
        if affect.source
            affect_data.merge!(affect.source.db_source_fields)
        end
        query_hash[:player_item_affect] << hash_to_insert_query_values(affect_data)
        if affect.modifiers
            affect.modifiers.each do |stat, value|
                modifier_data = {
                    saved_player_item_affect_id: @saved_player_item_affect_id_max,
                    field: stat.id,
                    value: value
                }
                query_hash[:player_item_affect_modifier] << hash_to_insert_query_values(modifier_data)
            end
        end
    end

    # Load a player from the database. Returns the player object.
    def load_player(id, client)

        player_data = @db[:players].where(id: id).first
        cooldown_rows = @db[:player_cooldowns].where(saved_player_id: id).all
        item_rows = @db[:player_items].where(saved_player_id: player_data[:id]).all.reverse
        all_item_affect_rows = @db[:player_item_affects].where(saved_player_item_id: item_rows.map{ |row| row[:id] }).all.reverse
        all_item_modifier_rows = @db[:player_item_affect_modifiers].where(saved_player_item_affect_id: all_item_affect_rows.map{ |row| row[:id]}).all.reverse
        affect_rows = @db[:player_affects].where(saved_player_id: player_data[:id]).all.reverse
        all_modifier_rows = @db[:player_affect_modifiers].where(saved_player_affect_id: affect_rows.map{ |row| row[:id] }).all.reverse
        skill_rows = @db[:player_skills].where(saved_player_id: player_data[:id]).all
        spell_rows = @db[:player_spells].where(saved_player_id: player_data[:id]).all

        if !player_data
            log "Trying to load invalid player: \"#{id}\""
            return
        end
        player_row = {
            learned_skill_ids: skill_rows.map { |row| row[:skill_id] },
            learned_spell_ids: spell_rows.map { |row| row[:spell_id] },
        }
        player_row.merge!(player_data)
        player_row[:keywords] = player_row[:name]

        player_model = PlayerModel.new(player_data[:id], player_row)
        player = Player.new(
            player_model,
            @rooms.dig(player_data[:room_id]) || @starting_room,
            client
        )
        player.experience = player_data[:experience]
        player.quest_points = player_data[:quest_points]
        healing_factor = [1.0, (@frame_time - player_data[:logout_time].to_f) / 86400].min

        max_health = player.max_health
        max_mana = player.max_mana
        max_movement = player.max_movement
        player.health = [max_health, player_data[:current_health].to_i + healing_factor * max_health].min.to_i
        player.mana = [max_mana, player_data[:current_mana].to_i + healing_factor * max_mana].min.to_i
        player.movement = [max_movement, player_data[:current_mana].to_i + healing_factor * max_movement].min.to_i
        player.update_snapshot
        cooldown_rows.each do |cooldown_row|
            symbol = cooldown_row[:symbol].to_sym
            timer = cooldown_row[:timer]
            message = cooldown_row[:message]
            player.add_cooldown(symbol, 0, message)
            player.cooldowns[symbol][:timer] = timer
        end

        item_saved_id_hash = Hash.new
        # load items

        # load items not in containers, then load items inside those recursively
        # also add cooldown data here
        item_rows.select{ |row| row[:container_id] == 0 }.each do |row|
            item = load_player_item(player, row, item_rows, item_saved_id_hash)
            item_cooldown_rows = @db[:player_item_cooldowns].where(saved_player_item_id: row[:id]).all

            item_cooldown_rows.each do |cooldown_row|
                symbol = cooldown_row[:symbol].to_sym
                timer = cooldown_row[:timer]
                message = cooldown_row[:message]
                item.add_cooldown(symbol, 0, message)
                item.cooldowns[symbol][:timer] = timer
            end
        end
        # load player affects
        affect_rows.each do |affect_row|
            affect_class = Game.instance.affect_class_with_id(affect_row[:affect_id])
            if affect_class
                source = find_affect_source(affect_row, player, player.items)
                affect = affect_class.new(player, source, affect_row[:level])
                affect.set_duration(affect_row[:duration])
                modifiers = {}
                modifier_rows = all_modifier_rows.select{ |row| row[:saved_player_affect_id] == affect_row[:id] }
                modifier_rows.each do |modifier_row|
                    stat = @stats.dig(modifier_row[:stat_id])
                    if stat
                        modifiers[stat] = modifier_row[:value]
                    end
                end
                affect.overwrite_modifiers(modifiers)
                data = JSON.parse(affect_row[:data], symbolize_names: true)
                data_string = affect_row[:data]
                pp data
                pp data_string
                affect.overwrite_data(JSON.parse(affect_row[:data], symbolize_names: true))
                if affect.apply(true)
                    affect.set_duration(affect_row[:duration])
                end
            end
        end
        # apply affects to items
        item_saved_id_hash.each do |saved_player_item_id, item|
            item_affect_rows = all_item_affect_rows.select{ |row| row[:saved_player_item_id] == saved_player_item_id }
            item_affect_rows.each do |affect_row|
                affect_class = Game.instance.affect_class_with_id(affect_row[:affect_id])
                if affect_class
                    source = find_affect_source(affect_row, player, player.items)
                    # portal??
                    # if affect_row[:name] == "portal"
                        # need to make portal use standard initialize args
                    affect = affect_class.new(item, source, affect_row[:level])
                    modifiers = {}
                    modifier_rows = all_item_modifier_rows.select{ |row| row[:saved_player_item_affect_id] == affect_row[:id] }
                    modifier_rows.each do |modifier_row|
                        stat = @stats.dig(modifier_row[:stat_id])
                        if stat
                            modifiers[stat] = modifier_row[:value]
                        end
                    end
                    affect.overwrite_modifiers(modifiers)
                    affect.overwrite_data(JSON.parse(affect_row[:data], symbolize_names: true))
                    if affect.apply(true)
                        affect.set_duration(affect_row[:duration])
                    end
                end
            end
        end
        add_global_mobile(player)
        return player
    end

    # loads a single item for a player - does not load affects. that happens later!
    protected def load_player_item(player, item_row, all_item_rows, item_saved_id_hash)
        item = load_item(item_row[:item_id], player.inventory)
        if item_row[:equipped]
            player.wear(item, true)
        end
        item_saved_id_hash[item_row[:id]] = item
        all_item_rows.select{ |row| row[:container_id] == item_row[:id] }.each do |contained_item_row|
            container_item = load_player_item(player, contained_item_row, all_item_rows, item_saved_id_hash)
            container_item.move(item.inventory)
        end
        return item
    end

    # Find/load a source for an affect.
    # Returns the source (or nil if that was the affect's source)
    # Can also return nil if the source wasn't found.
    protected def find_affect_source(data, player, items)
        source = nil
        source_type_class = Constants::SOURCE_TYPE_ID_TO_SOURCE_CLASS.dig(data[:source_type_id])
        if source_type_class == Player
            source = player if player.id == data[:source_id]
        else
            source = items.find{ |i| i.uuid == data[:source_uuid] }
        end
        if source
            return source   # source was an item on the player or the player itself? - return it!
        end
        case source_type_class
        when nil
            return nil
        when Continent
            source = @continents.dig(data[:source_id])
        when Area
            source = @areas.dig(data[:source_id])
        when Room
            source = @rooms.dig(data[:source_id])
        when Player
            # check active players
            source = @players.find { |p| p.id == data[:source_id] }
            if source # online player has been found
                return source
            end
            # check affects from inactive players
            if @inactive_player_source_affects.dig(data[:source_id])
                if @inactive_player_source_affects[data[:source_id]].size > 0
                    source = @inactive_player_source_affects[data[:source_id]].first.source
                end
            end

            if source # inactive player found as source
                return source
            end
            # check database players
            player_data = @db[:players].where(id: data[:source_id]).first
            if player_data # source exists in the database
                source = load_player(player_data[:id], nil)
                source.quit(true) # removes affects from master lists, puts into inactive players
            end
        when Mobile
            source = @mobiles.find{ |m| m.uuid == data[:source_uuid] }
            if source               # found the mobile with that uuid - great!
                return source
            end
            model = @mobile_models.dig(data[:source_id])
            if model
                source = load_mob(model, nil)
                source.destroy # mark as inactive, remove affects, etc
            end
        when Item
            source = @items.find{ |i| i.uuid = data[:source_uuid] }
            if source               # found the item with that uuid - :)
                return source
            end
            model = @item_models.dig(data[:source_id])
            if model
                source = load_item(model, nil)
                source.destroy # mark as inactive, remove affects, etc
            end
        else
            log "Unknown source_type in find_affect_source"
            log data
            return false
        end
        if source
            return source
        end
        return nil
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
            if v.is_a?(String)
                values << "'#{v.to_s.gsub(/'/, "''")}'"
            elsif v.nil?
                values << "NULL"
            else
                values << "#{v.to_s}"
            end
        end
        return "(#{values.join(", ")})"
    end

end
