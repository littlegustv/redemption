class Game
    # bit of haxing in the next line to get SolarGraph to understand singleton :)
    # @!parse def Game.instance; return Game.new; end
    include Singleton

    # @return [Hash{Integer => Hash{Symbol => Integer, String}}] The help table as a hash.
    # Uses ID as key.
    attr_reader :help_data

    # @return [Hash{Integer => Hash{Symbol => Integer, String}}] The social table as a hash.
    # Uses ID as key.
    attr_reader :social_data

    # @return [Float] The current frame time.
    attr_reader :frame_time

    # @return [Integer] The current frame count.
    attr_reader :frame_count

    # @return [Hash{Symbol => Integer, String, Float}] General settings for the game.
    attr_reader :game_settings

    # @return [Hash{Integer => Integer, String, Float}] The saved player database table.
    # This gets updated every time the game saves. Uses :id as key.
    attr_reader :saved_player_data
    
    # @return [Hash{Integer => Integer, String, Float}] The saved account database table.
    # This gets udpated every time the game saves. Uses :id as key.
    attr_reader :account_data

    # @return [Array<Hash{Symbol => String}>] The array of new accounts to be created.
    # When a client completes account creation, the account data gets added to this array
    # to be created in the next Game#game_loop, after which it will be removed.
    attr_reader :new_accounts
    
    # @return [Array<Hash{Symbol => Integer, String}>] The array of new characters to be created.
    # When a client completes character creation, the character data gets added to this array to
    # be created in the next Game#game_loop, after which it will be removed.
    attr_reader :new_players

    # @return [Array<Player>] The master list of players.
    attr_reader :players

    # @return [Array<Array<Integer, Client>>] The list of logging players.
    # When a Client logs into a player, the client pushes [player.id, client] to logging_players.
    # On the next Game#game_loop, Game will load the player, link it with the client, and remove
    # the id-client pair from logging_players.
    # This is because client threads don't interact with the database.
    attr_reader :logging_players

    # @return [Array<Integer>] The list of connected account IDs.
    attr_reader :client_account_ids

    # @return [Hash{Integer => Continent}] The hash of continents created by the database.
    # Uses ID as key.
    attr_reader :continents

    # @return [Hash{Integer => Area}] The hash of areas created by the database.
    # Uses ID as key.
    attr_reader :areas

    # @return [Hash{Integer => Room}] The hash of rooms created by the database.
    # Uses ID as key.
    attr_reader :rooms

    # -- commands --

    # @return [Array<Skill>] The array of all skills.
    attr_reader :skills

    # @return [Array<Spell>] The array of all spells.
    attr_reader :spells

    # @return [Hash{Integer => Command}] The hash of all skills _and_ spells. Uses ID as key.
    attr_reader :abilities

    # -- end commands --

    # -- models --

    # @return [Hash{Integer => MobileModel}] The hash of mobile models.
    # Uses ID as key.
    attr_reader :mobile_models

    # @return [Hash{Integer => ItemModel}] The hash of item models.
    # Uses ID as key.
    attr_reader :item_models

    # -- end models --

    # -- data classes --

    # @return [Hash{Integer => Direction}] The hash of directions. Uses ID as key.
    attr_reader :directions

    # @return [Hash{Integer => Element}] The hash of elements. Uses ID as key.
    attr_reader :elements

    # @return [Hash{Integer => EquipSlotInfo}] The hash of equip slot infos. Uses ID as key.
    attr_reader :equip_slot_infos

    # @return [Hash{Integer => Gender}] The hash of genders. Uses ID as key.
    attr_reader :genders

    # @return [Hash{Integer => Genre}] The hash of genres. Uses ID as key.
    attr_reader :genres

    # @return [Hash{Integer => Material}] The hash of materials. Uses ID as key.
    attr_reader :materials

    # @return [Hash{Integer => MobileClass}] The hash of mobile classes. Uses ID as key.
    attr_reader :mobile_classes

    # @return [Hash{Integer => Noun}] The hash of nouns. Uses ID as key.
    attr_reader :nouns

    # @return [Hash{Integer => Position}] The hash of positions. Uses ID as key.
    attr_reader :positions

    # @return [Hash{Integer => Race}] The hash of races. Uses ID as key.
    attr_reader :races

    # @return [Hash{Integer => Sector}] The hash of sectors. Uses ID as key.
    attr_reader :sectors

    # @return [Hash{Integer => Size}] The hash of sizes. Uses ID as key.
    attr_reader :sizes

    # @return [Hash{Integer => Stat}] The hash of stats. Uses ID as key.
    attr_reader :stats

    # @return [Hash{Integer => WearLocation}] The hash of wear locations. Uses ID as key.
    attr_reader :wear_locations

    # -- end data classes --

    #
    # Game initializer.
    #
    def initialize

        # @type [TCPServer]
        # The TCPServer object
        @server = nil

        # @type [Sequel::Database]
        # The database connection
        @db = nil

        # @type [Float]
        # The time at the beginning of the frame.
        @frame_time = 0.0
        
        # @type [Integer]
        # Frame count - goes up by 1 every frame (:
        @frame_count = 0

        # @type [Room]
        # The room that new characters start in.
        @starting_room = nil
        
        # @type [Boolean]
        # When this is set to `true`, the game will reload on the next frame.
        @reload = false

        # -- Database tables --

        # @type [Hash{Symbol => Integer, Float, String}]
        # Hash with values for next_uuid, login_splash, etc
        @game_settings = Hash.new

        # @type [Hash{Integer => Hash{Symbol => Integer}}]
        # Shops table as hash. Uses :mobile_id as key.
        @shop_data = Hash.new

        # @type [Hash{Integer => Hash{Symbol => Integer, String}}]
        # Helps table as hash  (uses :id as key)
        @help_data = Hash.new

        # @type [Hash{Integer => Hash{Symbol => Integer, String}}]
        # Socials table as hash (uses :id as key)
        @social_data = Hash.new

        # @type [Hash{Integer => Hash{Symbol => Integer, String}}]
        # Accounts table as hash (uses :id as key)
        @account_data = Hash.new

        # @type [Hash{Integer => Hash{Symbol => Integer, String}}]
        # Players table as hash (uses :id as key)
        @saved_player_data = Hash.new
        
        # -- end Database Tables --

        # -- players table IDs --

        # @type [Integer]
        # max id in database table players
        @saved_player_id_max = 0

        # @type [Integer]
        # max id in database table player_affects
        @saved_player_affect_id_max = 0

        # @type [Integer]
        # max id in database table player_items
        @saved_player_item_id_max = 0
        
        # @type [Integer]
        # max id in database table player_item_affects
        @saved_player_item_affect_id_max = 0

        # -- end players table IDs --

        # @type [Hash{Integer => Class}]
        # Affect classes as hash (uses :id as key)
        @affect_class_hash = Hash.new

        #  -- Resets -- 

        # @type [Array<MobileReset>]
        # Mobile resets in an array.
        @mobile_resets = []

        # @type [Array<ItemReset>]
        # Item resets in an array.
        @item_resets = []

        # @type [Array<Reset>]
        # Array of Resets waiting to pop - sorted by reset.pop_time (ascending)
        @active_resets = []

        # @type [Boolean]
        # When the game starts or reloads, this is set to `true`. When initial resets are completed,
        # a message is logged and this is set to `false`.
        @initial_reset = true

        # -- End Resets --

        # -- Models --

        # @type [Hash{Integer => Class}]
        # Hash of item model classes - uses item_type_id as key
        @item_model_classes = Hash.new

        # @type [Hash{Integer => ItemModel}]
        # Hash of item models (uses :id as key)
        @item_models = Hash.new

        # @type [Hash{Integer => MobileModel}]
        # Hash of mobile models (uses :id as key)
        @mobile_models = Hash.new

        # -- end Models --

        # -- Data Objects --

        # @type [Hash{Integer => Direction}]
        # hash of Direction objects (uses :id as key)
        @directions = Hash.new

        # @type [Hash{Integer => Element}]
        # hash of Element objects (uses :id as key)
        @elements = Hash.new

        # @type [Hash{Integer => EquipSlotInfo}]
        # hash of EquipSlotInfo objects (uses :id as key)
        @equip_slot_infos = Hash.new
        
        # @type [Hash{Integer => Gender}]
        # hash of Gender objects (uses :id as key)
        @genders = Hash.new

        # @type [Hash{Integer => Genre}]
        # hash of Genre objects (uses :id as key)
        @genres = Hash.new
        
        # @type [Hash{Integer => Material}]
        # hash of Material objects (uses :id as key)
        @materials = Hash.new
        
        # @type [Hash{Integer => MobileClass}]
        # hash of MobileClass objects (uses :id as key)
        @mobile_classes = Hash.new
        
        # @type [Hash{Integer => Noun}]
        # hash of Noun objects (uses :id as key)
        @nouns = Hash.new
        
        # @type [Hash{Integer => Position}]
        # hash of Position objects (uses :id as key)
        @positions = Hash.new
        
        # @type [Hash{Integer => Race}]
        # hash of Race objects (uses :id as key)
        @races = Hash.new
        
        # @type [Hash{Integer => Sector}]
        # hash of Sector objects (uses :id as key)
        @sectors = Hash.new
        
        # @type [Hash{Integer => Size}]
        # hash of Size objects (uses :id as key)
        @sizes = Hash.new
        
        # @type [Hash{Integer => Stat}]
        # hash of Stat objects (uses :id as key)
        @stats = Hash.new
        
        # @type [Hash{Integer => WearLocation}]
        # hash of WearLocation objects (uses :id as key)
        @wear_locations = Hash.new

        # @type [Hash{Symbol => Direction}]
        # Hash of directions with symbol as key
        @direction_lookup = nil

        # @type [Hash{Symbol => Element}]
        # Hash of elements with symbol as key
        @element_lookup = nil
        
        # @type [Hash{Symbol => Gender}]
        # Hash of genders with symbol as key
        @gender_lookup = nil
        
        # @type [Hash{Symbol => Genre}]
        # Hash of genres with symbol as key
        @genre_lookup = nil
        
        # @type [Hash{Symbol => Material}]
        # Hash of materials with symbol as key
        @material_lookup = nil
        
        # @type [Hash{Symbol => Noun}]
        # Hash of nouns with symbol as key
        @noun_lookup = nil
        
        # @type [Hash{Symbol => Position}]
        # Hash of positions with symbol as key
        @position_lookup = nil
        
        # @type [Hash{Symbol => Sector}]
        # Hash of sectors with symbol as key
        @sector_lookup = nil
        
        # @type [Hash{Symbol => Size}]
        # Hash of sizes with symbol as key
        @size_lookup = nil
        
        # @type [Hash{Symbol => Stat}]
        # Hash of stats with symbol as key
        @stat_lookup = nil

        # @type [Hash{Symbol => WearLocation}]
        # Hash of wear locations with symbol as key
        @wear_location_lookup = nil

        # -- End Data Objects --

        # -- GameObjects --

        # @type [Hash{Integer => GameObject}]
        # GameObjects as hash (uses :uuid as key)
        @gameobjects_by_uuids = Hash.new

        # @type [Hash{Integer => Continent}]
        # Continent objects as hash (uses :id as key)
        @continents = Hash.new

        # @type [Hash{Integer => Area}]
        # Area objects as hash (uses :id as key)
        @areas = Hash.new

        # @type [Hash{Integer => Room}]
        # Room objects as hash (uses :id as key)
        @rooms = Hash.new

        # @type [Hash{Integer => Exit}]
        # Exit objects as hash (uses :id as key)
        @exits = Hash.new

        # @type [Set<Mobile>]
        # Mobiles that are engaged in combat.
        @combat_mobs = Set.new

        # @type [Set<Mobile>]
        # Mobiles that are not at full heath/mana/movement.
        @regen_mobs = Set.new

        # @type [Set<GameObject>]
        # GameObjects with at least one active cooldown.
        @cooldown_objects = Set.new

        # @type [Hash{Symbol => Array<Item>}]
        # Hash containing keyword symbols as keys and an array of items as values.
        @item_keyword_map = Hash.new

        # @type [Hash{Symbol => Array<Mobile>}]
        # Hash containing keyword symbols as keys and an array of items as values.
        @mobile_keyword_map = Hash.new

        # @type [Set<Item>]
        # Set of all items.
        @items = Set.new

        # @type [Set<Mobile>]
        # Set of all mobiles.
        @mobiles = Set.new

        # -- End GameObjects --

        # @type [Array<Integer>]
        # Account IDs of connected clients
        @client_account_ids = []

        # @type [Array<Hash{Symbol => String}>]
        # Accounts waiting to be created - added to from client threads
        @new_accounts = []

        # @type [Array<Hash{Symbol => String, Integer}>]
        # Players waiting to be created - added to from client threads
        @new_players = []

        # @type [Array<Player>]
        # players online
        @players = []

        # @type [Array<Client>]
        # connected clients
        @clients = []

        # @type [Hash{Integer => Array<Affect>}]
        # Hash with key Player.id and value Array<Affect>, where the array is affects with source `player`
        # applied to objects other than `player`. Used to match up affect sources when players log out and
        # back in.
        @inactive_player_source_affects = Hash.new

        # @type [Array<Array<Integer, Client>>]
        # The list of logging players.
        # When a Client logs into a player, the client pushes [player.id, client] to logging_players.
        # On the next Game#game_loop, Game will load the player, link it with the client, and remove
        # the id-client pair from logging_players.
        # This is because client threads don't interact with the database.
        @logging_players = []               # ids of players waiting to be added to the game

        # @type [Set<Affect>]
        # Periodic affects get added to this set when they are enabled. They won't trigger their #period
        # until (at least) the following frame.
        @new_periodic_affects = Set.new

        # @type [Array<Affect>]
        # Affects with a duration exist in this array. Array is sorted by Affect#clear_time (ascending).
        # Affects are cleared when their clear time comes.
        @timed_affects = []

        # @type [Array<Affect>]
        # Affects with a period exist in this array. Array is sorted by Affect#next_periodic_time.
        @periodic_affects = []

        # @type [Array<Skill>]
        # Skill object array
        @skills = []

        # @type [Array<Spell]
        # Spell object array
        @spells = []

        # @type [Array<Command>]
        # Command object array
        @commands = []

        # @type [Array<Command>]
        # Server command object array
        @server_commands = []

        # @type [Hash{Integer => Command}]
        # Hash of skills and spells. Key is ID.
        @abilities = Hash.new

        # @type [ Hash{ Integer => Hash{ Symbol => Array<Object, Symbol, Integer> } } ]
        # Event responders
        @responders = Hash.new

        # @type [Boolean]
        # When shutdown is set to `true`, the game threads will all stop and the process will exit.
        @shutdown = false

    end

    #
    # This is the main loop of the game. One iteration through the loop is one 'frame'.
    #
    # @return [nil]
    #
    def game_loop
        total_time = 0 
        last_frame_time = Time.now.to_f - (1.0 / Constants::Interval::FPS)
        while !@shutdown do
            if @reload
                log "Starting reload..."
                save
                reload
                log "Reload complete."
                @reload = false
            end
            @frame_time = Time.now.to_f
            @frame_count += 1

            # insert into the database any new accounts waiting
            @new_accounts.each do |account_data|
                save_new_account(account_data)
                @new_accounts.delete(account_data)
            end

            # insert into the database any new players waiting
            @new_players.each do |player_data|
                save_new_player(player_data)
                @new_players.delete(player_data)
            end

            # load any players whose ids have been added to the logging_players queue
            @logging_players.dup.each do |player_id, client|
                @logging_players.delete([player_id, client])
                player = nil
                if (player = @players.find{ |p| p.id == player_id }) # found in online player
                    player.reconnect(client)
                elsif (player = load_player(player_id, client) )
                    # load player normally - nothing else to do, maybe!
                end
                if player
                    if @inactive_player_source_affects.dig(player.id)
                        @inactive_player_source_affects[player.id].each do |source_aff|
                            source_aff.set_source(player)
                        end
                        @inactive_player_source_affects.delete(player.id)
                    end
                    @players.unshift(player)
                end
            end

            # save every so often!
            # add one to the frame_count so it doesn't save on combat frames, etc

            if (@frame_count + 1) % Constants::Interval::AUTOSAVE == 0
                before = Time.now.to_f
                save
                save_time = Time.now.to_f - before
            end


            # each combat ROUND

            if @frame_count % Constants::Interval::ROUND == 0
                before = Time.now.to_f
                combat
                round_time = Time.now.to_f - before
            end

            if @frame_count % Constants::Interval::TICK == 0
                before = Time.now.to_f
                tick
                tick_time = Time.now.to_f - before
            end

            # before = Time.now.to_f
            update
            # update_time = Time.now.to_f - before

            @players.each do | player |
                player.send_to_client
            end

            handle_resets

            end_time = Time.now.to_f
            loop_computation_time = end_time - @frame_time
            sleep_time = (Constants::Interval::FRAME_SLEEP_TIME - loop_computation_time)
            total_time += loop_computation_time

            # Sleep until the next frame, if there's time left over
            if sleep_time < 0 # try to figure out why there isn't!
                slow_frame_diagnostic(loop_computation_time)
            else
                sleep([sleep_time, 0].max) #
            end
        end
        # game is being shut down after this point!
        save
        @clients.each do |client|
            client.send_output("{YServer is shutting down. Goodbye!{x")
        end
        @players.dup.each do |player|
            player.quit
        end
        @clients.dup.each do |client|
            client.disconnect
        end
        @client_accept_thread.kill
        @server_input_thread.kill
        return
    end

    #
    # Diagnose a slow frame to determine the cause.
    #
    # @param [Float] loop_computation_time The time taken for computation in that loop.
    #
    # @return [nil]
    #
    def slow_frame_diagnostic(loop_computation_time)
        percent_overage = (loop_computation_time * 100 / (1.0 / Constants::Interval::FPS) - 100).floor
        if $VERBOSE && false # disabled (temporary?)
            @last_gc_stat = GC.stat
            gc_stat = GC.stat
            lines = []
            gc_stat.each do |key, value|
                if value != last_gc_stat[key]
                    lines << key.to_s.ljust(30) + last_gc_stat[key].to_s.ljust(14) + " -> " + value.to_s
                end
            end
            log lines.join("\n")
            causes = []
            if gc_stat[:minor_gc_count] != last_gc_stat[:minor_gc_count]
                causes << "  Minor Garbage Collection"
            end
            if gc_stat[:major_gc_count] != last_gc_stat[:major_gc_count]
                causes << "  Major Garbage Collection"
            end
            if (gc_stat[:heap_allocatable_pages] != last_gc_stat[:heap_allocatable_pages] ||
                gc_stat[:heap_available_slots] != last_gc_stat[:heap_available_slots] ||
                gc_stat[:heap_allocated_pages] != last_gc_stat[:heap_allocated_pages] )
                causes << "  Heap Allocation"
            end
            last_heap_free = last_gc_stat[:heap_free_slots].to_i == 0 ? 1 : last_gc_stat[:heap_free_slots]
            if (gc_stat[:heap_free_slots] || 1) / last_heap_free > 3 # drastic increase in open heap slots
                causes << "  Freeing Heap Slots"
            end
            if (@frame_count + 1) % Constants::Interval::AUTOSAVE == 0
                causes << "  Save     {c%0.4f{x" % [save_time]
            end
            if @frame_count % Constants::Interval::ROUND == 0
                causes << "  Round    {c%0.4f{x" % [round_time]
            end
            if @frame_count % Constants::Interval::TICK == 0
                causes << "  Tick     {c%0.4f{x" % [tick_time]
            end
            causes << "  Update   {c%0.4f{x" % [update_time]
            percent_overage = (loop_computation_time * 100 / (1.0 / Constants::Interval::FPS) - 100).floor
            log ("Frame {m#{@frame_count}{x took {c#{percent_overage}\%{x too long - possible causes:\n#{causes.join("\n")}")
        else
            log ("Frame {m#{@frame_count}{x took {c#{percent_overage}\%{x too long.")
        end
        return
    end

    #
    # <Description>
    #
    # @param [String] color Color to use for the message, like "{g" for green.
    # @param [String] message A message to describe this profile
    # @param [Boolean] verbose true if you want report.pretty print
    #
    # @return [nil]
    #
    def profile(color, message, verbose = false)

        MemoryProfiler.start if $VERBOSE

        yield

        if $VERBOSE
            report = MemoryProfiler.stop

            log "#{color}<<<<<<<<<<<<<<<<<<<<<<<<<<<< #{message} >>>>>>>>>>>>>>>>>>>>>>>>{x"

            if verbose
                report.pretty_print
            end

            ObjectSpace.each_object.inject(Hash.new 0) { |h,o| h[o.class] += 1; h }.sort_by { |k,v| -v }.take(5).each { |klass, count| log "#{count.to_s.ljust(10)} #{klass}" }

            log "ALLOCATED #{ ( report.total_allocated_memsize / 10000 ) / 100.0 } MB"
            log "RETAINED #{ ( report.total_retained_memsize / 10000 ) / 100.0 } MB"
        end
        return
    end

    # eventually, this will handle all game logic

    #
    # Game#update is called once per frame. It handles player command processing and also
    # periodic/timed affects and cooldowns.
    #
    # @return [nil]
    #
    def update
        @players.each do | player |
            player.process_commands
        end
        handle_periodic_affects
        handle_timed_affects
        handle_cooldown_objects
        return
    end

    #
    # Handle mobile combat and mobile's periodic combat regeneration.
    #
    # @return [nil]
    #
    def combat
        @combat_mobs.to_a.each do |mob|
            mob.combat
        end
        @regen_mobs.to_a.each do |mob|
            mob.combat_regen
        end
        return
    end

    #
    # Have game target GameObjects using options from a query.
    #
    # Query options: 
    #
    #   :argument   # A String or Query to describe the target, eg. "2*50.diamond". This option overrides :keywords.
    #   :keywords   # A Set of Symbols to match keywords with. Usually generated by :argument.
    #   :offset     # An Integer offset to pick the Nth result. Usually generated by :argument.
    #   :quantity   # The number of desired results. Usually generated by :argument.
    #   :list       # An array of GameObjects to use as a base list
    #   :type       # A Class or Array of Classes to match
    #   :affect     # An Affect name or Array of Affect names to require results to have as affects
    #   :not        # A GameObject or Array of GameObjects to subtract from the results.
    #   :attacking  # A GameObject or Array of GameObjects that the results must be attacking.
    #   :visible_to # A GameObject which the results must be visible to.
    #   :where_to   # A GameObject which the results must be able to have been "where"d by.
    #   :limit      # Integer to limit the number of results.
    #
    # @param [Hash] **query The query.
    # @option query [Array<GameObject>] :list A list of GameObjects to filter from.
    # @option query [Array<Class>] :type An array containing GameObject Classes
    #
    # @return [Array<GameObjects>] The results of the query.
    #
    def target( **query )
        if query.key?(:argument)
            argument = query[:argument]
            if argument
                arg_q = argument.to_query
                query.merge!({
                    :offset => arg_q.offset || query[:offset],
                    :quantity => arg_q.quantity || query[:quantity],
                    :keywords => arg_q.keywords
                })
            else # nil keywords!
                return []
            end
        end
        targets = []
        if query.key?(:list)
            targets = query[:list].reject(&:nil?) # got a crash here once but don't know why - maybe a bad list passed in?
            if query.key?(:type)
                types = [query[:type]].flatten
                targets.reject! do |target| 
                    !types.any? { |type| target.is_a?(type) }
                end
            end
        elsif query.key?(:type)
            query[:type] = [query[:type]].flatten
            targets += @areas.values       if query[:type].to_a.include? Area
            targets += @continents.values  if query[:type].to_a.include? Continent
            targets += @players            if query[:type].to_a.include? Player
            targets += @items.to_a         if query[:type].to_a.include? Item
            targets += @mobiles.to_a       if query[:type].to_a.include? Mobile

        else
            targets = @areas.values + @players + @items.to_a + @mobiles.to_a
        end

        targets = targets.select { |t| query[:affect].to_a.any?{ |affect| t.affected?( affect.to_s ) } }  if query.key?(:affect)
        targets -= query[:not].to_a                                                                       if query.key?(:not)
        targets = targets.select { |t| query[:attacking].to_a.include? t.attacking }                      if query.key?(:attacking)
        targets = targets.select { |t| t.fuzzy_match( query[:keywords] ) }                                if query.key?(:keywords)
        targets = targets.select { |t| query[:visible_to].can_see? t }                                    if query.key?(:visible_to) && !query[:visible_to].nil?
        targets = targets.select { |t| query[:where_to].can_where? t }                                    if query.key?(:where_to)
        targets = targets[0...query[:limit].to_i]                                                         if query.key?(:limit)

        query[:offset] == "all" || query[:offset].nil? ? offset = 0 : offset = [0, query[:offset].to_i - 1].max
        query[:offset] == "all" || query[:quantity] == "all" || query[:quantity].nil? ? quantity = targets.length : quantity = [1, query[:quantity].to_i].max

        targets = targets[ offset...offset+quantity ].to_a

        return targets
    end

    #
    # Returns an array of items which positively fuzzy matched against a given query.
    #
    # @param [Hash{Symbol => Integer, String}] query The query to match against.
    #
    # @return [Array<Item>] The array of positive matches.
    #
    def target_global_items(query)
        targets = nil
        query.keywords.each do |keyword|
            if @item_keyword_map.key?(keyword)
                if targets
                    targets = targets & @item_keyword_map[keyword]
                else
                    targets = @item_keyword_map[keyword]
                end
                if targets.size == 0
                    return targets
                end
            end
        end
        return targets
    end

    #
    # Returns an array of mobiles which positively fuzzy matched against a given query.
    #
    # @param [Hash{Symbol => Integer, String}] query The query to match against.
    #
    # @return [Array<Mobile>] The array of positive matches.
    #
    def target_global_mobiles(query)
        targets = nil
        query.keywords.each do |keyword|
            if @mobile_keyword_map.key?(keyword)
                if targets
                    targets = targets & @mobile_keyword_map[keyword]
                else
                    targets = @mobile_keyword_map[keyword]
                end
                if targets.size == 0
                    return targets
                end
            end
        end
        return targets
    end

    #
    # Called on every tick. Does newbie tips and updates weather.
    #
    # @return [nil]
    #
    def tick
        if rand(0..100) < 75
            @players.each_output("{MMud newbies '#{ Constants::Tips::TOPTIPS.sample }'{x", send_to_sleeping: true)
        end

        weather
    end

    #
    # Add a new timed affect.
    # Affect will be cleared when its clear_time has come.
    #
    # @param [Affect] affect The new affect
    #
    # @return [nil]
    #
    def add_timed_affect(affect)
        if affect.permanent
            # how'd you get in here?
            log "Error: Trying to add permanent affect #{affect.name} as a timed affect."
            puts caller[0..3]
            return
        end
        index = @timed_affects.bsearch_index { |aff| aff.clear_time >= affect.clear_time }
        if index
            @timed_affects.insert(index, affect)
        else
            @timed_affects << affect
        end
        return
    end

    #
    # Remove a timed affect early.
    # Affect will be removed from @timed_affects instantly.
    #
    # @param [Affect] affect The affect to remove.
    #
    # @return [Boolean] True if the affect was removed, otherwise false.
    #
    def remove_timed_affect(affect)
        if affect.permanent || !affect.clear_time
            # how'd you get in here?
            log "Error trying to remove affect #{affect.name} from timed affects."
            puts caller[0..3]
            return false
        end
        # find index of first affect with the same clear time
        index = @timed_affects.bsearch_index { |aff| aff.clear_time >= affect.clear_time}
        if !index # no such index found
            return false
        end
        # check each of those affects with identical clear_time for the correct one
        while @timed_affects[index].clear_time == affect.clear_time
            if @timed_affects[index] == affect
                @timed_affects.delete_at(index)
                return true
            end
            index += 1
        end
        return false
    end

    #
    # Clear all affects whose clear_times have come.
    #
    # @return [nil]
    #
    def handle_timed_affects
        index = @timed_affects.bsearch_index { |aff| aff.clear_time > @frame_time }
        # slice array where affects are supposed to be cleared up until
        @timed_affects.slice!(0...index).each do |aff|
            aff.clear
        end
    end

    #
    # Add a new periodic affect.
    # Will be integrated into the @periodic_affect array in next Game#handle_periodic_affects.
    #
    # @param [Affect] affect The affect to add.
    #
    # @return [nil]
    #
    def add_periodic_affect(affect)
        if !affect.period
            log "Error: Trying to add affect #{affect.name} with no period as a periodic affect."
            puts caller[0..3]
            return
        end
        @new_periodic_affects.add(affect)
    end

    #
    # Remove an affect from @periodic_affects and @new_periodic_affects
    #
    # @param [Affect] affect The affect to remove.
    #
    # @return [Boolean] True if the affect was removed, otherwise false.
    #
    def remove_periodic_affect(affect)
        @new_periodic_affects.delete(affect)
        if !affect.period
            # how'd you get in here?
            log "Error: Trying to remove affect without period #{affect.name} from periodic affects."
            puts caller[0..3]
            return false
        end
        # find index of first affect with the same next_periodic_time
        index = @periodic_affects.bsearch_index { |aff| aff.next_periodic_time >= affect.next_periodic_time}
        if !index # no such index found
            # puts "#{affect.name} not found in periodic affects"
            return false
        end
        #check each of those affects with identical next_periodic_time for the correct one
        while @periodic_affects[index].next_periodic_time == affect.next_periodic_time
            if @periodic_affects[index] == affect
                @periodic_affects.delete_at(index)
                return true
            end
            index += 1
        end
        return false
    end

    #
    # Handle affects with periodic methods
    #
    # @return [nil]
    #
    def handle_periodic_affects
        # join new periodic affects into the master array
        @new_periodic_affects.each do |new_aff|
            index = @periodic_affects.bsearch_index { |aff| aff.next_periodic_time >= new_aff.next_periodic_time }
            if index
                @periodic_affects.insert(index, new_aff)
            else
                @periodic_affects << new_aff
            end
        end
        @new_periodic_affects.clear
        # slice the periodic-ready affects out of the array
        index = @periodic_affects.bsearch_index { |aff| aff.next_periodic_time > @frame_time }

        periodics_affects_to_call = @periodic_affects.slice!(0...index)
        periodics_affects_to_call.each_with_index do |aff, index|
            aff.periodic
            aff.schedule_next_periodic_time
        end
    end

    #
    # Activate a reset.
    # _Called only by the reset itself_
    #
    # @param [Reset] reset The reset to activate.
    #
    # @return [nil]
    #
    def activate_reset(reset)
        index = @active_resets.bsearch_index { |r| r.pop_time >= reset.pop_time }
        if index
            @active_resets.insert(index, reset)
        else
            @active_resets << reset
        end
    end

    #
    # Handle resets.
    # Iterate through resets, popping each until resets not ready to pop are found.
    #
    # @return [nil]
    #
    def handle_resets
        if @active_resets.size == 0
            if @initial_reset
                log "Initial resets complete."
                @initial_reset = false
            end
            return
        end
        @active_resets.size.times do
            if Time.now.to_f - @frame_time > Constants::Interval::FRAME_SLEEP_TIME * 0.6
                break
            end
            reset = @active_resets.first
            if @initial_reset && reset.pop_time > 0
                log "Initial resets complete."
                @initial_reset = false
            end
            if @frame_time >= reset.pop_time # either it's time to pop this reset, or...
                @active_resets.shift
                if reset.success?
                    reset.pop
                end
            else
                # stop trying to reset, all resets in loop after here are in the future!
                break
            end
        end
        return
    end

    #
    # Load a mobile into the game using a model or mobile ID.
    # Returns either the new mobile or `nil` if the mobile failed to load (invalid id?).
    # 
    #
    # @param [MobileModel, Integer] model_or_id Either a ModelModel describing a mobile or a mobile ID.
    # @param [Room, nil] room The room to place the mobile in, or `nil` if it "isn't anywhere".
    # @param [MobileReset, nil] reset The reset responsible for this mobile, or `nil` if it has none.
    #
    # @return [Mobile, nil] The mobile, or `nil`.
    #
    def load_mob( model_or_id, room, reset = nil )
        model = (model_or_id.is_a?(Integer)) ? @mobile_models.dig(model_or_id) : model_or_id
        if !model.is_a?(MobileModel)
            log "load_item [ITEM MODEL NOT FOUND] Model or ID: #{model_or_id}"
            return nil
        end
        mob = Mobile.new( model, room, reset )
        add_global_mobile(mob)
        if @shop_data.dig(model.id)
            AffectShopkeeper.new( mob ).apply(true)
        end
        return mob
    end

    #
    # Load an item into the game using a model or Item ID.
    # Returns either the new item or `nil` if the item failed to load (invalid id?).
    #
    # @param [ItemModel, Integer] model_or_id Either an ItemModel describing the item or an item ID.
    # @param [Inventory, nil] inventory The inventory the item is going in, or nil if it isn't "going anywhere".
    # @param [Reset] reset The reset responsible for this item, or `nil` if it has none.
    #
    # @return [Item, nil] The item, or `nil`.
    #
    def load_item( model_or_id, inventory, reset = nil )
        model = (model_or_id.is_a?(Integer)) ? @item_models.dig(model_or_id) : model_or_id
        if !model.is_a?(ItemModel)
            log "load_item [ITEM MODEL NOT FOUND] Model or ID: #{model_or_id}"
            return nil
        end
        item_class = model.class.item_class
        item = item_class.new(model, inventory, reset)
        add_global_item(item)
        return item
    end

    #
    # Return an array of Commands for a given mobile and keyword, sorted by priority.
    #
    # @param [Mobile] actor The mobile.
    # @param [String, Symbol] cmd The keyword.
    #
    # @return [Array<Command>] The matching commands.
    #
    def find_commands( actor, cmd )
        cmd = cmd.to_s
        matches = (
            @commands.select { |command| command.keywords.include?( cmd.to_sym ) } +
            actor.skills.select{ |skill| skill.keywords.include?( cmd.to_sym ) }
        ).sort_by(&:priority)
        return matches
    end

    #
    # Returns true if a given GameObject responds to a given event
    #
    # @param [GameObject] object the GameObject.
    # @param [Symbol] event The event.
    #
    # @return [Boolean] True if the object responds to the event.
    #
    def responds_to_event(object, event)
        return @responders.dig(object.uuid, event).nil?
    end

    #
    # Send an event to a list of objects
    #
    #   fire_event(some_mobile, :test, {})
    #   fire_event(some_mobile, :on_hit, data)
    #
    # @param [GameObject] object The object responding to the event.
    # @param [Symbol] event The event.
    # @param [Hash{}, nil] data A data hash, or `nil`.
    #
    # @return [Boolean] True, for some reason.
    #
    def fire_event(object, event, data)
        @responders.dig(object.uuid, event).to_a.each do |callback_object, callback, priority|
            callback_object.send(callback, data)
        end
        return true
    end

    #
    # Adds a given object as a listener for an event. A supplied callback will be called when the
    # event fires for the given object.
    #
    # @param [GameObject] object The object listening for the event.
    # @param [Symbol] event The event.
    # @param [Object] callback_object The object with the callback method.
    # @param [Symbol] callback The callback method.
    # @param [Integer] priority The priority. Higher means it will happen first.
    #
    # @return [nil]
    #
    def add_event_listener(object, event, callback_object, callback, priority = 100)
        key = object.uuid
        if !@responders[key]
            @responders[key] = Hash.new
        end
        if !@responders[key][event]
            @responders[key][event] = []
        end
        @responders[key][event].push([callback_object, callback, priority])
        if @responders[key][event].size > 1 # if there are multiple, sort for priority
            @responders[key][event].sort_by { |o, c, p| [p, c] }.reverse
        end
        return
    end

    #
    # Remove an object as a listener for a given event.
    #
    # @param [GameObject] object The object that was listening for the event.
    # @param [Symbol] event The event.
    # @param [Object] callback_object The callback object.
    #
    # @return [nil]
    #
    def remove_event_listener(object, event, callback_object)
        if @reload
            return
        end
        if !object
            log ("Trying to remove event for nil object. #{event} #{callback_object.name}")
        end
        key = object.uuid
        if @responders.dig(key, event)
            @responders[key][event].reject!{ |t| t[0] == callback_object }
        else
            log ("Trying to remove event not registered in Game. #{object.name}, #{event}, #{callback_object.name}")
        end
        if @responders.dig(key, event) && @responders.dig(key, event).empty?
            @responders[key].delete(event)
        end
        if @responders.dig(key) && @responders.dig(key).empty?
            @responders.delete(key)
        end
    end
    
    #
    # Adds a GameObject to the game.
    #
    # @param [GameObject] gameobject The GameObject to add.
    #
    # @return [nil]
    #
    def add_gameobject(gameobject)
        @gameobjects_by_uuids[gameobject.uuid] = gameobject
        return
    end

    #
    # Removes a GameObject from the game.
    #
    # @param [GameObject] gameobject The GameObject to remove.
    #
    # @return [nil]
    #
    def remove_gameobject(gameobject)
        @gameobjects_by_uuids.delete(gameobject.uuid)
        return
    end

    #
    # Adds an item to the game. Add it to the master list (@items) and 
    # also add it and its keywords to @item_keyword_map. All items should 
    # be added in this way.
    #
    # @param [Item] item The item to add.
    #
    # @return [nil]
    #
    def add_global_item(item)
        @items.add(item)
        if item.keywords
            item.keywords.symbols.each do |symbol|
                if !@item_keyword_map[symbol]
                    @item_keyword_map[symbol] = [item]
                else
                    @item_keyword_map[symbol] << item
                end
            end
        end
        return
    end

    #
    # Removes an item from the game. Remove it from the master list (@items) and 
    # also remove it and its keywords from @item_keyword_map. All items should 
    # be removed in this way.
    #
    # @param [Item] item The item to remove.
    #
    # @return [nil]
    #
    def remove_global_item(item)
        @items.delete(item)
        if item.keywords
            item.keywords.symbols.each do |symbol|
                if @item_keyword_map.has_key?(symbol)
                    @item_keyword_map[symbol].delete(item)
                    if @item_keyword_map[symbol].size == 0
                        @item_keyword_map.delete(symbol)
                    end
                end
            end
        end
        return
    end

    #
    # Adds a mobile to the game. Add it to the master list (@mobiles) and 
    # also add it and its keywords to @mobile_keyword_map. All mobiles should 
    # be added in this way.
    #
    # @param [Mobile] mobile The mobile to add.
    #
    # @return [nil]
    #
    def add_global_mobile(mobile)
        @mobiles.add(mobile)
        if mobile.keywords
            mobile.keywords.symbols.each do |symbol|
                if !@mobile_keyword_map[symbol]
                    @mobile_keyword_map[symbol] = [mobile]
                else
                    @mobile_keyword_map[symbol] << mobile
                end
            end
        end
        return
    end

    #
    # Removes a mobile from the game. Remove it from the master list (@mobiles) and 
    # also remove it and its keywords from @mobile_keyword_map. All mobiles should 
    # be removed in this way.
    #
    # @param [Mobile] mobile The mobile to remove.
    #
    # @return [nil]
    #
    def remove_global_mobile(mobile)
        @mobiles.delete(mobile)
        if mobile.keywords
            mobile.keywords.symbols.each do |symbol|
                if @mobile_keyword_map.has_key?(symbol)
                    @mobile_keyword_map[symbol].delete(mobile)
                    if @mobile_keyword_map[symbol].size == 0
                        @mobile_keyword_map.delete(symbol)
                    end
                end
            end
        end
        return
    end

    #
    # Adds a mobile to the array of combat mobiles, adding it to combat logic.
    #
    # @param [Mobile] mobile The mobile to add.
    #
    # @return [nil]
    #
    def add_combat_mobile(mobile)
        @combat_mobs.add(mobile)
        return
    end

    #
    # Removes a mobile from the array of combat mobiles, removing it from combat logic.
    #
    # @param [Mobile] mobile The mobile to remove.
    #
    # @return [nil]
    #
    def remove_combat_mobile(mobile)
        @combat_mobs.delete(mobile)
        return
    end

    #
    # Adds a mobile to the array of regen mobiles, giving it round-based regeneration.
    #
    # @param [Mobile] mobile The mobile to add.
    #
    # @return [nil]
    #
    def add_regen_mobile(mobile)
        @regen_mobs.add(mobile)
        return
    end

    #
    # Removes a mobile from the array of regen mobiles, removing the need to call combat_regen
    # on it.
    #
    # @param [Mobile] mobile The mobile to remove.
    #
    # @return [nil]
    #
    def remove_regen_mobile(mobile)
        @regen_mobs.delete(mobile)
        return
    end

    #
    # Adds a GameObject to the array of cooldown objects. Cooldown objects are checked every frame
    # to remove finished cooldowns.
    #
    # @param [GameObject] gameobject The object to add.
    #
    # @return [nil]
    #
    def add_cooldown_object(gameobject)
        @cooldown_objects.add(gameobject)
        return
    end

    #
    # update objects with pending cooldowns.
    # They remove themselves when all cooldowns are cleared.
    #
    # @return [nil]
    #
    def handle_cooldown_objects
        new_cooldown_objects = []
        @cooldown_objects.each do |gameobject|
            if gameobject.update_cooldowns(@frame_time)
                new_cooldown_objects << gameobject
            end
        end
        @cooldown_objects = new_cooldown_objects
        return
    end

    # -- Affect/GameObject removal --

    #
    # Removes an affect from Game. Manages removal from inactive player source affects, as well.
    #
    # @param [Affect] affect The affect to remove.
    #
    # @return [nil]
    #
    def remove_affect(affect)
        if affect.clear_time
            remove_timed_affect(affect)
        end
        source = affect.source
        if source && source.is_a?(Player) && @inactive_player_source_affects.dig(source.id)
            @inactive_player_source_affects[source.id].delete(affect)
            if @inactive_player_source_affects[source.id].size == 0
                @inactive_player_source_affects.delete(source.id)
            end
        end
        return
    end

    #
    # Removes a Continent from Game. Should only be called from Continent#destroy.
    #
    # @param [Continent] continent The continent to remove.
    #
    # @return [nil]
    #
    def remove_continent(continent)
        @continents.delete(continent.id)
        return
    end

    #
    # Removes an Area from Game. Should only be called from Area#destroy.
    #
    # @param [Area] area The area to remove.
    #
    # @return [nil]
    #
    def remove_area(area)
        @areas.delete(area.id)
        return
    end

    #
    # Removes a Room from Game. Should only be called from Room#destroy.
    #
    # @param [Room] room The room to remove.
    #
    # @return [nil]
    #
    def remove_room(room)
        @rooms.delete(room.id)
        return
    end

    #
    # Removes a Mobile from Game. Should only be called from Mobile#destroy.
    #
    # @param [Mobile] mobile The mobile to remove.
    #
    # @return [nil]
    #
    def remove_mobile(mobile)
        remove_global_mobile(mobile)
        @mobiles.delete(mobile)
        return
    end

    #
    # Removes a Player from Game. Should only be called from Player#destroy.
    #
    # @param [Player] player The player to remove.
    #
    # @return [nil]
    #
    def remove_player(player)
        if player.source_affects.size > 0
            @inactive_player_source_affects[player.id] = player.source_affects
        end
        @players.delete(player)
        return
    end

    #
    # Removes an Item from Game. Should only be called from Item#destroy.
    #
    # @param [Item] item The item to remove.
    #
    # @return [nil]
    #
    def remove_item(item)
        remove_global_item(item)
        return
    end

    #
    # String representation of the Game object. This exists mainly to prevent infinite loops
    # in older code. Probably not necessary now.
    #
    # @return [String] "GAME INSTANCE"
    #
    def inspect
        "GAME INSTANCE"
    end

    #
    # Returns in-game time.
    #
    # @return [Array<Integer>] The time
    #
    def time
        hour = ( @frame_count / Constants::Interval::TICK ).to_i
        day = ( hour / 24 ).to_i
        year = 1 + ( day / ( 30 * Constants::Time::MONTHS.count )).to_i
        return [ hour, day, year ]
    end

    #
    # Returns true if in-game time is sometime during the day (between sunrise and sunset). 
    #
    # @return [Boolean] True if the time is day.
    #
    def daytime?
        time.first.between?(Constants::Time::SUNRISE, Constants::Time::SUNSET)
    end

    #
    # Handles the changing of the weather/time of day.
    #
    # @return [nil]
    #
    def weather
        # just day/night messages at the moment
        if time.first == Constants::Time::SUNRISE
            @players.each_output "The sun rises in the east."
        elsif time.first == Constants::Time::SUNRISE + 1
            @players.each_output "The day has begun."
        elsif time.first == Constants::Time::SUNSET
            @players.each_output "The sun slowly disappears in the west."
        elsif time.first == Constants::Time::SUNSET + 1
            @players.each_output "The night has begun."
        end
        return nil
    end

    #
    # The server input loop runs on its own thread, taking input from the console window
    # and performing commands with them.
    #
    # @return [nil]
    #
    def server_input_loop
        while !@shutdown
            input = gets.chomp.to_s
            cmd, args = input.sanitize.split(" ", 2)

            command = find_server_commands( cmd.to_s ).last

            if command.nil?
                log "Huh?"
            else
                command.attempt(nil, cmd, args.to_s.to_args, input)
            end
        end
        return
    end

    #
    # Returns server commands matching a given command keyword.
    #
    # @param [String, Symbol] cmd The command keyword.
    #
    # @return [Array<Command>] The matches.
    #
    def find_server_commands( cmd )
        matches = @server_commands.select { |command| command.keywords.include?( cmd.to_sym ) }.sort_by(&:priority)
        return matches
    end

    #
    # Initiates a reload from the database.
    #
    # @return [nil]
    #
    def initiate_reload
        @reload = true
        return
    end

    #
    # allows the server to shut down
    #
    # @return [nil]
    #
    def initiate_stop
        @shutdown = true
        return
    end

end
