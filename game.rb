require 'sequel'
require 'logger'
require_relative 'game_setup'
require_relative 'game_save'

class Game

    attr_accessor :mobiles
    attr_accessor :mobile_count
    attr_accessor :items
    attr_reader :race_data
    attr_reader :class_data
    attr_reader :equip_slot_data
    attr_reader :affects
    attr_reader :help_data
    attr_reader :spells
    attr_reader :continents
    attr_reader :game_settings
    attr_reader :saved_player_data
    attr_reader :account_data
    attr_reader :new_accounts
    attr_reader :new_players
    attr_reader :players
    attr_reader :logging_players
    attr_reader :client_account_ids
    attr_reader :rooms
    attr_reader :frame_count

    include GameSetup
    include GameSave

    def initialize
        @server = nil                       # TCPServer object
        @db = nil                           # Sequel database connection
        @started = false                    # Boolean: start has been called?
        @next_uuid = 1                      # Next available UUID for a GameObject. Overridden with value from game_settings
        @start_time = nil                   # Time the server actually began running/accepting players
        @frame_count = 0                    # Frame count - goes up by 1 every frame (:
        @starting_room = nil                # The room that players log in to - currently gets set in make_rooms

        # Database tables
        @game_settings = Hash.new           # Hash with values for next_uuid, login_splash, etc
        @race_data = Hash.new               # Race table as array      (uses :id as key)
        @class_data = Hash.new              # Class table as array     (uses :id as key)
        @equip_slot_data = Hash.new         # equip_slot table as hash (uses :id as key)
        @continent_data = Hash.new          # Continent table as hash  (uses :id as key)
        @area_data = Hash.new               # Area table as hash       (uses :id as key)
        @room_data = Hash.new               # Room table as hash       (uses :id as key)
        @exit_data = Hash.new               # Room exit table as hash  (uses :id as key)
        @room_description_data = Hash.new   # Room desc rable as hash  (uses :id as key)
        @mobile_data = Hash.new             # Mobile table as hash     (uses :id as key)
        @item_data = Hash.new               # Item table as hash       (uses :id as key)
        @item_modifiers = Hash.new
        @ac_data = Hash.new                 # Item subtables           (use :item_id as key)
        @weapon_data = Hash.new
        @container_data = Hash.new
        @shop_data = Hash.new               # Shop table as hash       (uses :id as key)
        @skill_data = Hash.new              # Skill table as hash      (uses :id as key)
        @spell_data = Hash.new              # Spell table as hash      (uses :id as key)
        @command_data = Hash.new            # Command table as hash    (uses :id as key)

        @base_reset_data = Hash.new             # Reset table as hash           (uses :id as key)
        @mob_reset_data = Hash.new              # Mob reset table as hash       (uses :reset_id as key)
        @inventory_reset_data = Hash.new        # Inventory reset table as hash (uses :reset_id as key)
        @equipment_reset_data = Hash.new        # Equipment reset table as hash (uses :reset_id as key)
        @container_reset_data = Hash.new        # Container reset table as hash (uses :reset_id as key)
        @room_item_reset_data = Hash.new        # Room item reset table as hash (uses :reset_id as key)
        @base_mob_reset_data = Hash.new         # Subset of @base_reset_data where :type is "mobile"
        @base_room_item_reset_data = Hash.new   # Subset of @base_reset_data where :type is "room_item"

        @saved_player_id_max = 0                # max id in database table saved_player_base
        @saved_player_affect_id_max = 0         # max id in database table saved_player_affect
        @saved_player_item_id_max = 0           # max id in database table saved_player_item
        @saved_player_item_affect_id_max = 0    # max id in database table saved_player_item_affect

        @help_data = Hash.new                   # Help table as hash  (uses :id as key)
        @account_data = Hash.new                # Account table as hash (uses :id  as key)
        @saved_player_data = Hash.new           # Saved player table as hash    (uses :id as key)


        # GameObjects
        @continents = Hash.new              # Continent objects as hash   (uses :id as key)
        @areas = Hash.new                   # Area objects as hash        (uses :id as key)
        @rooms = Hash.new                   # Room objects as hash        (uses :id as key)

        @client_account_ids = []            # Account IDs of connected clients
        @new_accounts = []                  # Accounts waiting to be created - added to from client threads
        @new_players = []                   # Players waiting to be created - added to from client threads
        @players = []                       # players online - array
        @inactive_players = Hash.new        # inactive players - they've logged but not been garbage collected yet
        @logging_players = []               # ids of players waiting to be added to the game
        @quitting_players = []              # players who have placed themselves here are to be quit
        @items = Set.new
        @item_count = Hash.new
        @mobiles = Set.new
        @mobile_count = Hash.new

        @combat_mobs = Set.new
        @regen_mobs = Set.new

        @item_keyword_map = Hash.new
        @mobile_keyword_map = Hash.new

        @affects = Set.new                  # Master list of all applied affects in the game
        @skills = []                        # Skill object array
        @spells = []                        # Spell object array
        @commands = []                      # Command object array

        @responders = Hash.new                  # Event responders
        @responder_maintenance_count = 0        # current maintenance count
        @responder_maintenance_per_frame = 20   # number of responders that are cleaned per frame

    end

    def game_loop
        total_time = 0
        loop do
            start_time = Time.now
            @frame_count += 1

            before = Time.now
            # insert into the database any new accounts waiting
            @new_accounts.each do |account_data|
                save_new_account(account_data)
                @new_accounts.delete(account_data)
            end
            after = Time.now
            log "{gNew accounts:{x #{after - before}" if $VERBOSE

            before = Time.now
            # insert into the database any new players waiting
            @new_players.each do |player_data|
                save_new_player(player_data)
                @new_players.delete(player_data)
            end
            after = Time.now
            log "{gNew players:{x #{after - before}" if $VERBOSE

            before = Time.now
            # deal with inactive players that have been garbage collected
            # p "#{@frame_count} #{@inactive_players.keys}" if @inactive_players.length > 0
            @inactive_players.each do |name, player|
                if !player.weakref_alive?
                    @inactive_players.delete(name)
                    puts "#{name} has been deleted from memory."
                end
            end
            after = Time.now
            log "{gInactive players:{x #{after - before}" if $VERBOSE

            before = Time.now
            # load any players whose ids have been added to the logging_players queue
            @logging_players.each do |player_id, client|
                @logging_players.delete([player_id, client])
                player = nil
                if (player = @players.select{ |p| p.id == player_id }.first) # found in online player
                    player.reconnect(client)
                elsif (player = @inactive_players.values.select { |p| p.weakref_alive? && p.id == player_id }.first)
                    player = player.__getobj__             # found in inactive player
                    @inactive_players.delete(player.name)
                    player.reconnect(client)
                elsif (player = load_player(player_id, client) )
                    # load player normally - nothing else to do, maybe!
                end
                if player
                    @players.unshift(player)
                end
            end
            after = Time.now
            log "{gLogging players:{x #{after - before}" if $VERBOSE

            # save every so often!
            # add one to the frame_count so it doesn't save on combat frames, etc
            if (@frame_count + 1) % Constants::Interval::AUTOSAVE == 0
                before = Time.now
                save
                after = Time.now
                log "{gSave:{x #{after - before}" if $VERBOSE
            end


            # each combat ROUND
            if @frame_count % Constants::Interval::ROUND == 0
                before = Time.now
                combat
                after = Time.now
                log "{gCombat:{x #{after - before}" if $VERBOSE
            end

            if @frame_count % Constants::Interval::TICK == 0
                before = Time.now
                tick
                after = Time.now
                # if @frame_count != 0
                #     Thread.start do
                #         GC.start
                #     end
                # end
                log "{gTick:{x #{after - before}" if $VERBOSE
            end

            if @frame_count % Constants::Interval::REPOP == 0
                before = Time.now
                repop
                after = Time.now
                log "{gRepop:{x #{after - before}" if $VERBOSE
            end
            before = Time.now
            update( 1.0 / Constants::Interval::FPS )
            after = Time.now
            log "{gUpdate:{x #{after - before}" if $VERBOSE
            # responder_maintenance
            send_to_client
            end_time = Time.now
            loop_computation_time = end_time - start_time
            sleep_time = ((1.0 / Constants::Interval::FPS) - loop_computation_time)
            total_time += loop_computation_time
            log "{rTotal:{x #{end_time - start_time}" if $VERBOSE
            puts "" if $VERBOSE
            # puts "#{sleep_time.to_s.ljust(22)} #{loop_computation_time.to_s.ljust(22)} #{(sleep_time - loop_computation_time > 0).to_s.ljust(22)} #{total_time / @frame_count}"
            if sleep_time < 0                   # Sleep until the next frame, if there's time leftover
                log ("Negative sleep time detected: {c#{sleep_time}{x")
            else
                sleep(sleep_time)
            end
        end
    end

    def profile color, message, verbose = false
        log "#{color}<<<<<<<<<<<<<<<<<<<<<<<<<<<< #{message} >>>>>>>>>>>>>>>>>>>>>>>>{x"
        ObjectSpace.each_object.inject(Hash.new 0) { |h,o| h[o.class] += 1; h }.sort_by { |k,v| -v }.take(5).each { |klass, count| log "#{count.to_s.ljust(10)} #{klass}" }
        MemoryProfiler.start
        yield
        report = MemoryProfiler.stop

        if verbose
            report.pretty_print
        end
        
        log "ALLOCATED #{ ( report.total_allocated_memsize / 10000 ) / 100.0 } MB"
        log "RETAINED #{ ( report.total_retained_memsize / 10000 ) / 100.0 } MB"
    end

    # eventually, this will handle all game logic
    def update( elapsed )
        @players.each do | player |
            # player.update(elapsed)
            player.process_commands(elapsed)
        end
        # @mobiles.each do | mobile |
        #     mobile.update(elapsed)
        # end
        # @items.each do | item |
        #     item.update(elapsed)
        # end
        # @rooms.values.each do | room |
        #     room.update(elapsed)
        # end
        # @areas.values.each do | area |
        #     area.update(elapsed)
        # end
        # @affects.each do |affect|
        #     affect.update(elapsed)
        # end
        # @continents.values.each do | continent |
        #     continent.update(elapsed)
        # end
        affects = @affects.to_a
        affects.each do |affect|
            if affect.active
                affect.update(elapsed)
            else
                @affects.delete(affect)
            end
        end
    end

    def send_to_client
        @players.each do | player |
            player.send_to_client
        end
    end

    def combat
        @combat_mobs.to_a.each do |mob|
            mob.combat
        end
    end

    def broadcast( message, targets, objects = [], send_to_sleeping: false )
        if !send_to_sleeping
            targets.reject!{ |t| t.respond_to?(:position) && t.position == Constants::Position::SLEEP }
        end
        targets.each do | player |
            player.output( message, objects.to_a )
        end
    end

    def target( query = {} )
        targets = []
        if query[:list]
            targets = query[:list].reject(&:nil?) # got a crash here once but don't know why - maybe a bad list passed in?
            if query[:type]
                targets -= targets.select { |t| Area === t }      if !query[:type].to_a.include?("Area")
                targets -= targets.select { |t| Continent === t } if !query[:type].to_a.include?("Continent")
                targets -= targets.select { |t| Player === t }    if !query[:type].to_a.include?("Player")
                targets -= targets.select { |t| Item === t }      if !query[:type].to_a.include?("Item")
                targets -= targets.select { |t| Mobile === t }    if !query[:type].to_a.include?("Mobile")
            end
        elsif query[:type]
            targets += @areas.values       if query[:type].to_a.include? "Area"
            targets += @continents.values  if query[:type].to_a.include? "Continent"
            targets += @players            if query[:type].to_a.include? "Player"
            if query[:type].to_a.include? "Item"
                items = @items.to_a
                # items = items.reject{ |item| !item.active }
                targets += items
            end
            targets += @mobiles.to_a       if query[:type].to_a.include? "Mobile"

        else
            targets = @areas.values + @players + @items.to_a + @mobiles.to_a
        end

        targets = targets.select { |t| t.uuid == query[:uuid] }                                                     if query[:uuid]
        targets = targets.select { |t| query[:affect].to_a.any?{ |affect| t.affected?( affect.to_s ) } }            if query[:affect]
        targets = targets.select { |t| t.type == query[:item_type] }                                                if query[:item_type]
        targets = targets.select { |t| !query[:not].to_a.include? t }                                               if query[:not]
        targets = targets.select { |t| query[:attacking].to_a.include? t.attacking }                                if query[:attacking]
        targets = targets.select { |t| t.fuzzy_match( query[:keyword] ) }                                           if query[:keyword]
        targets = targets.select { |t| query[:visible_to].can_see? t }                                              if query[:visible_to]
        targets = targets.select { |t| query[:where_to].can_where? t }                                              if query[:where_to]

        targets = targets[0...query[:limit].to_i]                                                                   if query[:limit]

        query[:offset] == "all" || query[:offset].nil? ? offset = 0 : offset = [0, query[:offset].to_i - 1].max
        query[:offset] == "all" || query[:quantity] == "all" || query[:quantity].nil? ? quantity = targets.length : quantity = [1, query[:quantity].to_i].max

        targets = targets[ offset...offset+quantity ].to_a

        return targets
    end

    def target_global_items(query)
        targets = []
        query[:keyword].each do |keyword|
            if @item_keyword_map[keyword]
                if targets.length > 0
                    targets = targets & @item_keyword_map[keyword].to_a
                else
                    targets = @item_keyword_map[keyword].to_a
                end
            end
        end
        return targets
    end

    def target_global_mobiles(query)
        targets = []
        query[:keyword].each do |keyword|
            if @mobile_keyword_map[keyword]
                if targets.length > 0
                    targets = targets & @mobile_keyword_map[keyword].to_a
                else
                    targets = @mobile_keyword_map[keyword].to_a
                end
            end
        end
        return targets
    end

    def tick
        log "{YTick!{x"
        broadcast("{MMud newbies 'Hi everyone! It's a tick!!'{x", @players, send_to_sleeping: true)
        
        # player tick is called, just to allow for some regen!!
        ( @players ).each do | entity |
            entity.tick
        end

        weather
    end

    def repop
        @base_mob_reset_data.each do |reset_id, reset_data|
            reset = @mob_reset_data[reset_id]
            if !reset
              log "[Reset not found] RESET ID: #{reset_id}"
            elsif @mob_data[ reset[:mobile_id] ]
                if @mobile_count[ reset[:mobile_id] ].to_i < reset[:world_max] && @rooms[reset[:room_id]].mobile_count[reset[:mobile_id]].to_i < reset[:room_max]
                    mob = load_mob( reset[:mobile_id], @rooms[ reset[:room_id] ] )
                    
                    # @mobiles.add(mob)
                    add_global_mobile(mob)

                    @mobile_count[ reset[:mobile_id] ] = @mobile_count[ reset[:mobile_id] ].to_i + 1

                    # inventory
                    @inventory_reset_data.select{ |id, inventory_reset| inventory_reset[:parent_id] == reset_id }.each do | item_reset_id, item_reset |
                        if @item_data[ item_reset[:item_id] ]                          

                            item = load_item( item_reset[:item_id], mob.inventory )
                            #containers
                            if Container === item
                                @container_reset_data.select{ |id, container_reset| container_reset[:parent_id] == item_reset_id }.each do |container_item_reset_id, container_item_reset|
                                    if @item_data[ container_item_reset[:item_id] ]
                                        [1, container_item_reset[:quantity]].max.times do
                                            container_item = load_item( container_item_reset[:item_id], item.inventory )
                                        end
                                    else
                                        log "[Container item not found] RESET ID: #{item_reset_id}, ITEM ID: #{item_reset[:item_id]}, AREA: #{@base_reset_data[item_reset_id][:area_id]}"
                                    end
                                end
                            end
                        else
                            log "[Inventory item not found] RESET ID: #{item_reset_id}, ITEM ID: #{item_reset[:item_id]}, AREA: #{@areas[@base_reset_data[item_reset_id][:area_id]]}"
                        end
                    end

                    #equipment
                    @equipment_reset_data.select{ |id, equipment_reset| equipment_reset[:parent_id] == reset_id }.each do | item_reset_id, item_reset |
                        if @item_data[ item_reset[:item_id] ]
                            item = load_item( item_reset[:item_id], mob.inventory )
                            mob.wear(item: item, silent: true)
                            #containers
                            if Container === item
                                @container_reset_data.select{ |id, container_reset| container_reset[:parent_id] == item_reset_id }.each do |container_item_reset_id, container_item_reset|
                                    if @item_data[ container_item_reset[:item_id] ]
                                        [1, container_item_reset[:quantity]].max.times do
                                            container_item = load_item( container_item_reset[:item_id], item.inventory )
                                        end
                                    else
                                        log "[Container item not found] RESET ID: #{item_reset_id}, ITEM ID: #{item_reset[:item_id]}, AREA: #{@base_reset_data[item_reset_id][:area_id]}"
                                    end
                                end
                            end
                        else
                            log "[Equipped item not found] RESET ID: #{item_reset_id}, ITEM ID: #{item_reset[:item_id]}, AREA: #{@base_reset_data[item_reset_id][:area_id]}"
                        end
                    end

                end
            else
                log "[Mob not found] RESET ID: #{reset[:id]}, MOB ID: #{reset[:mobile_id]}"
            end
        end

        @base_room_item_reset_data.each do |reset_id, reset_data|
            if ( reset = @room_item_reset_data[reset_id] )
                if @rooms[reset[:room_id]].inventory.item_count[reset[:item_id]].to_i < 1
                    load_item( reset[:item_id], @rooms[ reset[:room_id] ].inventory )
                end
            else
                log ["Room item reset not found] RESET ID: #{reset_id}"]
            end
        end
    end

    def load_mob( id, room )
        row = @mob_data[ id ]
        race_matches = @race_data.select{ |k, v| v[:name] == row[:race] }
        race_id = 0
        if race_matches.any?
            race_id = race_matches.first[0]
        end
        mob = Mobile.new( {
                id: id,
                keywords: row[:keywords].split(" "),
                short_description: row[:short_desc],
                long_description: row[:long_desc],
                full_description: row[:full_desc],
                race_id: race_id,
                action_flags: row[:act_flags],
                affect_flags: row[:affect_flags],
                alignment: row[:align].to_i,
                # mobgroup??
                hitroll: row[:hitroll].to_i,
                hitpoints: dice( row[:hp_dice_count].to_i, row[:hp_dice_sides].to_i ) + row[:hp_dice_bonus].to_i,
                #hp_range: row[:hpRange].split("-").map(&:to_i), # take lower end of range, maybe randomize later?
                hp_range: [500, 1000],
                # mana: row[:manaRange].split("-").map(&:to_i).first,
                manapoints: dice( row[:mana_dice_count].to_i, row[:mana_dice_sides].to_i ) + row[:mana_dice_bonus].to_i,
                movepoints: 100,
                #damage_range: row[:damageRange].split("-").map(&:to_i),
                # damage_range: [10, 20],
                damage_dice_sides: row[:damage_dice_sides].to_i,
                damage_dice_count: row[:damage_dice_count].to_i,
                damage_dice_bonus: row[:damage_dice_bonus].to_i,
                hand_to_hand_noun: row[:hand_to_hand_noun], # pierce, slash, none, etc.
                ac: [row[:ac_pierce], row[:ac_bash], row[:ac_slash], row[:ac_magic]],
                offensive_flags: row[:off_flags],
                immune_flags: row[:immune_flags],
                resist_flags: row[:resist_flags],
                vulnerable_flags: row[:vuln_flags],
                starting_position: row[:start_position],
                default_position: row[:default_position],
                sex: row[:sex],
                wealth: row[:wealth].to_i,
                form_flags: row[:form_flags],
                specials: row[:specials],
                parts: row[:part_flags],
                size: row[:size],
                material: row[:material],
                level: row[:level]
            },
            self,
            room
        )
        #
        # "Shopkeeper behavior" is handled as an affect, which is currently used only as a kind of 'flag' for the buy/sell commands
        #
        if not @shop_data[ id ].nil?
            mob.apply_affect( AffectShopkeeper.new( source: mob, target: mob, level: 0, game: self ) )
        end
        return mob
    end

    def load_item( id, inventory )
        item = nil
        if ( row = @item_data[ id ] )
            data = {
                id: id,
                short_description: row[:short_desc],
                long_description: row[:long_desc],
                keywords: row[:keywords].split(" "),
                weight: row[:weight].to_i,
                cost: row[:cost].to_i,
                type: row[:type],
                level: row[:level].to_i,
                wear_location: row[:wear_flags].match(/(wear_\w+|wield|hold|light)/).to_a[1].to_s.gsub("wear_", ""),
                wear_flags: row[:wear_flags].split(","),
                material: row[:material],
                extra_flags: row[:extra_flags].to_s.split(","),
                modifiers: {},
                ac: @ac_data[ id ].to_h.reject{ |k, v| [:id, :item_id].include?(k) }
            }
            @item_modifiers[ id ].to_a.each do |modifier|
                data[:modifiers][ modifier[:field].to_sym ] = modifier[:value]
            end
            if row[:type] == "weapon"
                weapon_info = @weapon_data[ id ]
                if weapon_info
                    weapon_data = {
                        noun: weapon_info[:noun],
                        genre: weapon_info[:type],
                        flags: weapon_info[:flags].split(","),
                        element: weapon_info[:element],
                        dice_sides: weapon_info[:dice_sides].to_i,
                        dice_count: weapon_info[:dice_count].to_i
                    }
                    item = Weapon.new( data.merge( weapon_data ), self, inventory )
                else
                    log "[Weapon and/or Dice data not found] ITEM ID: #{id}"
                    item = Item.new( data, self, inventory )
                end
            elsif row[:type] == "container"
                container_info = @container_data[ id ]
                if container_info
                    container_data = {
                        flags: container_info[:flags],
                        max_item_weight: container_info[:max_item_weight].to_i,
                        weight_multiplier: container_info[:weight_multiplier].to_f,
                        max_total_weight: container_info[:max_total_weight].to_i,
                        key_id: container_info[:key_id].to_i,
                    }
                    item = Container.new( data.merge( container_data ), self, inventory )
                else
                    log "[Container data not found] ITEM ID: #{id}"
                    item = Item.new( data, self, inventory )
                end
            else
                item = Item.new( data, self, inventory )
            end

            if not @portal_data[ id ].nil?
                # portal = AffectPortal.new( source: nil, target: item, level: 0, game: self )
                # portal.overwrite_modifiers({ destination: @rooms[ @portal_data[id][:to_room_id] ] })
                item.apply_affect( AffectPortal.new( target: item, game: self, destination: @rooms[ @portal_data[id][:to_room_id] ] ) )
            end

            if item
                add_global_item(item)
                return item
            else
                log "[Item creation unsuccessful]"
                return nil
            end
        else
            log "load_item [ITEM NOT FOUND] Item ID: #{ id }"
        end
    end

    def do_command( actor, cmd, args = [], input = cmd )
        matches = (
            @commands.select { |command| command.check( cmd ) } +
            @skills.select{ |skill| skill.check( cmd ) && actor.knows( skill.to_s ) }
        ).sort_by(&:priority)

        if matches.any?
            matches.last.execute( actor, cmd, args, input )
            return
        end

    	actor.output "Huh?"
    end

    def recall_room( continent )
        return @rooms[continent.recall_room_id]
    end

    # Send an event to a list of objects
    #
    # Examples:
    #  fire_event(some_mobile, :event_test, {})
    #  fire_event(some_mobile, :event_on_hit, data)
    def fire_event(object, event, data)
        if !( r = @responders.dig(object.uuid, event) )
            return
        end
        r.each do |callback_object, callback, priority|
            callback_object.send(callback, data)
        end
    end

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
    end

    def remove_event_listener(object, event, callback_object)
        key = object.uuid
        if @responders.dig(key, event)
            @responders[key][event].reject!{ |t| t[0] == callback_object }
        else
            log ("Trying to remove event not registered in Game.")
        end
        if @responders.dig(key, event) && @responders.dig(key, event).empty?
            @responders[key].delete(event)
        end
        if @responders.dig(key) && @responders.dig(key).empty?
            @responders.delete(key)
        end
    end

    def add_global_item(item)
        @items.add(item)
        item.keywords.each do |keyword|
            if !@item_keyword_map[keyword]
                @item_keyword_map[keyword] = Set.new([item])
            else
                @item_keyword_map[keyword].add(item)
            end
        end
    end


    def remove_global_item(item)
        @items.delete(item)
        item.keywords.each do |keyword|
            if @item_keyword_map[keyword]
                @item_keyword_map[keyword].delete(item)
                if @item_keyword_map[keyword].size == 0
                    @item_keyword_map.delete(keyword)
                end
            end
        end
    end

    def add_global_mobile(mobile)
        @mobiles.add(mobile)
        mobile.keywords.each do |keyword|
            if !@mobile_keyword_map[keyword]
                @mobile_keyword_map[keyword] = Set.new([mobile])
            else
                @mobile_keyword_map[keyword].add(mobile)
            end
        end
    end

    def remove_global_mobile(mobile)
        @mobiles.delete(mobile)
        mobile.keywords.each do |keyword|
            if @mobile_keyword_map[keyword]
                @mobile_keyword_map[keyword].delete(mobile)
                if @mobile_keyword_map[keyword].size == 0
                    @mobile_keyword_map.delete(keyword)
                end
            end
        end
    end

    def add_global_affect(affect)
        if !affect.permanent || affect.period
            @affects.add(affect)
        end
    end

    def remove_global_affect(affect)
        @affects.delete(affect)
    end

    def add_combat_mobile(mobile)
        @combat_mobs.add(mobile)
    end

    def remove_combat_mobile(mobile)
        @combat_mobs.delete(mobile)
    end

    # Object removal methods:
    #
    # objects passed to these methods will be allowed to be garbage collected, provided they are not
    # the source of any remaining affects in the game.
    #
    # Calling destroy_mobile does NOT call destroy_item on the mobile's items
    # figure out what to do with continents/areas/rooms?
    #

    # destroy a continent object
    def destroy_continent(continent)
        continent.affects.each do |affect|
            remove_global_affect(affect)
        end
        areas = @areas.select{ |area| area.continent == continent}
        areas.each do |area|
            destroy_area(area)
        end
        @continents.delete(continent.id)
    end

    def new_inactive_continent
        data = {
            name: "inactive continent",
            id: 0,
            preposition: "on",
            recall_room_id: 0,
            starting_room_id: 0
        }
        return Continent.new(data, self)
    end

    # destroy an area object
    def destroy_area(area)
        area.affects.each do |affect|
            remove_global_affect(affect)
        end
        area.rooms.each do |room|
            destroy_room(room)
        end
        @areas.delete(area.id)
    end

    def new_inactive_area
        data = {
            name: "inactive area",
            age: 0,
            builders: "no builders",
            continent: self.new_inactive_continent,
            control: "no control",
            credits: "no credits",
            gateable: 0,
            id: 0,
            questable: 0,
            security: 0
        }
        return Area.new(data, self)
    end

    # destroy a room object
    def destroy_room(room)
        @rooms.each do |other_room| # remove exits that go to the room being destroyed
            other_room.exits.each do |direction, exit|
                if exit.desination == room
                    other_room[direction] = nil
                    # destroy exit object as well?
                end
            end
        end

        rooms.affects.each do |affect|
            remove_global_affect(affect)
        end
        room.mobiles.each do |mobile|
            destroy_mobile(mobile)
        end
        room.players.each do |player|
            player.move_to_room(@starting_room) # just move players out
        end
        room.inventory.items.each do |item|
            item.active = false
            item.affects.each do |affect|
                affect.active = false
            end
        end
        @rooms.delete(room.id)
    end

    def new_inactive_room
        return Room.new(0, "inactive room", "no description", "no sector",
                self.new_inactive_area, "", 0, 0, self)
    end

    # destroy a mobile object
    def destroy_mobile(mobile)
        mobile.move_to_room(self.new_inactive_room)
        mobile.deactivate
        mobile.affects.each do |affect|
            affect.active = false
        end
        mobile.items.each do |item|
            remove_global_item(item)
            item.affects.each do |affect|
                affect.active = false
            end
        end
        @mobile_count[mobile.id] = @mobile_count[mobile.id].to_i - 1
        @mobile_count.delete(mobile.id) if @mobile_count[mobile.id] <= 0
        @mobiles.delete(mobile)
    end

    # destroy a player object
    def destroy_player(player)
        @inactive_players[player.name] = WeakRef.new(player)
        player.room.mobile_exit(player)
        player.affects.each do |affect|
            affect.active = false
        end
        player.items.each do |item|
            remove_global_item(item)
            item.affects.each do |affect|
                affect.active = false
            end
        end
        player.deactivate
        @players.delete(player)
    end

    # destroy an item object
    def destroy_item(item)
        item.move(nil)          # remove its inventory references by moving it to a nil inventory
        item.active = false
        item.affects.each do |affect|
            affect.active = false
        end
    end

    def inspect
        "GAME OBJECT"
    end

    def time
        hour = ( @frame_count / Constants::Interval::TICK ).to_i
        day = ( hour / 24 ).to_i
        year = 1 + ( day / ( 30 * Constants::Time::MONTHS.count )).to_i
        return [ hour, day, year ]
    end

    def daytime?
        time.first.between?(Constants::Time::SUNRISE, Constants::Time::SUNSET)
    end

    def weather
        # just day/night messages at the moment
        if time.first == Constants::Time::SUNRISE
            broadcast "The sun rises in the east.", @players
        elsif time.first == Constants::Time::SUNRISE + 1
            broadcast "The day has begun.", @players
        elsif time.first == Constants::Time::SUNSET
            broadcast "The sun slowly disappears in the west.", @players
        elsif time.first == Constants::Time::SUNSET + 1
            broadcast "The night has begun.", @players
        end
    end

end
