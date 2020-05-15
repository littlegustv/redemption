require_relative 'game_lookups'
require_relative 'game_save'
require_relative 'game_setup'

class Game

    include GameLookups
    include GameSave
    include GameSetup
    include Singleton

    attr_reader :help_data
    attr_reader :social_data

    attr_reader :frame_time
    attr_reader :frame_count
    attr_reader :game_settings
    attr_reader :saved_player_data
    attr_reader :account_data
    attr_reader :new_accounts
    attr_reader :new_players
    attr_reader :players
    attr_reader :logging_players
    attr_reader :client_account_ids
    attr_reader :continents
    attr_reader :areas
    attr_reader :rooms
    attr_reader :skills
    attr_reader :spells
    attr_reader :abilities

    # models
    attr_reader :mobile_models
    attr_reader :item_models

    # data classes
    attr_reader :elements
    attr_reader :equip_slot_infos
    attr_reader :genders
    attr_reader :genres
    attr_reader :materials
    attr_reader :mobile_classes
    attr_reader :nouns
    attr_reader :positions
    attr_reader :races
    attr_reader :sectors
    attr_reader :sizes
    attr_reader :stats
    attr_reader :wear_locations

    def initialize
        @server = nil                       # TCPServer object
        @db = nil                           # Sequel database connection
        @started = false                    # Boolean: start has been called?
        @next_uuid = 1                      # Next available UUID for a GameObject.
        @frame_time = 0
        @frame_count = 0                    # Frame count - goes up by 1 every frame (:
        @starting_room = nil                # The room that players log in to - currently gets set in make_rooms

        # Database tables
        @game_settings = Hash.new           # Hash with values for next_uuid, login_splash, etc

        @saved_player_id_max = 0                # max id in database table saved_player_base
        @saved_player_affect_id_max = 0         # max id in database table saved_player_affect
        @saved_player_item_id_max = 0           # max id in database table saved_player_item
        @saved_player_item_affect_id_max = 0    # max id in database table saved_player_item_affect

        @shop_data = Hash.new               # Shop table as hash       (uses :mobile_id as key)
        @portal_data = Hash.new
        @help_data = Hash.new                   # Help table as hash  (uses :id as key)
        @social_data = Hash.new                 # Social table as hash (uses :id as key)
        @account_data = Hash.new                # Account table as hash (uses :id  as key)
        @saved_player_data = Hash.new           # Saved player table as hash    (uses :id as key)

        @affect_class_hash = Hash.new           # Affect classes as hash (uses :id as key)

        # Resets
        @mobile_resets = []                 # Mobile resets
        @item_resets = []
        @active_resets = []                 # Array of Resets waiting to pop - sorted by reset.pop_time (ascending)
        @initial_reset = true

        # Models
        @item_model_classes = Hash.new      # hash of item model classes - uses item_type_id as key
        @item_models = Hash.new             # hash of item models (uses :id as key)
        @mobile_models = Hash.new           # Hash of mobile models (uses :id as key)

        # Data Classes
        @elements =         Hash.new        # hash of damage element objects  (uses :id as key)
        @equip_slot_infos = Hash.new        # hash of the equip slot info objects
        @genders =          Hash.new
        @genres =           Hash.new        # hash of weapon genres           (uses :id as key)
        @materials =        Hash.new        # hash of materials               (uses :id as key)
        @mobile_classes =   Hash.new        # hash of mobile class objects    (uses :id as key)
        @nouns =            Hash.new        # hash of damage noun objects     (uses :id as key)
        @positions =        Hash.new        # hash of mobile positions        (uses :id as key)
        @races =            Hash.new        # hash of race objects            (uses :id as key)
        @sectors =          Hash.new        # hash of sector ObjectSpace      (uses :id as key)
        @sizes =            Hash.new        # hash of mobile sizes            (uses :id as key)
        @stats =            Hash.new        # hash of stats                   (uses :id as key)
        @wear_locations =   Hash.new        # hash of wear locations          (uses :id as key)

        # GameObjects
        @continents = Hash.new              # Continent objects as hash   (uses :id as key)
        @areas = Hash.new                   # Area objects as hash        (uses :id as key)
        @rooms = Hash.new                   # Room objects as hash        (uses :id as key)

        @client_account_ids = []            # Account IDs of connected clients
        @new_accounts = []                  # Accounts waiting to be created - added to from client threads
        @new_players = []                   # Players waiting to be created - added to from client threads
        @players = []                       # players online - array
        @clients = []                       # connected clients - array

        @inactive_player_source_affects = Hash.new

        @logging_players = []               # ids of players waiting to be added to the game
        @items = Set.new
        @mobiles = Set.new

        @combat_mobs = Set.new
        @regen_mobs = Set.new
        @cooldown_objects = Set.new

        @item_keyword_map = Hash.new
        @mobile_keyword_map = Hash.new

        @new_periodic_affects = Set.new
        @timed_affects = []
        @periodic_affects = []
        @skills = []                        # Skill object array
        @spells = []                        # Spell object array
        @commands = []                      # Command object array
        @server_commands = []

        @abilities = Hash.new

        @responders = Hash.new                  # Event responders

        @shutdown = false

    end

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
    end

    def slow_frame_diagnostic(loop_computation_time)
        percent_overage = (loop_computation_time * 100 / (1.0 / Constants::Interval::FPS) - 100).floor
        if $VERBOSE
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
    end

    def profile color, message, verbose = false

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
    end

    # eventually, this will handle all game logic
    def update
        @players.each do | player |
            player.process_commands
        end
        handle_periodic_affects
        handle_timed_affects
        handle_cooldown_objects
    end

    def combat
        @combat_mobs.to_a.each do |mob|
            mob.combat
        end
        @regen_mobs.to_a.each do |mob|
            mob.combat_regen
        end
    end

    def target( query = {} )
        targets = []
        if query[:list]
            targets = query[:list].reject(&:nil?) # got a crash here once but don't know why - maybe a bad list passed in?
            if query[:type]
                targets -= targets.select { |t| Area === t }      if !query[:type].to_a.include?(Area)
                targets -= targets.select { |t| Continent === t } if !query[:type].to_a.include?(Continent)
                targets -= targets.select { |t| Player === t }    if !query[:type].to_a.include?(Player)
                targets -= targets.select { |t| Item === t }      if !query[:type].to_a.include?(Item)
                targets -= targets.select { |t| Mobile === t }    if !query[:type].to_a.include?(Mobile)
            end
        elsif query[:type]
            targets += @areas.values       if query[:type].to_a.include? Area
            targets += @continents.values  if query[:type].to_a.include? Continent
            targets += @players            if query[:type].to_a.include? Player
            if query[:type].to_a.include? Item
                items = @items.to_a
                # items = items.reject{ |item| !item.active }
                targets += items
            end
            targets += @mobiles.to_a       if query[:type].to_a.include? Mobile

        else
            targets = @areas.values + @players + @items.to_a + @mobiles.to_a
        end

        targets = targets.select { |t| t.uuid == query[:uuid] }                                                     if query[:uuid]
        targets = targets.select { |t| query[:affect].to_a.any?{ |affect| t.affected?( affect.to_s ) } }            if query[:affect]
        targets = targets.select { |t| t.is_a?(query[:item_type]) }                                                 if query[:item_type]
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
        if rand(0..100) < 75
            @players.each_output("{MMud newbies '#{ Constants::Tips::TOPTIPS.sample }'{x", send_to_sleeping: true)
        end

        weather
    end

    ##
    # Add a new timed affect.
    # Affect will be cleared when its clear_time has come.
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
    end

    ##
    # Remove a timed affect early.
    # Affect will be removed from @timed_affects instantly.
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

    ##
    # Clear all affects whose clear_times have come.
    def handle_timed_affects
        index = @timed_affects.bsearch_index { |aff| aff.clear_time > @frame_time }
        # slice array where affects are supposed to be cleared up until
        @timed_affects.slice!(0...index).each do |aff|
            aff.clear
        end
    end

    ##
    # Add a new periodic affect.
    # Will be integrated into the @periodic_affect array in next Game#handle_periodic_affects.
    def add_periodic_affect(affect)
        if !affect.period
            log "Error: Trying to add affect #{affect.name} with no period as a periodic affect."
            puts caller[0..3]
            return
        end
        @new_periodic_affects.add(affect)
    end

    ##
    # Remove an affect from @periodic_affects and @new_periodic_affects
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

    ##
    # Handle affects with periodic methods
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
            aff.update
        end
    end

    ## Activate a reset.
    # _Called only by the reset itself_
    def activate_reset(reset)
        index = @active_resets.bsearch_index { |r| r.pop_time >= reset.pop_time }
        if index
            @active_resets.insert(index, reset)
        else
            @active_resets << reset
        end
    end

    ## Handle resets.
    # Iterate through resets, popping each until resets not ready to pop are found.
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
            if @frame_time >= reset.pop_time
                @active_resets.shift
                if reset.success?
                    reset.pop
                end
            else
                # stop trying to reset, all resets in loop after here are in the future!
                break
            end
        end
    end

    def load_mob( model_or_id, room, reset = nil )
        model = (model_or_id.is_a?(Integer)) ? @mobile_models.dig(model_or_id) : model_or_id
        if !model.is_a?(MobileModel)
            log "load_item [ITEM MODEL NOT FOUND] Model or ID: #{model_or_id}"
            return nil
        end
        mob = Mobile.new( model, room, reset )
        add_global_mobile(mob)
        if @shop_data.dig(model.id)
            AffectShopkeeper.new( mob, mob, 0 ).apply(true)
        end
        return mob
    end

    def load_item( model_or_id, inventory, reset = nil )
        model = (model_or_id.is_a?(Integer)) ? @item_models.dig(model_or_id) : model_or_id
        if !model.is_a?(ItemModel)
            log "load_item [ITEM MODEL NOT FOUND] Model or ID: #{model_or_id}"
            return nil
        end
        item_class = model.class.item_class
        item = item_class.new(model, inventory, reset)
        add_global_item(item)
        if @portal_data.dig(item.id)
            # portal = AffectPortal.new( source: nil, target: item, level: 0, game: self )
            # portal.overwrite_modifiers({ destination: @rooms[ @portal_data[id][:to_room_id] ] })
            AffectPortal.new( item, @rooms[ @portal_data[item.id][:to_room_id] ] ).apply
        end
        return item
    end

    def find_commands( actor, cmd )
        matches = (
            @commands.select { |command| command.check( cmd ) } +
            @skills.select{ |skill| skill.check( cmd ) && actor.knows( skill ) }
        ).sort_by(&:priority)
        return matches
    end

    ##
    # Returns true if a given GameObject responds to a given event
    def responds_to_event(object, event)
        return true
        return @responders.dig(object.uuid, event).nil?
    end

    # Send an event to a list of objects
    #
    # Examples:
    #  fire_event(some_mobile, :event_test, {})
    #  fire_event(some_mobile, :event_on_hit, data)
    def fire_event(object, event, data)
        @responders.dig(object.uuid, event).to_a.each do |callback_object, callback, priority|
            callback_object.send(callback, data)
        end
        return true
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

    def add_combat_mobile(mobile)
        @combat_mobs.add(mobile)
    end

    def remove_combat_mobile(mobile)
        @combat_mobs.delete(mobile)
    end

    def add_regen_mobile(mobile)
        @regen_mobs.add(mobile)
    end

    def remove_regen_mobile(mobile)
        @regen_mobs.delete(mobile)
    end

    def add_cooldown_object(gameobject)
        @cooldown_objects.add(gameobject)
    end

    def remove_cooldown_object(gameobject)
        @cooldown_objects.delete(gameobject)
    end

    ##
    # update objects with pending cooldowns.
    # They remove themselves when all cooldowns are cleared.
    def handle_cooldown_objects
        @cooldown_objects.each do |gameobject|
            gameobject.update_cooldowns(@frame_time)
        end
    end

    # Affect/GameObject destruction:

    def destroy_affect(affect)
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
    end

    # destroy a continent object
    def destroy_continent(continent)
        @continents.delete(continent.id)
    end

    # destroy an area object
    def destroy_area(area)
        @areas.delete(area.id)
    end

    # destroy a room object
    def destroy_room(room)
        if !@reload
            @rooms.values.each do |other_room| # remove exits that go to the room being destroyed
                other_room.exits.each do |direction, exit|
                    if exit && exit.destination == room
                        exit.destination = nil
                        # destroy exit object as well?
                    end
                end
            end
        end
        @rooms.delete(room.id)
    end

    # destroy a mobile object
    def destroy_mobile(mobile)
        remove_global_mobile(mobile)
        @mobiles.delete(mobile)
    end

    # destroy a player object
    def destroy_player(player)
        @inactive_player_source_affects[player.id] = player.source_affects
        @players.delete(player)
    end

    # destroy an item object
    def destroy_item(item)
        remove_global_item(item)
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
            @players.each_output "The sun rises in the east."
        elsif time.first == Constants::Time::SUNRISE + 1
            @players.each_output "The day has begun."
        elsif time.first == Constants::Time::SUNSET
            @players.each_output "The sun slowly disappears in the west."
        elsif time.first == Constants::Time::SUNSET + 1
            @players.each_output "The night has begun."
        end
    end

    def server_input_loop
        while !@shutdown
            input = gets.chomp.to_s
            cmd, args = input.sanitize.split(" ", 2)

            command = find_server_commands( cmd ).last

            if command.nil?
                log "Huh?"
            else
                command.attempt(nil, cmd, args.to_s.to_args, input)
            end
        end
    end

    def find_server_commands( cmd )
        matches = @server_commands.select { |command| command.check( cmd ) }.sort_by(&:priority)
        return matches
    end

    ##
    # allows the server to shut down
    def initiate_reload
        @reload = true
    end

    ##
    # allows the server to shut down
    def initiate_stop
        @shutdown = true
    end

end
