require 'sequel'

class Game

    def initialize( ip_address, port )


        puts "Opening server on #{ip_address}:#{port}"
        @server = TCPServer.open( ip_address, port )

        host, port, username, password = File.read( "server_config.txt" ).split("\n").map{ |line| line.split(" ")[1] }

        @players = Hash.new
        @items = []
        @mobiles = []
        @rooms = []
        @areas = []
        @starting_room = nil

       #begin
            @db = Sequel.mysql2( :host => host, :username => username, :password => password, :database => "redemption" )
            load_rooms
       #rescue
       #     make_rooms
       #end

        make_commands

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
                    client.puts "By what name do you wish to be known?"
                    name = client.gets.chomp.to_s

                    if name.length <= 2
                        client.puts "Your name must be at least three characters."
                        name = nil
                    elsif @players.has_key? name
                        client.puts "That name is already in use, try another."
                        name = nil
                    else
                        client.puts "Welcome, #{name}."
                        broadcast "#{name} has joined the world.", target
                        @players[name] = Player.new( name, self, @starting_room.nil? ? @rooms.first : @starting_room, client, thread )
                        client.puts "Users Online: [#{ @players.keys.join(', ') }]"
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

    def broadcast( message, targets )
        targets.each do | player |
            player.output( message )
        end
    end

    # right now this is just for players??
    def target( query = {} )
        targets = @players.values + @items + @mobiles
        targets = targets.select { |t| query[:type].to_a.include? t.class.to_s }			                        if query[:type]
        targets = targets.select { |t| query[:room].to_a.include? t.room }                                          if query[:room]
        targets = targets.select { |t| !query[:not].to_a.include? t }                                               if query[:not]
        targets = targets.select { |t| query[:attacking].to_a.include? t.attacking }                                if query[:attacking]
        targets = targets.select { |t| t.fuzzy_match( query[:keyword] ) }                                       	if query[:keyword]
        targets = targets[0...query[:limit].to_i] if query[:limit]
        return targets
    end

    def disconnect( name )
        @players.delete( name )
        broadcast "#{name} has disconnected.", target
    end

    # temporary content-creation
    def load_rooms

        # connect to database

        room_rows = @db[:Room]
        exit_rows = @db[:RoomExit]

        # create a room_row[:vnum] hash, create rooms
        rooms_hash = {}
        areas_hash = {}

        room_rows.each do |row|
        	
        	area = areas_hash[row[:area]] || Area.new( row[:area], row[:continent], self )
        	areas_hash[row[:area]] = area
        	@areas.push area

            @rooms.push Room.new( row[:name], row[:description], row[:sector], area, row[:flags].to_s.split(" "), row[:hp].to_i, row[:mana].to_i, self )
            rooms_hash[row[:vnum]] = @rooms.last
            if row[:vnum] == 31000
                @starting_room = @rooms.last
            end

        end

        # assign each exit to its room in the hash (if the destination exists)
        exit_rows.each do |exit|
            if rooms_hash.key?(exit[:roomVnum]) && rooms_hash.key?(exit[:toVnum])
                rooms_hash[exit[:roomVnum]].exits[exit[:direction].to_sym] = rooms_hash[exit[:toVnum]]
            end
        end

        puts ( "Rooms loaded from database." )

        # temporary: load all rooms into area hash, to randomly put mobiles and items in the right area
        areas_hash.each do | area_name, area |
            areas_hash[ area_name ] = @rooms.select{ | room | room.area == area }
        end

        item_rows = @db[:Item]

        item_rows.each do |row|
            if areas_hash[ row[:area] ]
                data = {
                    short_description: row[:short],
                    long_description: row[:description],
                    keywords: row[:name].split(" "),
                    weight: row[:weight].to_i,
                    cost: row[:cost].to_i,
                    type: row[:type],
                    level: row[:level].to_i,
                    wear_location: row[:wearFlags].match(/(wear_\w+|wield)/).to_a[1].to_s.gsub("wear_", "")
                }
                if row[:type] == "weapon"
                    weapon_info = @db["select * from Weapon where itemVnum = #{ row[:vnum] }"].first
                    dice_info = @db["select * from Dice where itemVnum = #{ row[:vnum] }"].first
                    weapon_data = {
                        noun: weapon_info[:noun],
                        flags: weapon_info[:flags].split(" "),
                        element: weapon_info[:element],
                        dice_sides: dice_info[:sides].to_i,
                        dice_count: dice_info[:count].to_i
                    }
                    @items.push Weapon.new( data.merge( weapon_data ), 
                        self, 
                        areas_hash[ row[:area] ].sample
                    )
                else
                    @items.push Item.new( data, 
                        self, 
                        areas_hash[ row[:area] ].sample
                    )
                end
            end
        end

        puts ( "Items loaded from database." )

        mobile_rows = @db[:Mobile]

        mobile_rows.each do |row|
            if areas_hash[ row[:area] ]
                @mobiles.push Mobile.new( {
                        keywords: row[:keywords].split(" "),
                        short_description: row[:shortDesc],
                        long_description: row[:longDesc],
                        full_description: row[:description],
                        race: row[:race],
                        action_flags: row[:actFlags],
                        affect_flags: row[:affFlags],
                        alignment: row[:align].to_i,
                        # mobgroup??
                        hitroll: row[:hitroll].to_i,
                        hitpoints: row[:hp].to_i,
                        hp_range: row[:hpRange].split("-").map(&:to_i), # take lower end of range, maybe randomize later?
                        # mana: row[:manaRange].split("-").map(&:to_i).first,
                        mana: row[:mana].to_i,
                        damage_range: row[:damageRange].split("-").map(&:to_i),
                        damage: row[:damage].to_i,
                        damage_type: row[:attack].split(" ").first, # pierce, slash, none, etc.
                        armor_class: row[:ac].split(" ").map(&:to_i),
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
                    areas_hash[ row[:area] ].sample 
                ) 
            end
        end

        puts ( "Mobiles loaded from database." )

    end

    def make_rooms
        area = Area.new( "Default", "Terra", self )
        @areas.push area

        10.times do |i|
            @rooms.push Room.new( "Room no. #{i}", "#{i} description", "forest", area, [], 100, 100, self )
        end

        @rooms.each_with_index do |room, index|
            room.exits[:north] = @rooms[ (index + 1) % @rooms.count ]
            @rooms[ (index + 1) % @rooms.count ].exits[:south] = room
        end

        @starting_room = @rooms.first

        # m = Mobile.new "Cuervo", self, @starting_room
        # @mobiles.push m

        # i = Item.new "A Teddy Bear", self, @starting_room
        # @items.push i

        puts ( "Rooms created ( no database found )." )
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
    		Down.new( ["down"], 0.5 ),
    		Up.new( ["up"], 0.5 ),
    		East.new( ["east"], 0.5 ),
    		West.new( ["west"], 0.5 ),
    		North.new( ["north"], 0.5 ),
    		South.new( ["south"], 0.5 ),
    		Who.new( ["who"] ),
    		Help.new( ["help"] ),
    		Qui.new( ["qui"] ),
    		Quit.new( ["quit"] ),
    		Look.new( ["look"] ),
    		Say.new( ["say", "'"] ),
    		Kill.new( ["hit", "kill"], 0.5 ),
    		Flee.new( ["flee"], 0.5 ),
    		Get.new( ["get", "take"] ),
    		Drop.new( ["drop"] ),
            Inventory.new( ["inventory"] ),
            Equipment.new( ["equipment"] ),
            Wear.new( ["wear", "hold", "wield"] ),
            Remove.new( ["remove"] ),
    	]
    end
end
