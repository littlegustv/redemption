require_relative 'game_setup'
require_relative 'game_save'

class Game

    include Singleton
    include GameSetup
    include GameSave

    attr_reader :help_data
    attr_reader :social_data

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
    attr_reader :wear_locations

    def initialize
        @server = nil                       # TCPServer object
        @db = nil                           # Sequel database connection
        @started = false                    # Boolean: start has been called?
        @next_uuid = 1                      # Next available UUID for a GameObject.
        @start_time = nil                   # Time the server actually began running/accepting players
        @frame_count = 0                    # Frame count - goes up by 1 every frame (:
        @starting_room = nil                # The room that players log in to - currently gets set in make_rooms

        # Database tables
        @game_settings = Hash.new           # Hash with values for next_uuid, login_splash, etc

        @shop_data = Hash.new               # Shop table as hash       (uses :mobile_id as key)

        # @new_reset_

        @saved_player_id_max = 0                # max id in database table saved_player_base
        @saved_player_affect_id_max = 0         # max id in database table saved_player_affect
        @saved_player_item_id_max = 0           # max id in database table saved_player_item
        @saved_player_item_affect_id_max = 0    # max id in database table saved_player_item_affect

        @help_data = Hash.new                   # Help table as hash  (uses :id as key)
        @social_data = Hash.new                 # Social table as hash (uses :id as key)
        @account_data = Hash.new                # Account table as hash (uses :id  as key)
        @saved_player_data = Hash.new           # Saved player table as hash    (uses :id as key)

        @affect_class_hash = Hash.new           # Affect classes as hash (uses :id as key)

        # Models
        @item_model_classes = Hash.new      # hash of item model classes - uses item_type_id as key
        @item_models = Hash.new             # hash of item models (uses :id as key)
        @mobile_models = Hash.new           # Hash of mobile models (uses :id as key)

        # Resets
        @mobile_resets = []                 # Mobile resets
        @active_resets = []                 # Array of Resets waiting to pop - sorted by reset.pop_time (ascending)
        @active_resets_sorted = false       # set to false when a new reset is activated. resets will be sorted on next handle_resets
        @initial_reset = true

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
        @wear_locations =   Hash.new        # hash of wear locations          (uses :id as key)

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

        @combat_mobs = Set.new
        @regen_mobs = Set.new

        @item_keyword_map = Hash.new
        @mobile_keyword_map = Hash.new

        @affects = Set.new                  # Master list of all applied affects in the game
        @skills = []                        # Skill object array
        @spells = []                        # Spell object array
        @commands = []                      # Command object array

        @abilities = Hash.new

        @responders = Hash.new                  # Event responders

    end

    def game_loop
        last_gc_stat = {}
        total_time = 0
        last_frame_time = Time.now
        loop do
            start_time = Time.now
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

            # deal with inactive players that have been garbage collected
            # p "#{@frame_count} #{@inactive_players.keys}" if @inactive_players.length > 0
            @inactive_players.each do |name, player|
                if !player.weakref_alive?
                    @inactive_players.delete(name)
                    puts "#{name} has been deleted from memory."
                end
            end

            # load any players whose ids have been added to the logging_players queue
            @logging_players.each do |player_id, client|
                @logging_players.delete([player_id, client])
                player = nil
                if (player = @players.find{ |p| p.id == player_id }) # found in online player
                    player.reconnect(client)
                elsif (player = @inactive_players.values.find { |p| p.weakref_alive? && p.id == player_id })
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

            # save every so often!
            # add one to the frame_count so it doesn't save on combat frames, etc
            before = Time.now
            if (@frame_count + 1) % Constants::Interval::AUTOSAVE == 0
                save
            end
            save_time = Time.now - before

            # each combat ROUND
            before = Time.now
            if @frame_count % Constants::Interval::ROUND == 0
                combat
            end
            round_time = Time.now - before

            before = Time.now
            if @frame_count % Constants::Interval::TICK == 0
                tick
            end
            tick_time = Time.now - before

            handle_resets

            before = Time.now
            elapsed = Time.now - last_frame_time
            last_frame_time = Time.now
            update( elapsed )
            update_time = Time.now - before

            @players.each do | player |
                player.send_to_client
            end

            end_time = Time.now
            loop_computation_time = end_time - start_time
            sleep_time = ((1.0 / Constants::Interval::FPS) - loop_computation_time)
            total_time += loop_computation_time

            # Sleep until the next frame, if there's time left over
            if sleep_time < 0 && !@initial_reset # try to figure out why there isn't (initial reset frames don't really count :) )!
                gc_stat = GC.stat
                if $VERBOSE
                    lines = []
                    gc_stat.each do |key, value|
                        if value != last_gc_stat[key]
                            lines << key.to_s.ljust(30) + last_gc_stat[key].to_s.ljust(14) + " -> " + value.to_s
                        end
                    end
                    log lines.join("\n")
                end
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
                sleep([sleep_time, 0].max) #
            end
            last_gc_stat = GC.stat
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
    def update( elapsed )
        @players.each do | player |
            # player.update(elapsed)
            player.process_commands(elapsed)
        end
        # @wander_mobiles = @mobiles.dup
        # @wander_mobiles.shuffle.
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

    def combat
        @combat_mobs.to_a.each do |mob|
            mob.combat
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

    def affect_class_with_id(id)
        return @affect_class_hash.dig(id)
    end

    def element_with_symbol(symbol)
        element = @elements.values.find { |e| e.symbol == symbol}
        if !element
            log ("No element with symbol #{symbol} found. Creating one now. Stack trace:")
            puts caller[0..3]
            new_id = (@elements.keys.min || 0) - 1
            element = Element.new({
                id: new_id,
                name: symbol.to_s
            })
            @elements[new_id] = element
        end
        return element
    end

    def gender_with_symbol(symbol)
        size = @genders.values.find { |g| g.symbol == symbol}
        if !size
            log ("No gender with symbol #{symbol} found. Creating one now. Stack trace:")
            puts caller[0..3]
            new_id = (@genders.keys.min || 0) - 1
            size = Genre.new({
                id: new_id,
                name: symbol.to_s,
                personal_objective: "it",
                personal_subjective: "it",
                possessive: "its",
                reflexive: "itself",
            })
            @genres[new_id] = size
        end
        return size
    end

    def genre_with_symbol(symbol)
        genre = @genres.values.find { |g| g.symbol == symbol}
        if !genre
            log ("No genre with symbol #{symbol} found. Creating one now. Stack trace:")
            puts caller[0..3]
            new_id = (@genres.keys.min || 0) - 1
            new_value = 0
            genre = Genre.new({
                id: new_id,
                name: symbol.to_s
            })
            @genres[new_id] = genre
        end
        return genre
    end

    def noun_with_symbol(symbol)
        noun = @nouns.values.find { |n| n.symbol == symbol }
        if !noun
            copy_noun = @nouns.values.first
            if !copy_noun
                log ("No damage nouns exist. That's going to be a problem!")
                return nil
            end
            log("No noun with symbol #{symbol} found. Creating one using #{copy_noun.name} as a base. Stack trace:")
            puts caller[0..3]
            new_id = (@nouns.keys.min || 0) - 1
            @nouns[new_id] = Noun.new({
                id: new_id,
                name: symbol.to_s,
                element: copy_noun.element.id,
                magic: copy_noun.magic
            })
        end
        return noun
    end

    def position_with_symbol(symbol)
        position = @positions.values.find { |p| p.symbol == symbol}
        if !position
            log ("No position with symbol #{symbol} found. Creating one now. Stack trace:")
            puts caller[0..3]
            new_id = (@positions.keys.min || 0) - 1
            position = Position.new(new_id, symbol.to_s)
            @positions[new_id] = position
        end
        return position
    end

    def sector_with_symbol(symbol)
        sector = @sectors.values.find { |s| s.symbol == symbol}
        if !sector
            log ("No sector with symbol #{symbol} found. Creating one now. Stack trace:")
            puts caller[0..3]
            new_id = (@sectors.keys.min || 0) - 1
            new_value = 0
            sector = Sector.new(new_id, symbol.to_s, new_value)
            @sectors[new_id] = sector
        end
        return sector
    end

    def size_with_symbol(symbol)
        size = @sizes.values.find { |s| s.symbol == symbol}
        if !size
            log ("No size with symbol #{symbol} found. Creating one now. Stack trace:")
            puts caller[0..3]
            new_id = (@sizes.keys.min || 0) - 1
            new_value = 0
            size = Size.new(new_id, symbol.to_s, new_value)
            @sizes[new_id] = size
        end
        return size
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

        # player tick is called, just to allow for some regen!!
        ( @players ).each do | entity |
            entity.tick
        end

        weather
    end

    ## Activate a reset.
    # _Called only by the reset itself_
    def activate_reset(reset)
        @active_resets << reset             # add to the list of active resets!
        @active_resets_sorted = false
    end

    ## Handle resets.
    # Iterate through resets, popping each until resets not ready to pop are found.
    def handle_resets(limit = Constants::Interval::RESETS_PER_FRAME)
        if @active_resets.size == 0
            return
        end
        if !@active_resets_sorted
            @active_resets.sort_by!(&:pop_time)
            @active_resets_sorted = true
        end
        current_time = Time.now.to_i
        [@active_resets.size, limit].min.times do
            reset = @active_resets.first
            if current_time >= reset.pop_time
                @active_resets.shift
                reset.pop if reset.success?
            else
                # stop trying to reset, all resets in loop after here are in the future!
                break
            end
        end
        if @initial_reset && @active_resets.select { |r| r.pop_time == 0 }.size == 0
            log "Initial resets complete."
            @initial_reset = false
        end
    end

    def load_mob( mobile_model, room, reset = nil )
        mob = Mobile.new( mobile_model, room, reset )
        add_global_mobile(mob)
        if not @shop_data[ mobile_model.id ].nil?
            mob.apply_affect( AffectShopkeeper.new( mob, mob, 0 ), true )
        end
        return mob
    end

    def load_item( id, inventory )
        item = nil
        if ( row = @item_data[ id ] )
            if row[:noun]
                item = Weapon.new( row, inventory )
            elsif row[:type] == "container"
                item = Container.new( row, inventory )
            elsif row[:type] == "pill" or row[:type] == "potion"
                item = Consumable.new( row, inventory, @item_spells[ id ] )
            else
                item = Item.new( row, inventory )
            end

            if not @portal_data[ id ].nil?
                # portal = AffectPortal.new( source: nil, target: item, level: 0, game: self )
                # portal.overwrite_modifiers({ destination: @rooms[ @portal_data[id][:to_room_id] ] })
                item.apply_affect( AffectPortal.new( item, @rooms[ @portal_data[id][:to_room_id] ] ) )
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
            @skills.select{ |skill| skill.check( cmd ) && actor.knows( skill ) }
        ).sort_by(&:priority)

        if matches.any?
            matches.last.execute( actor, cmd, args, input )
            return
        end

    	actor.output "Huh?"
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
            name: "inactive continent".freeze,
            id: 0,
            preposition: "on".freeze,
            recall_room_id: 0,
            starting_room_id: 0
        }
        return Continent.new(data)
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
            name: "inactive area".freeze,
            age: 0,
            builders: "no builders".freeze,
            continent: self.new_inactive_continent,
            control: "no control".freeze,
            credits: "no credits".freeze,
            gateable: 0,
            id: 0,
            questable: 0,
            security: 0
        }
        return Area.new(data)
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
        return Room.new("inactive room".freeze, 0, "no description".freeze, "inside".to_sector,
                self.new_inactive_area, 0, 0)
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
        if mobile.hand_to_hand_weapon
             remove_global_item(mobile.hand_to_hand_weapon)
        end
        remove_global_mobile(mobile)
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
        if player.hand_to_hand_weapon
             remove_global_item(player.hand_to_hand_weapon)
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

end
