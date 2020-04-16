class Room < GameObject

    attr_accessor :area
    attr_accessor :exits

    attr_reader :id
    attr_reader :inventory
    attr_reader :mobiles
    attr_reader :players
    attr_reader :sector

    def initialize(name, id, short_description, sector, area, hp_regen, mana_regen)
        super(name, nil)
        @id = id
        @short_description = short_description
        @sector = sector
        @area = area
        @hp_regen = hp_regen
        @mana_regen = mana_regen

        @exits = { north: nil, south: nil, east: nil, west: nil, up: nil, down: nil }
        @mobiles = []
        @players = []
        @inventory = Inventory.new(self)
    end

    def show( looker )
        if looker.can_see? self
            out = "#{ @name }\n" +
            "  #{ @short_description }\n" +
            "[Exits: #{ @exits.select { |direction, room| not room.nil? }.map{ |k, v| v.to_s }.join(", ") }]"
            description_data = {extra_show: ""}
            Game.instance.fire_event(self, :event_calculate_room_description, description_data)
            out += description_data[:extra_show]
        else
            out = "It is pitch black ..."
        end
        item_list = @inventory.show(observer: looker, short_description: true)
        out += "\n#{item_list}" if item_list.length > 0

        visible_occupant_longs = Game.instance.target({ list: self.occupants, :not => looker, visible_to: looker }).map{ |t| t.show_short_description(observer: looker) }
        out += "\n#{visible_occupant_longs.join("\n")}" if visible_occupant_longs.length > 0
        return out
    end

    def mobile_enter(mobile)
        if mobile.is_player?
            @players.delete(mobile)
            @players.unshift(mobile)
        else
            @mobiles.unshift(mobile)
        end
        Game.instance.fire_event(self, :event_room_mobile_enter, {mobile: mobile})
    end

    def mobile_exit(mobile)
        if mobile.is_player?
            @players.delete(mobile)
        else
            @mobiles.delete(mobile)
        end
        Game.instance.fire_event(self, :event_room_mobile_exit, {mobile: mobile})
    end

    # Returns true if the room contains ALL mobiles (an array of players and/or mobiles)
    def contains?(mobiles)
        return (mobiles.to_a - occupants).empty?
    end

    def occupants
        return @mobiles | @players
    end

    def items
        if @inventory
            return @inventory.items
        else
            return []
        end
    end

    def get_item(item)
        item.move(@inventory)
    end

    def db_source_type
        return "Room"
    end

    # sort of a hack to add a room method to items
    def room
        return self
    end

    def continent
        @area.continent
    end

end
