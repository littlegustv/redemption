class Room < GameObject

    attr_reader :id
    attr_reader :inventory
    attr_reader :sector
    attr_reader :hp_regen
    attr_reader :mana_regen

    def initialize(id, name, short_description, sector, area, hp_regen, mana_regen)
        super(name.freeze, nil)
        @id = id
        @short_description = short_description.freeze
        @sector = sector
        @area = area
        @hp_regen = hp_regen
        @mana_regen = mana_regen
        @exits = nil
        @entrances = nil
        @mobiles = nil
        @players = nil
        @inventory = Inventory.new(self)
    end

    def destroy
        super
        @area.rooms.delete self
        if @exits
            @exits.dup.each do |direction, exit|
                remove_exit(exit)
            end
        end
        if @entrances
            @entrances.dup.each do |entrance|
                entrance.source.remove_exit(entrance)
                entrance.destroy
            end
        end
        @inventory.items.dup.each do |item|
            item.destroy
        end
        if @mobiles
            @mobiles.dup.each do |mob|
                mob.destroy
            end
        end
        if @players
            @players.dup.each do |player|
                player.move_to_room(Game.instance.starting_room)
            end
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
            "[Exits: #{ @exits.select { |direction, room| not room.nil? }.map{ |k, v| v.to_s }.join(" ") }]"
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
            if @players
                @players.delete(mobile)
                @players.unshift(mobile)
            else
                @players = [mobile]
            end
        else
            if @mobiles
                @mobiles.unshift(mobile)
            else
                @mobiles = [mobile]
            end
        end
        Game.instance.fire_event(self, :event_room_mobile_enter, {mobile: mobile})
    end

    def mobile_exit(mobile)
        if mobile.is_player?
            @players.delete(mobile)
            if @players.empty?
                @players = nil
            end
        else
            @mobiles.delete(mobile)
            if @mobiles.empty?
                @mobiles = nil
            end
        end
        Game.instance.fire_event(self, :event_room_mobile_exit, {mobile: mobile})
    end

    # Returns true if the room contains ALL mobiles (an array of players and/or mobiles)
    def contains?(mobiles)
        return (mobiles.to_a - occupants).empty?
    end

    def players
        @players || []
    end

    def mobiles
        @mobiles || []
    end

    def occupants
        return @mobiles.to_a | @players.to_a
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

    def add_exit(direction, exit)
        if !@exits
            @exits = {}
        end
        exit.destination.add_entrance(exit)
        @exits[direction] = exit
    end

    def remove_exit(exit)
        if !@exits
            return
        end
        exit.destination.remove_entrance(exit)
        @exits.delete_if { |k,v| v == exit }
        if @exits.empty?
            @exits = nil
        end
    end

    # adds an Exit object to the list of exits that lead to this room
    def add_entrance(exit)
        if !@entrances
            @entrances = []
        end
        @entrances << exit
    end

    def remove_entrance(exit)
        if !@entrances
            return
        end
        @entrances.delete(exit)
        if @entrances.empty?
            @entrances = nil
        end
    end

    def exits
        @exits || {}
    end

end
