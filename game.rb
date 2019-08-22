require 'sequel'

class Game

    attr_accessor :mobiles

    def initialize( ip, port )


        puts "Opening server on #{port}"
        if ip
            @server = TCPServer.open( ip, port )
        else
            @server = TCPServer.open( port )
        end

        sql_host, sql_port, sql_username, sql_password = File.read( "server_config.txt" ).split("\n").map{ |line| line.split(" ")[1] }

        @players = Hash.new
        @items = []
        @mobiles = []
        @rooms = []
        @areas = []
        @helps = []
        @starting_room = nil

        @db = Sequel.mysql2( :host => sql_host, :username => sql_username, :password => sql_password, :database => "redemption" )
        setup_game

        make_commands

        puts( "Redemption is ready to rock on port #{port}!\n" )

        @start_time = Time.now
        @interval = 0
        @clock = 0

        # game update loop runs on a single thread
        Thread.start do
            game_loop
        end

        # each client runs on its own thread as well
        loop do
            thread = Thread.start(@server.accept) do |client|

                name = nil
                while name.nil?
                    client.puts "By what name do you wish to be known?\n\r"
                    name = client.gets.chomp.to_s

                    if name.length <= 2
                        client.puts "Your name must be at least three characters.\n\r"
                        name = nil
                    elsif @players.has_key? name
                        client.puts "That name is already in use, try another.\n\r"
                        name = nil
                    else
                        client.puts "Welcome, #{name}."
                        broadcast "#{name} has joined the world.", target
                        @players[name] = Player.new( name, self, @starting_room.nil? ? @rooms.first : @starting_room, client, thread )
                        client.puts "Users Online: [#{ @players.keys.join(', ') }]\n\r"
                        @players[name].input_loop
                    end
                end

            end
        end
    end

    def game_loop
        loop do
            new_time = Time.now
            dt = new_time - @start_time
            @start_time = new_time

            @interval += dt
            # each update FRAME
            if @interval > ( 1.0 / Constants::FPS )
                @interval = 0
                @clock += 1

                update( 1.0 / Constants::FPS )
                send_to_client

                # each combat ROUND
                if @clock % Constants::ROUND == 0
                    combat
                end

                if @clock % Constants::RESET == 0
                    reset
                end
            end
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

    def dice( count, sides )
        count.times.collect{ rand(1..sides) }.sum
    end

    def target( query = {} )
        targets = @players.values + @items + @mobiles
        targets = targets.select { |t| query[:type].to_a.include? t.class.to_s }			                        if query[:type]
        targets = targets.select { |t| query[:visible_to].can_see? t }                                              if query[:visible_to]
        targets = targets.select { |t| query[:room].to_a.include? t.room }                                          if query[:room]
        # fix me: figure out a good way of getting the area for objects that are not directly in a room
        targets = targets.select { |t| t.room && query[:area].to_a.include?(t.room.area) }                          if query[:area]
        targets = targets.select { |t| !query[:not].to_a.include? t }                                               if query[:not]
        targets = targets.select { |t| query[:attacking].to_a.include? t.attacking }                                if query[:attacking]
        targets = targets.select { |t| t.fuzzy_match( query[:keyword] ) }                                       	if query[:keyword]
        targets = targets[0...query[:limit].to_i]                                                                   if query[:limit]
        targets = [ targets[ query[:offset] ] ]                                                                     if query[:offset]
        return targets
    end

    def disconnect( name )
        @players.delete( name )
        broadcast "#{name} has disconnected.", target
    end

    def reset
        @base_mob_resets.each do |reset_id, reset_data|
            reset = @mob_resets[reset_id]
            if @mob_data[ reset[:mobileVnum] ]
                mob_count = @mobiles.select { |m| m.vnum == reset[:mobileVnum] }.count
                if mob_count < reset[:roomMax]
                    mob = load_mob( reset[:mobileVnum], @rooms_hash[ reset[:roomVnum] ] )
                    @mobiles.push mob

                    # inventory
                    @inventory_resets.select{ |id, inventory_reset| inventory_reset[:parent] == reset_id }.each do | item_reset_id, item_reset |
                        if @item_data[ item_reset[:itemVnum] ]
                            item = load_item( item_reset[:itemVnum], nil )
                            mob.inventory.push item
                        else
                            puts "[Inventory item not found] RESET ID: #{item_reset_id}, ITEM VNUM: #{item_reset[:itemVnum]}, AREA: #{@base_resets[item_reset_id][:area]}"
                        end
                    end

                    #equipment
                    @equipment_resets.select{ |id, equipment_reset| equipment_reset[:parent] == reset_id }.each do | item_reset_id, item_reset |
                        if @item_data[ item_reset[:itemVnum] ]
                            item = load_item( item_reset[:itemVnum], nil )
                            ["", "_1", "_2"].each do | modifier |
                                slot = "#{item.wear_location}#{modifier}".to_sym
                                if mob.equipment.key?( slot ) and mob.equipment[slot] == nil
                                    mob.equipment[ slot ] = item
                                    if modifier == "_2"
                                        puts "Found multi-slot item #{mob} #{mob.room} #{item} #{slot}"
                                    end
                                    break
                                end
                            end
                        else
                            puts "[Equipped item not found] RESET ID: #{item_reset_id}, ITEM VNUM: #{item_reset[:itemVnum]}, AREA: #{@base_resets[item_reset_id][:area]}"
                        end
                    end

                    #containers ???
                end

            else
                puts "[Mob not found] RESET ID: #{reset[:id]}, MOB VNUM: #{reset[:mobileVnum]}"
            end
        end
    end

    def load_mob( vnum, room )
        row = @mob_data[ vnum ]
        Mobile.new( {
                vnum: vnum,
                keywords: row[:keywords].split(" "),
                short_description: row[:shortDesc],
                long_description: row[:longDesc],
                full_description: row[:fullDesc],
                race: row[:race],
                action_flags: row[:actFlags],
                affect_flags: row[:affFlags],
                alignment: row[:align].to_i,
                # mobgroup??
                hitroll: row[:hitroll].to_i,
                hitpoints: dice( row[:hpDiceCount].to_i, row[:hpDiceSides].to_i ) + row[:hpDiceBonus].to_i,
                #hp_range: row[:hpRange].split("-").map(&:to_i), # take lower end of range, maybe randomize later?
                hp_range: [500, 1000],
                # mana: row[:manaRange].split("-").map(&:to_i).first,
                mana: row[:mana].to_i,
                #damage_range: row[:damageRange].split("-").map(&:to_i),
                damage_range: [10, 20],
                damage: row[:damage].to_i,
                damage_type: row[:handToHandNoun].split(" ").first, # pierce, slash, none, etc.
                armor_class: [row[:acPierce], row[:acBash], row[:acSlash], row[:acMagic]],
                offensive_flags: row[:offFlags],
                immune_flags: row[:immFlags],
                resist_flags: row[:resFlags],
                vulnerable_flags: row[:vulnFlags],
                starting_position: row[:startPos],
                default_position: row[:defaultPos],
                sex: row[:sex],
                wealth: row[:wealth].to_i,
                form_flags: row[:formFlags],
                parts: row[:partFlags],
                size: row[:size],
                material: row[:material],
                level: row[:level]
            },
            self,
            room
        )
    end

    def load_item( vnum, room )
        row = @item_data[ vnum ]
        data = {
            short_description: row[:shortDesc],
            long_description: row[:longDesc],
            keywords: row[:keywords].split(" "),
            weight: row[:weight].to_i,
            cost: row[:cost].to_i,
            type: row[:type],
            level: row[:level].to_i,
            wear_location: row[:wearFlags].match(/(wear_\w+|wield)/).to_a[1].to_s.gsub("wear_", "")
        }
        if row[:type] == "weapon"
            weapon_info = @weapon_data[ vnum ]
            dice_info = @dice_data[ vnum ]
            if weapon_info and dice_info
                weapon_data = {
                    noun: weapon_info[:noun],
                    flags: weapon_info[:flags].split(" "),
                    element: weapon_info[:element],
                    dice_sides: dice_info[:sides].to_i,
                    dice_count: dice_info[:count].to_i
                }
                item = Weapon.new( data.merge( weapon_data ), self, room )
            else
                puts "[Weapon and/or Dice data not found] ITEM VNUM: #{vnum}"
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

    # temporary content-creation
    def setup_game

        # connect to database

        room_rows = @db[:RoomBase]
        exit_rows = @db[:RoomExit]

        # create a room_row[:vnum] hash, create rooms
        @rooms_hash = {}
        @areas_hash = {}

        room_rows.each do |row|

        	area = @areas_hash[row[:area]] || Area.new( row[:area], row[:continent], self )
        	@areas_hash[row[:area]] = area
        	@areas.push area

            @rooms.push Room.new( row[:name], row[:description], row[:sector], area, row[:flags].to_s.split(" "), row[:hp].to_i, row[:mana].to_i, row[:continent], self )
            @rooms_hash[row[:vnum]] = @rooms.last
            if row[:vnum] == 31000
                @starting_room = @rooms.last
            end

        end

        # assign each exit to its room in the hash (if the destination exists)
        exit_rows.each do |exit|
            if @rooms_hash.key?(exit[:roomVnum]) && @rooms_hash.key?(exit[:toVnum])
                @rooms_hash[exit[:roomVnum]].exits[exit[:direction].to_sym] = @rooms_hash[exit[:toVnum]]
            end
        end

        puts ( "Rooms loaded from database." )

        @mob_data = @db[:mobilebase].as_hash(:vnum)
        @item_data = @db[:itembase].as_hash(:vnum)
        @weapon_data = @db[:ItemWeapon].as_hash(:itemVnum)
        @dice_data = @db[:ItemDice].as_hash(:itemVnum)

        @mob_resets = @db[:resetmobile].as_hash(:id)
        @inventory_resets = @db[:resetinventoryitem].as_hash(:id)
        @equipment_resets = @db[:resetequippeditem].as_hash(:id)
        # @base_resets = @db[:resetbase].where( area: "Shandalar" ).as_hash(:id)
        @base_resets = @db[:resetbase].as_hash(:id)
        @base_mob_resets = @base_resets.select{ |key, value| value[:type] == "mobile" }

        reset

        puts( "Mob Data and Resets loaded from database.")

        @areas_hash.each do | area_name, area |
            @areas_hash[ area_name ] = @rooms.select{ | room | room.area == area }
        end

        @helps = @db[:HelpBase].all
        @helps.each { |help| help[:keywords] = help[:keywords].split(" ") }

        puts ( "Helpfiles loaded from database." )
    end

    def do_command( actor, cmd, args = [] )
    	@commands.each do | command |
    		if command.check( cmd )
    			command.execute( actor, args )
    			return
    		end
    	end
    	actor.output "Huh?"
    end

    def make_commands
    	@commands = [
    		Command.new( [""] ),
    		Down.new( ["down"], 0.5 ),
    		Up.new( ["up"], 0.5 ),
    		East.new( ["east"], 0.5 ),
    		West.new( ["west"], 0.5 ),
    		North.new( ["north"], 0.5 ),
    		South.new( ["south"], 0.5 ),
    		Who.new( ["who"] ),
    		Help.new( ["help"], @helps ),
    		Qui.new( ["qui"] ),
    		Quit.new( ["quit"] ),
    		Look.new( ["look"] ),
            Say.new( ["say", "'"] ),
            Yell.new( ["yell"] ),
    		Kill.new( ["hit", "kill"], 0.5 ),
    		Flee.new( ["flee"], 0.5 ),
    		Get.new( ["get", "take"] ),
    		Drop.new( ["drop"] ),
            Inventory.new( ["inventory"] ),
            Equipment.new( ["equipment"] ),
            Wear.new( ["wear", "hold", "wield"] ),
            Remove.new( ["remove"] ),
            Blind.new( ["blind"] ),
            Unblind.new( ["unblind"] ),
            Peek.new( ["peek"] ),
            Recall.new( ["/", "recall"] ),
            GoTo.new( ["goto"], self ),
    	]
    end

    def recall_room( continent )
        room = (continent == "terra" ? @rooms_hash[3001] : @rooms_hash[31000])
        return room
    end

    def area_with_name( name )
        @areas.select { |area| area.name.fuzzy_match( name ) }.first
    end

    def first_room_in_area( area )
        @areas_hash[area.name].first
    end

end
