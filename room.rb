class Room < GameObject

    attr_accessor :exits

    attr_reader :id
    attr_reader :inventory
    attr_reader :mobiles
    attr_reader :players
    attr_reader :sector
    attr_reader :hp_regen
    attr_reader :mana_regen

    def initialize(id, name, short_description, sector, area, hp_regen, mana_regen)
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

    def destroy
        super
        @area.rooms.delete self
        @exits.dup.each do |direction, exit|
            # exit.destroy
        end
        @inventory.items.dup.each do |item|
            item.destroy
        end
        @mobiles.dup.each do |mob|
            mob.destroy
        end
        @players.dup.each do |player|
            player.move_to_room(Game.instance.starting_room)
        end
        @area = nil
        @exits = nil
        @inventory = nil
        @mobiles = nil
        @players = nil
        Game.instance.destroy_room(self)
    end

    def self.inactive_room
        if @inactive_room.nil?
            @inactive_room = Room.new("inactive room", 0, "no description", :inside.to_sector, nil, 0, 0)
            @inactive_room.deactivate
        end
        return @inactive_room
    end

    def area
        return @area || Area.inactive_area
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

        visible_occupant_longs = Game.instance.target({ list: self.occupants, :not => looker, visible_to: looker }).map{ |t| t.show_short_description(looker) }
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

    def db_source_type_id
        return 4
    end

    # sort of a hack to add a room method to items
    def room
        return self
    end

    def continent
        @area.continent
    end

end
