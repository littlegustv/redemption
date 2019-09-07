require 'sequel'

class Game

    attr_accessor :mobiles, :mobile_count

    def initialize( ip, port )

        @players = Hash.new
        @items = []
        @item_data = Hash.new
        @mobiles = []
        @mobile_data = Hash.new
        @mobile_count = {}
        @rooms = Hash.new
        @areas = Hash.new
        @helps = Hash.new
        @continents = Hash.new
        @game_settings = Hash.new
        @starting_room = nil
        @start_time = Time.now
        @frame_count = 0

        @race_data = []
        @class_data = []

        # eventually load these from the database
        puts "Opening server on #{port}"
        if ip
            @server = TCPServer.open( ip, port )
        else
            @server = TCPServer.open( port )
        end

        sql_host, sql_port, sql_username, sql_password = File.read( "server_config.txt" ).split("\n").map{ |line| line.split(" ")[1] }
        @db = Sequel.mysql2( :host => sql_host, :username => sql_username, :password => sql_password, :database => "redemption" )
        setup_game

        make_commands

        puts( "Redemption is ready to rock on port #{port}!" )

        # game update loop runs on a single thread
        Thread.start do
            game_loop
        end

        # each client runs on its own thread as well
        loop do
            thread = Thread.start(@server.accept) do |client|
                login client, thread
            end
        end
    end

    def login( client, thread )
        client.puts @game_settings[:login_splash]
        name = nil
        client.puts "By what name do you wish to be known?"
        while name.nil?
            name = client.gets.chomp.to_s

            if name.length <= 2
                client.puts "Your name must be at least three characters.\n\r"
                name = nil
            elsif @players.has_key? name
                client.puts "That name is already in use, try another.\n\r"
                name = nil
            else
            end
        end

        race = nil
        player_race_data = @race_data.select{ |key, value| value[:player_race] == 1 }
        player_race_names = player_race_data.keys
        while race.nil?

            client.puts %Q(
The following races are available:
#{player_race_names.map{ |name| name.ljust(10) }.each_slice(5).to_a.map(&:join).join("\n")}

What is your race (help for more information)?)
            race_input = client.gets.chomp
            race_matches = player_race_names.select{ |name| name.fuzzy_match(race_input) }
            if race_matches.any?
                race = @race_data[race_matches.first]
            else
                client.puts "You must choose a valid race!"
                race = nil
            end
        end

        charclass = nil
        class_names = @class_data.keys
        while charclass.nil?
            client.puts %Q(
Select a class
---------------
#{class_names.join("\n")}
:)
            charclass =
            class_input = client.gets.chomp.to_s
            class_matches = class_names.select{ |name| name.fuzzy_match(class_input) }
            if class_matches.any?
                charclass = @class_data[class_matches.first]
            else
                client.puts "Invalid class!"
                charclass = nil
            end
        end

        alignment = nil
        while alignment.nil?
            client.puts %Q(
You may be good, neutral, or evil.
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

        client.puts "Welcome, #{name}."
        broadcast "#{name} has joined the world.", target
        @players[name] = Player.new( { alignment: alignment, name: name, race: race, charclass: charclass }, self, @starting_room.nil? ? @rooms.first : @starting_room, client, thread )
        client.puts "Users Online: [#{ @players.keys.join(', ') }]\n\r"
        @players[name].input_loop
    end

    def game_loop
        loop do
            @frame_count += 1

            # each combat ROUND
            if @frame_count % Constants::ROUND == 0
                combat
            end

            if @frame_count % Constants::TICK == 0
                tick
            end

            if @frame_count % Constants::RESET == 0
                reset
            end

            update( 1.0 / Constants::FPS )
            send_to_client

            # Sleep until the next frame
            sleep_time = (1.0 / Constants::FPS)
            sleep(sleep_time)
        end
    end

    # eventually, this will handle all game logic
    def update( elapsed )
        ( @players.values + @mobiles).each do | entity |
            entity.update elapsed
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
            player.output( message, objects )
        end
    end

    def target( query = {} )
        targets = []

        if query[:type].nil?
            targets = @areas.values + @players.values + @items + @mobiles
        else
            targets += @areas.values       if query[:type].to_a.include? "Area"
            targets += @players.values     if query[:type].to_a.include? "Player"
            targets += @items              if query[:type].to_a.include? "Item"
            targets += @mobiles            if query[:type].to_a.include? "Mobile"
        end

        targets = query[:list].reject(&:nil?)                                                                       if query[:list]
        targets = targets.select { |t| query[:visible_to].can_see? t }                                              if query[:visible_to]
        targets = targets.select { |t| query[:room].to_a.include? t.room }                                          if query[:room]
        # fix me: figure out a good way of getting the area for objects that are not directly in a room
        targets = targets.select { |t| t.room && query[:area].to_a.include?(t.room.area) }                          if query[:area]
        targets = targets.select { |t| !query[:not].to_a.include? t }                                               if query[:not]
        targets = targets.select { |t| query[:attacking].to_a.include? t.attacking }                                if query[:attacking]
        targets = targets.select { |t| t.fuzzy_match( query[:keyword] ) }                                       	if query[:keyword]
        targets = targets[0...query[:limit].to_i]                                                                   if query[:limit]

        unless query[:offset] == 'all' or query[:quantity] == 'all'
            offset = [0, query[:offset].to_i - 1].max
            quantity = [1, query[:quantity].to_i].max
            targets = targets[ offset...offset+quantity ]
        end

        return targets
    end

    def disconnect( name )
        @players.delete( name )
        broadcast "#{name} has disconnected.", target
    end

    def tick
        broadcast "{MMud newbies 'Hi everyone! It's a tick!!'{x", target
        ( @players.values + @mobiles).each do | entity |
            entity.tick
        end
    end

    def reset
        @base_mob_resets.each do |reset_id, reset_data|
            reset = @mob_resets[reset_id]
            if @mob_data[ reset[:mobile_id] ]
                if @mobile_count[ reset[:mobile_id] ].to_i < reset[:world_max]
                    mob = load_mob( reset[:mobile_id], @rooms[ reset[:room_id] ] )
                    @mobiles.push mob

                    @mobile_count[ reset[:mobile_id] ] = @mobile_count[ reset[:mobile_id] ].to_i + 1

                    # inventory
                    @inventory_resets.select{ |id, inventory_reset| inventory_reset[:parent_id] == reset_id }.each do | item_reset_id, item_reset |
                        if @item_data[ item_reset[:item_id] ]
                            item = load_item( item_reset[:item_id], nil )
                            mob.inventory.push item
                        else
                            puts "[Inventory item not found] RESET ID: #{item_reset_id}, ITEM ID: #{item_reset[:item_id]}, AREA: #{@areas[@base_resets[item_reset_id][:area_id]]}"
                        end
                    end

                    #equipment
                    @equipment_resets.select{ |id, equipment_reset| equipment_reset[:parent_id] == reset_id }.each do | item_reset_id, item_reset |
                        if @item_data[ item_reset[:item_id] ]
                            item = load_item( item_reset[:item_id], nil )
                            ["", "_1", "_2"].each do | modifier |
                                slot = "#{item.wear_location}#{modifier}".to_sym
                                if mob.equipment.key?( slot ) and mob.equipment[slot] == nil
                                    mob.equipment[ slot ] = item
                                    break
                                end
                            end
                        else
                            puts "[Equipped item not found] RESET ID: #{item_reset_id}, ITEM ID: #{item_reset[:item_id]}, AREA: #{@base_resets[item_reset_id][:area_id]}"
                        end
                    end

                    #containers ???
                end

            else
                puts "[Mob not found] RESET ID: #{reset[:id]}, MOB ID: #{reset[:mobile_id]}"
            end
        end
    end

    def load_mob( id, room )
        row = @mob_data[ id ]
        Mobile.new( {
                id: id,
                keywords: row[:keywords].split(" "),
                short_description: row[:short_desc],
                long_description: row[:long_desc],
                full_description: row[:full_desc],
                race: @race_data[row[:race]] || {name: row[:race]},
                action_flags: row[:act_flags],
                affect_flags: row[:aff_flags],
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
                damage_range: [10, 20],
                damage: row[:damage].to_i,
                damage_type: row[:hand_to_hand_noun].split("").first, # pierce, slash, none, etc.
                armor_class: [row[:ac_pierce], row[:ac_bash], row[:ac_slash], row[:ac_magic]],
                offensive_flags: row[:off_flags],
                immune_flags: row[:imm_flags],
                resist_flags: row[:res_flags],
                vulnerable_flags: row[:vuln_flags],
                starting_position: row[:start_position],
                default_position: row[:default_position],
                sex: row[:sex],
                wealth: row[:wealth].to_i,
                form_flags: row[:form_flags],
                parts: row[:part_flags],
                size: row[:size],
                material: row[:material],
                level: row[:level]
            },
            self,
            room
        )
    end

    def load_item( id, room )
        row = @item_data[ id ]
        data = {
            short_description: row[:short_desc],
            long_description: row[:long_desc],
            keywords: row[:keywords].split(" "),
            weight: row[:weight].to_i,
            cost: row[:cost].to_i,
            type: row[:type],
            level: row[:level].to_i,
            wear_location: row[:wear_flags].match(/(wear_\w+|wield)/).to_a[1].to_s.gsub("wear_", ""),
            material: row[:material],
            extraFlags: row[:extra_flags],
            modifiers: {},
            ac: @ac_data[ id ].to_h.values[1..4]
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
                    flags: weapon_info[:flags].split(" "),
                    element: weapon_info[:element],
                    dice_sides: weapon_info[:dice_sides].to_i,
                    dice_count: weapon_info[:dice_count].to_i
                }
                item = Weapon.new( data.merge( weapon_data ), self, room )
            else
                puts "[Weapon and/or Dice data not found] ITEM ID: #{id}"
                item = Item.new( data, self, room )
            end
        else
            item = Item.new( data, self, room )
        end
        if item
            @items.push item
            return item
        else
            "[Item creation unsuccessful]"
            return nil
        end
    end

    def setup_game

        @game_settings = @db[:game_settings].all.first
        @race_data = @db[:race_base].to_hash(:name)
        @race_data.each do |key, value|
            value[:skills] = value[:skills].split(",")
            value[:spells] = value[:spells].split(",")
            value[:immune_flags] = value[:immune_flags].split(",")
            value[:resist_flags] = value[:resist_flags].split(",")
            value[:vuln_flags] = value[:vuln_flags].split(",")
            value[:part_flags] = value[:part_flags].split(",")
            value[:form_flags] = value[:form_flags].split(",")
        end
        @class_data = @db[:class_base].to_hash(:name)
        @class_data.each do |key, value|
            value[:skills] = value[:skills].split(",")
            value[:spells] = value[:spells].split(",")
        end

        continent_rows = @db[:continent_base].all
        continent_rows.each do |row|
            @continents[row[:id]] = Continent.new(row, self)
        end

        # create area objects
        area_rows = @db[:area_base].all
        area_rows.each do |row|
            @areas[row[:id]] = Area.new(
                {
                    id: row[:id],
                    name: row[:name],
                    continent: @continents[row[:continent_id]],
                    age: row[:age],
                    builders: row[:builders],
                    credits: row[:credits],
                    questable: row[:questable],
                    gateable: row[:gateable],
                    security: row[:security],
                    control: row[:control]
                },
                self
            )
        end

        # create rooms
        @item_modifiers = @db[:item_modifier].to_hash_groups(:item_id)
        @ac_data = @db[:item_armor].to_hash(:item_id)

        room_rows = @db[:room_base].all
        room_rows.each do |row|
            @rooms[row[:id]] = Room.new(
                row[:name],
                row[:description],
                row[:sector],
                @areas[row[:area_id]],
                row[:flags].to_s.split(" "),
                row[:hp_regen].to_i,
                row[:mana_regen].to_i,
                self
            )
        end


        @starting_room = @rooms[@db[:continent_base].to_hash(:id)[2][:starting_room_id]]

        # assign each exit to its room in the hash (if the destination exists)
        exit_rows = @db[:room_exit].all
        exit_rows.each do |exit|
            if @rooms[exit[:room_id]] && @rooms[exit[:to_room_id]]
                @rooms[exit[:room_id]].exits[exit[:direction].to_sym] = @rooms[exit[:to_room_id]]
            end
        end

        puts ( "Rooms loaded from database." )

        @mob_data = @db[:mobile_base].as_hash(:id)
        @item_data = @db[:item_base].as_hash(:id)
        @weapon_data = @db[:item_weapon].as_hash(:item_id)

        @mob_resets = @db[:reset_mobile].as_hash(:reset_id)
        @inventory_resets = @db[:reset_inventory_item].as_hash(:reset_id)
        @equipment_resets = @db[:reset_equipped_item].as_hash(:reset_id)
        # @base_resets = @db[:resetbase].where( area: "Shandalar" ).as_hash(:id)
        @base_resets = @db[:reset_base].as_hash(:id)
        @base_mob_resets = @base_resets.select{ |key, value| value[:type] == "mobile" }
        reset

        puts( "Mob Data and Resets loaded from database.")

        @areas.values.each do | area |
            area.set_rooms (@rooms.values.select{ | room | room.area == area })
        end

        @helps = @db[:help_base].as_hash(:id)
        @helps.each { |id, help| help[:keywords] = help[:keywords].split(" ") }

        puts ( "Helpfiles loaded from database." )
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

    def make_commands
    	@commands = [
            CommandAffects.new,
            CommandBlind.new,
            CommandConsider.new,
            CommandDrop.new,
            CommandEquipment.new,
            CommandFlee.new,
            CommandGet.new,
            CommandGoTo.new,
            CommandGroup.new,
            CommandHelp.new( @helps.values ),
            CommandInspect.new,
            CommandInventory.new,
            CommandKill.new,
            CommandLeave.new,
            CommandLook.new,
            CommandLore.new,
            CommandMove.new,
            CommandPeek.new,
            CommandPoison.new,
            CommandQui.new,
            CommandQuicken.new,
            CommandQuit.new,
            CommandRecall.new,
            CommandRemove.new,
            CommandRest.new,
            CommandSay.new,
            CommandScore.new,
            CommandSkills.new,
            CommandSleep.new,
            CommandStand.new,
            CommandWear.new,
            CommandWhere.new,
            CommandWhitespace.new,
            CommandWho.new( @continents.values ),
            CommandYell.new,
    	]
        @skills = [
            SkillSneak.new,
            SkillBerserk.new,
            SkillBash.new,
            SkillDisarm.new,
            SkillLivingStone.new,
        ]
        @spells = [
            # SpellHurricane.new,
        ]
    end

    def recall_room( continent )
        return @rooms[continent.recall_room_id]
    end

end
