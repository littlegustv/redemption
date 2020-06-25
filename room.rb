#
# The Room object.
#
class Room < GameObject

    # @return [Integer] The ID of the room. Returns 0 if it has none.
    attr_reader :id
    
    # @return [Inventory] The room's inventory.
    attr_reader :inventory
    
    # @return [Sector] The sector for the room.
    attr_reader :sector
    
    # @return [Float] The Health regen multiplier for the room.
    attr_reader :hp_regen

    # @return [Float] The Mana regen multiplier for the room.
    attr_reader :mana_regen

    #
    # Room initializer.
    #
    # @param [Integer, nil] id The ID of the room, or `nil` if it doesn't have one.
    # @param [String, nil] name The name of the room.
    # @param [String] short_description The short description of the room.
    # @param [Sector, Symbol] sector The sector for the room, or its symbol.
    # @param [Area] area The area this room belongs to.
    # @param [Float] hp_regen The Health regen multiplier for the room.
    # @param [Float] mana_regen The Mana regen multiplier for the room.
    #
    def initialize(id, name, short_description, sector, area, hp_regen, mana_regen)
        name = name.to_s
        short_description = short_description.to_s
        super(name.freeze, nil)
        @id = id || 0
        @short_description = short_description.freeze
        @sector = sector.to_sector
        @area = area
        @hp_regen = hp_regen.to_f
        @mana_regen = mana_regen.to_f
        @exits = nil
        @entrances = nil
        @mobiles = nil
        @players = nil
        @inventory = Inventory.new(self)
    end

    #
    # Destroys this room.
    # Removes it from its area.
    # Destroys entrances and exits.
    # Destroys items in its inventory.
    # 
    #
    # @return [nil]
    #
    def destroy
        super
        @area.rooms.delete self
        if @exits
            @exits.dup.each do |exit|
                exit.destroy
            end
        end
        if @entrances
            @entrances.dup.each do |entrance|
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
        Game.instance.remove_room(self)
    end

    #
    # Gets the inactive room. This is basically just a deactivated Room object that other
    # GameObjects can regerence if they've been removed from the game but still have
    # affects or something else that causes game logic to be executed on them.
    #
    # @return [Room] The inactive room.
    #
    def self.inactive_room
        if @inactive_room.nil?
            @inactive_room = Room.new("inactive room", 0, "no description", :inside.to_sector, nil, 0, 0)
            @inactive_room.deactivate
        end
        return @inactive_room
    end

    #
    # Gets the Area object for this Room. Can be Area#inactive_area if the room has been destroyed.
    #
    # @return [Area] The area.
    #
    def area
        return @area || Area.inactive_area
    end

    #
    # Generates a string representation of this room from the perspective of an observer.
    #
    # @param [GameObject] observer The observer.
    #
    # @return [String] The string output.
    #
    def show( observer )
        if observer.can_see? self
            out = "#{ @name }\n" +
            "  #{ @short_description }\n\n" +
            "[Exits: #{ @exits.select.map(&:to_s).join(" ") }]"
            description_data = {extra_show: ""}
            Game.instance.fire_event(self, :calculate_room_description, description_data)
            out += description_data[:extra_show]
        else
            out = "It is pitch black ..."
        end
        item_list = @inventory.show(observer, true, nil)
        out += "\n#{item_list}" if item_list

        visible_occupant_longs = observer.target(list: occupants, not: observer).map{ |t| t.show_short_description(observer) }
        out += "\n#{visible_occupant_longs.join("\n")}" if visible_occupant_longs.length > 0
        return out
    end

    #
    # This is called whenever a mobile enters the room.
    #
    # __Don't call this, except from inside Mobile#move_to_room.__
    #
    # @param [Mobile] mobile The mobile.
    #
    # @return [nil]
    #
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
        Game.instance.fire_event(self, :room_mobile_enter, {mobile: mobile})
        return
    end

    #
    # This is called whenever a mobile enters the room.
    #
    # __Don't call this, except from inside Mobile#move_to_room.__
    #
    # @param [Mobile] mobile The mobile.
    #
    # @return [nil]
    #
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
        Game.instance.fire_event(self, :room_mobile_exit, {mobile: mobile})
        return
    end

    #
    # Returns true if the room contains ALL mobiles (an array of players and/or mobiles).
    #
    # @param [Array<Mobile>, Mobile] mobiles A Mobile of Array of Mobiles.
    #
    # @return [Boolean] True if this room contains ALL of the `mobiles` passed in.
    #
    def contains?(mobiles)
        return (mobiles.to_a - occupants).empty?
    end

    #
    # Returns the array of players in this room
    #
    # @return [Array<Player>] The players.
    #
    def players
        @players || []
    end

    #
    # Returns the array of mobiles in this room (NOT including players).
    #
    # @return [Arary<Mobile>] The mobiles.
    #
    def mobiles
        @mobiles || []
    end

    #
    # Returns the combined array of Mobiles and Players in this room.
    #
    # @return [Array<Mobile>] The players and mobiles in the room.
    #
    def occupants
        return @mobiles.to_a | @players.to_a
    end

    #
    # Returns an array containing the items in this room's inventory.
    #
    # @return [Array<Item>] The items.
    #
    def items
        if @inventory
            return @inventory.items
        else
            return []
        end
    end

    #
    # Moves an item into this room's inventory.
    #
    # @param [Item] item The item to move.
    #
    # @return [Boolean] Returns true if the item moved, otherwise false.
    #
    def get_item(item)
        return item.move(@inventory)
    end

    #
    # Sort of a hack to add a room method to items.
    #
    # @return [Room] This room object.
    #
    def room
        return self
    end

    #
    # Returns the continent for this room's area. Can be Continent#inactive_continent.
    #
    # @return [Continent] The continent.
    #
    def continent
        @area.continent
    end

    #
    # Add an exit to this room.
    #
    # @param [Exit] exit The exit to add.
    #
    # @return [nil]
    #
    def add_exit(exit)
        if !@exits
            @exits = []
        end
        @exits << exit
        @exits.sort_by!{ |exit| exit.direction.id }
        return
    end

    #
    # Remove an exit from this room.
    #
    # @param [Exit] exit The exit to remove.
    #
    # @return [nil] 
    #
    def remove_exit(exit)
        if !@exits
            return
        end
        @exits.delete(exit)
        if @exits.empty?
            @exits = nil
        end
        return
    end

    #
    # Add an Exit object to the array of exits that lead to this room.
    #
    # @param [Exit] exit The exit leading to this room.
    #
    # @return [nil]
    #
    def add_entrance(exit)
        if !@entrances
            @entrances = []
        end
        @entrances << exit
        return
    end

    #
    # Remove an Exit object from the array of exits that lead to this room.
    #
    # @param [Exit] exit The Exit to remove.
    #
    # @return [nil]
    #
    def remove_entrance(exit)
        if !@entrances
            return
        end
        @entrances.delete(exit)
        if @entrances.empty?
            @entrances = nil
        end
        resolve_personal_objective_pronoun
    end

    #
    # Returns an array of Exits that lead from this Room to other Rooms.
    #
    # @return [Array<Exit>] The exits.
    #
    def exits
        exits = (@exits || []) + self.items.reject{|i| !i.is_a?(Portal) }.map(&:exit)
        return exits
    end

    #
    # Returns an array of all rooms connected to this one through exits and entrances.
    #
    # @return [Array<Room>] The connected rooms.
    #
    def connected_rooms
        return (self.exits.map(&:destination) + @entrances.to_a).reject{ |room| room == self }
    end

end
