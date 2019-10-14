class Room < GameObject

    attr_accessor :area
    attr_accessor :continent
    attr_accessor :exits

    attr_reader :id
    attr_reader :inventory
    attr_reader :mobiles
    attr_reader :mobile_count
    attr_reader :players

    def initialize( id, name, description, sector, area, flags, hp_regen, mana_regen, game, exits = {} )
        super(name, name.split(" "), game)
        @exits = { north: nil, south: nil, east: nil, west: nil, up: nil, down: nil }
        @exits.each do | direction, room |                  # Exits exist as a hash.
            if not exits[ direction ].nil?                  #  Key is direction (as a string)
                @exits[ direction ] = exits[ direction ]    #  Value is the room object in that direction.
            end
        end
        @id = id
        @description = description
        @sector = sector
        @area = area
        @flags = flags
        @hp_regen = hp_regen
        @mana_regen = mana_regen
        @continent = area.continent
        @mobiles = []
        @mobile_count = {}
        @players = []
        @inventory = Inventory.new(owner: self, game: @game)
    end

    def show( looker )
        if looker.can_see? self
            out = "#{ @name }\n" +
            "#{ @description }\n" +
            "[Exits: #{ @exits.select { |direction, room| not room.nil? }.keys.join(", ") }]"
            item_list = @inventory.show(observer: looker, long: true)
            description_data = {extra_show: ""}
            @game.fire_event(self, :event_calculate_room_description, description_data)
            out += description_data[:extra_show]
            out += "\n#{item_list}" if item_list.length > 0
            visible_occupant_longs = @game.target({ list: self.occupants, :not => looker, visible_to: looker }).map{ |t| t.show_long_description(observer: looker) }
            out += "\n#{visible_occupant_longs.join("\n")}" if visible_occupant_longs.length > 0
            return out
        else
            return "You can't see a thing!"
        end
    end

    def mobile_enter(mobile)
        if mobile.is_player?
            @players.delete(mobile)
            @players.unshift(mobile)
        else
            @mobiles.unshift(mobile)
            @mobile_count[mobile.id] = @mobile_count[mobile.id].to_i + 1
            @mobile_count.delete(mobile.id) if @mobile_count[mobile.id] <= 0
        end
        @game.fire_event(self, :event_room_mobile_enter, {mobile: mobile})
    end

    def mobile_exit(mobile)
        if mobile.is_player?
            @players.delete(mobile)
        else
            @mobiles.delete(mobile)
            @mobile_count[mobile.id] = @mobile_count[mobile.id] - 1
            @mobile_count.delete(mobile.id) if @mobile_count[mobile.id] <= 0
        end
        @game.fire_event(self, :event_room_mobile_exit, {mobile: mobile})
    end

    # Returns true if the room contains ALL mobiles (an array of players and/or mobiles)
    def contains?(mobiles)
        return (mobiles.to_a - occupants).empty?
    end

    def occupants
        return @mobiles | @players
    end

    def items
        return @inventory.items
    end

    def db_source_type
        return "Room"
    end

    # sort of a hack to add a room method to items
    def room
        return self
    end

end
