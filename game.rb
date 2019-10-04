require 'sequel'
require_relative 'game_setup'
require_relative 'game_save'

class Game

    attr_accessor :mobiles
    attr_accessor :mobile_count
    attr_accessor :items
    attr_reader :race_data
    attr_reader :locked
    attr_reader :class_data
    attr_reader :equip_slot_data
    attr_reader :affects
    attr_reader :help_data
    attr_reader :spells
    attr_reader :continents

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
        @shop_data = Hash.new               # Shop table as hash       (uses :id as key)

        @base_resets = Hash.new             # Reset table as hash           (uses :id as key)
        @mob_resets = Hash.new              # Mob reset table as hash       (uses :reset_id as key)
        @inventory_resets = Hash.new        # Inventory reset table as hash (uses :reset_id as key)
        @equipment_resets = Hash.new        # Equipment reset table as hash (uses :reset_id as key)
        @room_item_resets = Hash.new        # Room item reset table as hash (uses :reset_id as key)
        @base_mob_resets = Hash.new         # Subset of @base_resets where :type is "mobile"
        @base_room_item_resets = Hash.new   # Subset of @base_resets where :type is "room_item"

        @help_data = Hash.new               # Help table as hash  (uses :id as key)

        # GameObjects
        @continents = Hash.new              # Continent objects as hash   (uses :id as key)
        @areas = Hash.new                   # Area objects as hash        (uses :id as key)
        @rooms = Hash.new                   # Room objects as hash        (uses :id as key)
        @players = Hash.new
        @inactive_players = Hash.new
        @items = []
        @item_count = Hash.new
        @mobiles = []
        @mobile_count = Hash.new

        @affects = []                       # Master list of all applied affects in the game
        @skills = []                        # Skill object array
        @spells = []                        # Spell object array
        @commands = []                      # Command object array

        @locked = false                     # lock is true during game loop, unlocked between frames

    end

    def login( client, thread )
        client.puts @game_settings[:login_splash]
        name = nil
        client.puts "By what name do you wish to be known?"
        while name.nil?
            name = client.gets.chomp.to_s.downcase.capitalize
            if name.length <= 2
                client.puts "Your name must be at least three characters."
                name = nil
            elsif (player_data = @db[:saved_player_base].where(name: name).first)
                try = 0
                correct = false
                while try < 3 && !correct
                    client.puts "Password:"
                    password = client.gets.chomp.to_s
                    try += 1
                    if !(correct = (Digest::MD5.hexdigest(password) == player_data[:md5]))
                        client.puts "Incorrect Password."
                    end
                end
                if try == 3
                    client.puts "Goodbye."
                    client.close
                    Thread.kill(thread)
                    return
                end
                if @players[name]       # quit that player if they're online
                    @players[name].quit
                end
                if @inactive_players.has_key?(name) && @inactive_players[name].weakref_alive?
                    player = @inactive_players[name].__getobj__
                    @inactive_players.delete(name)
                    player.reconnect(client, thread)
                    # log "#{name} is connecting as an inactive player!"
                    finalize_login(player)
                    return
                else
                    player = load_player(name, client, thread)
                    if !player
                        @players.delete(name)
                        client.close
                        Thread.kill(thread)
                        return
                    end
                    finalize_login(player)
                    return
                end
            end
        end

        md5 = nil
        # local_echo_off = ["11111111111110110000000100000000"].pack("B*")
        # local_echo_on =  ["11111111111111000000000100000000"].pack("B*")
        # client.puts local_echo_off
        client.puts "Please choose a password."
        while md5.nil?
            password = client.gets.chomp.to_s
            if password.length < 6
                client.puts "Passwords must be at least 6 characters long."
            else
                md5 = Digest::MD5.hexdigest(password)
            end
            if md5
                client.puts "Re-enter password:"
                password2 = client.gets.chomp.to_s
                if password2 != password
                    client.puts "Passwords don't match.\n\rPlease choose a password."
                    md5 = nil
                end
            end
        end
        # client.puts local_echo_on

        race_id = nil
        player_race_data = @race_data.select{ |key, value| value[:player_race] == 1 && value[:starter_race] == 1 }
        player_race_names = player_race_data.map{ |key, value| value[:name] }
        while race_id.nil?

            client.puts("The following races are available:\n\r" +
            "#{player_race_names.map{ |name| name.lpad(10) }.each_slice(5).to_a.map(&:join).join("\n\r")}\n\r\n\r" +
            "What is your race (help for more information)?)")
            race_input = client.gets.chomp
            race_matches = player_race_names.select{ |name| name.fuzzy_match(race_input) }
            if race_matches.any?
                race_id = @race_data.select{ |key, value| value[:name] == race_matches.first}.first[0]
            else
                client.puts "You must choose a valid race!"
            end
        end

        class_id = nil
        start_class_data = @class_data.select{ |key, value| value[:starter_class] == 1 }
        class_names = start_class_data.map{ |key, value| value[:name] }
        while class_id.nil?
            client.puts %Q(
Select a class
---------------
#{class_names.join("\n")}
:)
            class_input = client.gets.chomp.to_s
            class_matches = class_names.select{ |name| name.fuzzy_match(class_input) }
            if class_matches.any?
                class_id = @class_data.select{ |key, value| value[:name] == class_matches.first}.first[0]
            else
                client.puts "Invalid class!"
            end
        end

        alignment = nil
        while alignment.nil?
            client.puts %Q(You may be good, neutral, or evil.
Which alignment (G/N/E)?)
            case client.gets.chomp.to_s.capitalize
            when "G"
                alignment = 1000
            when "N"
                alignment = 0
            when "E"
                alignment = -1000
            else
                client.puts "Please type G N or E OMG!"
            end
        end

        player = Player.new( { alignment: alignment, name: name, race_id: race_id, class_id: class_id }, self, @starting_room.nil? ? @rooms.first : @starting_room, client, thread )
        save_player(player, md5)
        finalize_login(player)
    end

    def finalize_login(player)
        until !@locked
            sleep(0.001)
        end
        @players[player.name] = player
        save
        player.output "Welcome, #{player.name}."
        player.move_to_room(player.room)
        broadcast("%s has entered the game.", target({not: [player], list: player.room.occupants, quantity: "all"}), [player])
        @players[player.name].input_loop
    end

    def game_loop
        loop do
            @locked = true
            @frame_count += 1

            # deal with inactive players that have been garbage collected
            # p "#{@frame_count} #{@inactive_players.keys}" if @inactive_players.length > 0
            @inactive_players.each do |name, player|
                if !player.weakref_alive?
                    @inactive_players.delete(name)
                end
            end

            # save every so often!
            if @frame_count % Constants::Interval::AUTOSAVE == 0
                save
            end

            # each combat ROUND
            if @frame_count % Constants::Interval::ROUND == 0
                combat
            end

            if @frame_count % Constants::Interval::TICK == 0
                tick
            end

            if @frame_count % Constants::Interval::REPOP == 0
                repop
            end

            update( 1.0 / Constants::Interval::FPS )
            send_to_client

            # GC.start

            # Sleep until the next frame
            sleep_time = (1.0 / Constants::Interval::FPS)
            @locked = false
            sleep(sleep_time)
        end
    end

    # eventually, this will handle all game logic
    def update( elapsed )
        ( @players.values + @mobiles + @items + @rooms.values + @areas.values ).each do | entity |
            entity.update(elapsed)
        end
    end

    def send_to_client
        @players.each do | username, player |
            player.send_to_client
        end
    end

    def combat
        ( @players.values + @mobiles).each do | entity |
            entity.combat
        end
    end

    def broadcast( message, targets, objects = [] )
        targets.each do | player |
            player.output( message, objects.to_a )
        end
    end

    def target( query = {} )
        targets = []

        if !query[:list].nil?
            targets = query[:list].reject(&:nil?) # got a crash here once but don't know why - maybe a bad list passed in?
            if query[:type]
                targets -= targets.select { |t| Area === t }      if !query[:type].to_a.include?("Area")
                targets -= targets.select { |t| Continent === t } if !query[:type].to_a.include?("Continent")
                targets -= targets.select { |t| Player === t }    if !query[:type].to_a.include?("Player")
                targets -= targets.select { |t| Item === t }      if !query[:type].to_a.include?("Item")
                targets -= targets.select { |t| Mobile === t }    if !query[:type].to_a.include?("Mobile")
            end
        elsif query[:type].nil?
            targets = @areas.values + @players.values + @items + @mobiles
        else
            targets += @areas.values       if query[:type].to_a.include? "Area"
            targets += @continents.values  if query[:type].to_a.include? "Continent"
            targets += @players.values     if query[:type].to_a.include? "Player"
            targets += @items              if query[:type].to_a.include? "Item"
            targets += @mobiles            if query[:type].to_a.include? "Mobile"
        end

        targets = targets.select { |t| t.uuid == query[:uuid] }                                                     if query[:uuid]
        targets = targets.select { |t| query[:affect].to_a.any?{ |affect| t.affected?( affect.to_s ) } }            if query[:affect]
        targets = targets.select { |t| t.type == query[:item_type] }                                                if query[:item_type]
        targets = targets.select { |t| query[:visible_to].can_see? t }                                              if query[:visible_to]
        targets = targets.select { |t| query[:room].to_a.include? t.room }                                          if query[:room]
        targets = targets.select { |t| t.room && query[:area].to_a.include?(t.room.area) }                          if query[:area]
        targets = targets.select { |t| !query[:not].to_a.include? t }                                               if query[:not]
        targets = targets.select { |t| query[:attacking].to_a.include? t.attacking }                                if query[:attacking]
        targets = targets.select { |t| t.fuzzy_match( query[:keyword] ) }                                       	if query[:keyword]
        targets = targets[0...query[:limit].to_i]                                                                   if query[:limit]

        query[:offset] == "all" || query[:offset].nil? ? offset = 0 : offset = [0, query[:offset].to_i - 1].max
        query[:offset] == "all" || query[:quantity] == "all" || query[:quantity].nil? ? quantity = targets.length : quantity = [1, query[:quantity].to_i].max

        targets = targets[ offset...offset+quantity ].to_a

        return targets
    end

    def tick
        broadcast "{MMud newbies 'Hi everyone! It's a tick!!'{x", target({ list: @players.values })
        ( @players.values + @mobiles).each do | entity |
            entity.tick
        end
    end

    def repop
        @base_mob_resets.each do |reset_id, reset_data|
            reset = @mob_resets[reset_id]
            if @mob_data[ reset[:mobile_id] ]
                if @mobile_count[ reset[:mobile_id] ].to_i < reset[:world_max] && @rooms[reset[:room_id]].mobile_count[reset[:mobile_id]].to_i < reset[:room_max]
                    mob = load_mob( reset[:mobile_id], @rooms[ reset[:room_id] ] )
                    @mobiles.push mob

                    @mobile_count[ reset[:mobile_id] ] = @mobile_count[ reset[:mobile_id] ].to_i + 1

                    # inventory
                    @inventory_resets.select{ |id, inventory_reset| inventory_reset[:parent_id] == reset_id }.each do | item_reset_id, item_reset |
                        if @item_data[ item_reset[:item_id] ]
                            item = load_item( item_reset[:item_id], mob.inventory )
                        else
                            log "[Inventory item not found] RESET ID: #{item_reset_id}, ITEM ID: #{item_reset[:item_id]}, AREA: #{@areas[@base_resets[item_reset_id][:area_id]]}"
                        end
                    end

                    #equipment
                    @equipment_resets.select{ |id, equipment_reset| equipment_reset[:parent_id] == reset_id }.each do | item_reset_id, item_reset |
                        if @item_data[ item_reset[:item_id] ]
                            item = load_item( item_reset[:item_id], mob.inventory )
                            mob.wear(item: item, silent: true)
                        else
                            log "[Equipped item not found] RESET ID: #{item_reset_id}, ITEM ID: #{item_reset[:item_id]}, AREA: #{@base_resets[item_reset_id][:area_id]}"
                        end
                    end

                    #containers ???
                end

            else
                log "[Mob not found] RESET ID: #{reset[:id]}, MOB ID: #{reset[:mobile_id]}"
            end
        end

        @base_room_item_resets.each do |reset_id, reset_data|
            if ( reset = @room_item_resets[reset_id] )
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
                extra_flags: row[:extra_flags],
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
            else
                item = Item.new( data, self, inventory )
            end
            if item
                @items.push item
                return item
            else
                log "[Item creation unsuccessful]"
                return nil
            end
        else
            log "load_item [ITEM NOT FOUND] Item ID: #{ id }"
        end
    end

    def do_command( actor, cmd, args = [] )
        matches = (
            @commands.select { |command| command.check( cmd ) } +
            @skills.select{ |skill| skill.check( cmd ) && actor.knows( skill.to_s ) }
        ).sort_by(&:priority)

        if matches.any?
            matches.last.execute( actor, cmd, args )
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
    #  fire_event(:event_test, {}, some_mobile)
    #  fire_event(:event_on_hit, data, some_mobile, some_room, some_room.area, some_mobile.equipment)
    def fire_event(event, data, *objects)
        objects.flatten.uniq.each do |object|
            object.event(event, data)
        end
    end

    def add_affect(affect)
        @affects.push(affect)
    end

    def remove_affect(affect)
        @affects.delete(affect)
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
            remove_affect(affect)
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
            remove_affect(affect)
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
        rooms.affects.each do |affect|
            remove_affect(affect)
        end
        room.mobiles.each do |mobile|
            destroy_mobile(mobile)
        end
        room.players.each do |player|
            player.move_to_room(@starting_room) # just move players out
        end
        room.inventory.items.each do |item|
            item.affects.each do |affect|
                remove_affect(affect)
            end
            @items.delete(item)
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
            remove_affect(affect)
        end
        mobile.inventory.items.each do |item|
            item.affects.each do |affect|
                remove_affect(affect)
            end
            @items.delete(item)
        end
        mobile.equipment.each do |item|
            item.affects.each do |affect|
                remove_affect(affect)
            end
            @items.delete(item)
        end
        @mobile_count[mobile.id] = @mobile_count[mobile.id].to_i - 1
        @mobile_count.delete(mobile.id) if @mobile_count[mobile.id] <= 0
        @mobiles.delete(mobile)
    end

    # destroy a player object
    def destroy_player(player)
        @inactive_players[player.name] = WeakRef.new(player)
        player.room.mobile_depart(player)
        player.deactivate
        player.affects.each do |affect|
            remove_affect(affect)
        end
        player.inventory.items.each do |item|
            item.affects.each do |affect|
                remove_affect(affect)
            end
            @items.delete(item)
        end
        player.equipment.each do |item|
            item.affects.each do |affect|
                remove_affect(affect)
            end
            @items.delete(item)
        end
        @players.delete(player.name)
    end

    # destroy an item object
    def destroy_item(item)
        item.move(nil)          # remove its inventory references by moving it to a nil inventory
        item.affects.each do |affect|
            remove_affect(affect)
        end
        @items.delete(item)
    end

    def inspect
        "GAME OBJECT"
    end

end
