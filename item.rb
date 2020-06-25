class Item < GameObject

    # @return [Float] The weight of the Item.
    attr_accessor :weight
    
    # @return [Integer]] The cost of the item in silver.
    attr_accessor :cost
    
    # @return [Inventory, nil] The parent Inventory of this object, or `nil` if it's "not really anywhere".
    attr_reader :parent_inventory
    
    # @return [Material] The material for this item.
    attr_reader :material
    
    # @return [Integer] The level for this item.
    attr_reader :level

    #
    # Item initialization. `parent_inventory` can be set to `nil` in cases where the item is going to
    # immediately leave the game. (Item source loading from database)
    #
    # @param [Model] model The model that describes this item.
    # @param [Inventory] parent_inventory The inventory this item is going into.
    # @param [Reset, nil] reset The reset responsible for this item.
    #
    def initialize( model, parent_inventory, reset = nil )
        super(nil, nil, reset, model)
        @model = model
        @name = nil
        @level = model.level
        @weight = model.weight
        @cost = @model.cost
        @material = @model.material

        @parent_inventory = nil
        @modifiers = model.modifiers.dup
        move(parent_inventory)
        if @model.affect_models
            @model.affect_models.each do |affect_model|
                self.apply_affect_model(affect_model, true)
            end
        end

    end

    #
    # Destroys this Item. Moves to a `nil` inventory.
    # Call Game#remove_item for removal from global lists.
    #
    # @return [nil]
    #
    def destroy
        super
        self.move(nil)
        Game.instance.remove_item(self)
    end

    #
    # The type name of this Item class. Override. for each Item subclass.
    #
    # @return [String] The type name.
    #
    def type_name
        "item"
    end

    #
    # Returns the ID of the item by retrieving it from the model.
    #
    # @return [Integer, nil] The ID, or `nil` if it doesn't have one.
    #
    def id
        if @model
            return @model.id
        end
        return nil
    end

    #
    # Generate a store listing string for this Item.
    #
    # @param [Integer] quantity The quantity of this item in the listing.
    #
    # @return [String] The listing string.
    #
    def to_store_listing( quantity )
        "[#{@level.to_s.lpad(2)} #{carrier.sell_price( self ).to_s.lpad(7)} #{ [quantity, 99].min.to_s.lpad(2) } ] #{self.name}"
    end

    #
    # Returns the modifier value for a given stat.
    #
    # @param [Stat, Symbol] s The stat as a Symbol or Stat.
    #
    # @return [Integer] The modifier value.
    #
    def modifier( s )
        s = s.to_stat
        return @modifiers.nil? ? 0 : @modifiers.dig(s).to_i
    end

    #
    # Returns a String describing the various parts of this Item.
    # Item subclasses can override this method to show more or less information.
    #
    # @return [String] The description.
    #
    def lore
        output = self.pre_lore
        output += self.post_lore
        return output
    end

    #
    # The first part of the `lore` output.
    #
    # @return [String] The output.
    #
    def pre_lore
        output = "Object '#{ self.name }' is of type #{ self.type_name }.\n"
        output += "Description: #{ self.short_description }\n"
        output += "Keywords '#{ self.keywords.to_s }'\n"
        output += "Weight #{ @weight } lbs, Value #{ @cost } silver, level is #{ @level }, Material is #{ @material.name }."
        return output
    end

    #
    # The last part of the `lore` output.
    # Wear locations, Modifiers, and Affects.
    #
    # @return [String] The output.
    #
    def post_lore
        output = ""
        if wear_locations.size > 0
            output += "\nItem can #{wear_locations.map(&:display_string).to_list("or")}."
        end
        if @modifiers
            output += "\n" + @modifiers.map { |stat, value| "Object modifies #{stat.name} by #{value}#{stat.percent?}." }.join("\n")
        end
        if @affects && @affects.size > 0
            output += "\n" + self.show_affects
        end
        return output
    end

    #
    # Move this item to another inventory - nil is passed when an item is going to be destroyed.
    #
    # @param [Inventory, EquipSlot, nil] new_inventory The inventory to move to, or `nil` when it's going to be destroyed.
    #
    # @return [Boolean] True if the item was moved, otherwise false.
    #
    def move(new_inventory)
        if @reset && @parent_inventory && @parent_inventory.owner.active && (new_inventory.nil? || @parent_inventory.owner != new_inventory.owner)
            @reset.activate(false, @parent_inventory.owner)
            unlink_reset
        end
        if @parent_inventory == new_inventory
            return false
        end
        if @parent_inventory
            if equipped?
                Game.instance.fire_event(self, :item_unwear, {mobile: carrier})
            end
            @parent_inventory.remove_item(self)
        end
        @parent_inventory = new_inventory
        if new_inventory
            new_inventory.add_item(self)
            if equipped?
                Game.instance.fire_event(self, :item_wear, {mobile: carrier})
            end
        end
        return true
    end

    #
    # Removes the reference to this object's reset. Used when an object triggers its reset, or 
    # if this object was inside a container whose reset has been activated.
    #
    # @return [nil]
    #
    def unlink_reset
        @reset = nil
        return
    end

    #
    # Returns the room this object is in, whether it's in a room directly, in a mobile inventory/equip_slot,
    # or in another item.
    #
    # @return [Room] The room.
    #
    def room
        if @parent_inventory.nil?
            return Room.inactive_room
        end
        return @parent_inventory.owner.room
    end

    #
    # Returns the gameobject that carries this item, whether it's the room that this object is on
    # the floor in, a mobile with this item in a container, or just a mobile with this in an equip_slot.
    #
    # @return [GameObject] The carrier of this item.
    #
    def carrier
        if @parent_inventory.nil?
            return Room.inactive_room
        end
        owner = @parent_inventory.owner
        while Item === owner
            owner = owner.parent_inventory.owner
        end
        return owner
    end

    #
    # True or false - item is equipped?
    #
    # @return [Boolean] True if the item is in an EquipSlot, otherwise false.
    #
    def equipped?
        return @parent_inventory.is_a?(EquipSlot)
    end

    #
    # Returns the array of WearLocation objects for this item as an array.
    #
    # @return [Array<WearLocation>] The wear locations
    #
    def wear_locations
        return @model.wear_locations.to_a
    end

    #
    # Returns true if the Item is fixed. A fixed Item cannot be picked up.
    #
    # @return [Boolean] True if the Item is fixed, otherwise false.
    #
    def fixed
        @model.fixed
    end

end

class Weapon < Item

    # @return [Noun] The noun for this weapon. (Stab, Slash, Fireball, etc)
    attr_reader :noun
    
    # @return [Genre] The genre for this weapon. (Dagger, Sword, Polearm, etc)
    attr_reader :genre

	def initialize( model, parent_inventory, reset = nil )
		super(model, parent_inventory, reset)

		@noun = model.noun
        @genre = model.genre
		@dice_count = model.dice_count
		@dice_sides = model.dice_sides
	end

    def lore
        output = self.pre_lore
        output += "\nDamage is #{@dice_count}d#{@dice_sides} (#{@dice_count}-#{@dice_count*@dice_sides}, average #{@dice_count * (1 + @dice_sides) / 2})."
        output += "\nAttack speed is #{@genre.attack_speed}."
        output += self.post_lore
        return output
    end

    def type_name
        "weapon"
    end

	#
    # Returns a damage roll from this weapon by rolling its dice.
    #
    # @return [Float] The damage.
    #
    def damage
        dice( @dice_count, @dice_sides )
	end

    #
    # Returns the attack speed for the weapon. Value is based solely on the weapon's genre.
    #
    # @return [Float] The attack speed.
    #
    def attack_speed
        @genre.attack_speed
    end

end

class Container < Item

    # @return [Inventory] The inventory for this container.
    attr_accessor :inventory

	def initialize( model, parent_inventory, reset = nil )
        @inventory = Inventory.new(self)
        super(model, parent_inventory, reset)
        @max_item_weight = model.max_item_weight
        @weight_multiplier = model.weight_multiplier
        @max_total_weight = model.max_total_weight
        @key_id = model.key_id
    end
    
    #
    # Destroy this container.
    # Destroys all items in its inventory.
    # Calls Item#destroy.
    #
    # @return [nil]
    #
    def destroy
        @inventory.items.dup.each do |item|
            item.destroy
        end
        super
        return
    end

    #
    # Override of Item#move to handle reset unlinking for contained objects.
    #
    # @param [Inventory] new_inventory The new inventory to move to.
    #
    # @return [Boolean] True if the container actually moved.
    #
    def move(new_inventory)
        @inventory.items.each do |item|
            item.unlink_reset
        end
        return super(new_inventory)
    end

    def type_name
        "container"
    end

    #
    # Returns the array of items inside this Container.
    #
    # @return [Array<Item>] The array of items.
    #
    def items
        return Inventory.items.dup
    end

    #
    # Moves an item into this Container's Inventory.
    #
    # @param [Item] item The item to move.
    #
    # @return [Boolean] True if the item moved, otherwise false.
    #
    def get_item(item)
        return item.move(@inventory)
    end

    #
    # Container has to override Item#unlink_reset to also unlink any resets of its contained items.
    #
    # @return [nil]
    #
    def unlink_reset
        @reset = nil
        if @inventory
            @inventory.items.each do |item|
                item.unlink_reset
            end
        end
        return
    end

end

class Consumable < Item

    def initialize( model, parent_inventory, reset = nil )
        super( model, parent_inventory, reset )
        @ability_instances = model.ability_instances
    end

    def type_name
        "consumable"
    end

    #
    # Attempt the ability instances of this consumable on a Mobile.
    #
    # @param [Mobile] actor The Mobile doing the consumption.
    #
    # @return [nil]
    #
    def consume( actor )
        @ability_instances.each do |ability, level|
            ability.attempt(actor, ability.name, [], "", level)
        end
        return
    end

end

class Pill < Consumable
    def type_name
        "pill"
    end
end

class Potion < Consumable
    def type_name
        "potion"
    end
end

class Light < Item
    def type_name
        "light"
    end
end

class Portal < Item

    # @return [Exit] The exit for the portal. This links it to its destination room.
    attr_reader :exit

    def initialize(model, parent_inventory, reset = nil)
        super(model, parent_inventory, reset)
        # @type [Exit]
        @exit = Exit.new(
            nil,
            nil,
            nil,
            self.keywords.to_s,
            model.name,
            model.short_description,
            model.door,
            model.key_id,
            model.closed,
            model.locked,
            model.pickproof,
            model.passproof,
            model.nonspatial,
            model.reset_timer
        )
        room = Game.instance.rooms.dig(model.to_room_id)
        if room
            set_destination(room)
        end
    end

    #
    # Overload Item#destroy to destroy the exit as well.
    #
    # @return [nil]
    #
    def destroy
        super
        if @exit
            @exit.destroy
        end
        return
    end

    #
    # Set the destination room of the Portal to a given Room.
    #
    # @param [Room] room The destination room.
    #
    # @return [nil]
    #
    def set_destination(room)
        @exit.set_destination(room)
    end

end

# class Tattoo < Item

#     attr_reader :brilliant

#     @@stats = [ :wis, :int, :con, :dex, :str, :damroll, :hitroll ]

#     @@lesser = {
#         wis: { min: 1, max: 1, noun: "fairy", adjective: "wise" },
#         int: { min: 1, max: 1, noun: "wizard", adjective: "smart" },
#         con: { min: 1, max: 1, noun: "stallion", adjective: "tough" },
#         dex: { min: 1, max: 1, noun: "fox", adjective: "agile" },
#         str: { min: 1, max: 1, noun: "bear", adjective: "muscular" },
#         damroll: { min: 1, max: 1, noun: "blade", adjective: "powerful" },
#         hitroll: { min: 1, max: 1, noun: "eyeball", adjective: "focused" },
#         hitpoints: { min: 10, max: 10, noun: "sun", adjective: "bloody" },
#         manapoints: { min: 10, max: 10, noun: "moon", adjective: "glowing" },
#         saves: { min: -1, max: -1, noun: "shield", adjective: "guardian" },
#         age: { min: 10, max: 10, noun: "turtle", adjective: "aging" },
#     }

#     @@greater = {
#         wis: { min: 1, max: 4,  noun: "unicorn", adjective: "sage" },
#         int: { min: 1, max: 4, noun: "sphinx", adjective: "brilliant" },
#         con: { min: 1, max: 4, noun: "gorgon", adjective: "resilient" },
#         dex: { min: 1, max: 4, noun: "wyvern", adjective: "flying" },
#         str: { min: 1, max: 4, noun: "titan", adjective: "red" },
#         damroll: { min: 1, max: 4, noun: "warlord", adjective: "flaming" },
#         hitroll: { min: 1, max: 4, noun: "archer", adjective: "precise" },
#         hitpoints: { min: 10, max: 40, noun: "gryphon", adjective: "huge" },
#         manapoints: { min: 10, max: 40, noun: "dragon", adjective: "pulsating" },
#         saves: { min: 1, max: 5, noun: "pentagram", adjective: "sealed" },
#         age: { min: 10, max: 30, noun: "hourglass", adjective: "ancient" },
#     }

#     def initialize( runist, slot, reset = nil )
#         super({
#             level: runist.level,
#             weight: 0,
#             cost: 0,
#             material: "tattoo",
#             extraFlags: "noremove",
#         }.merge( paint ), runist.inventory, reset)
#         @runist = runist
#         @duration = 600.0 * runist.level
#         @slot = slot
#     end

#     def type_name
#         "tattoo"
#     end

#     def update(elapsed)
#         super(elapsed)
#         @duration -= elapsed
#         if @duration <= 0 && @runist.equipment[ @slot.to_sym ] == self
#             destroy
#         end
#     end

#     def destroy( damage = false )
#         @runist.magic_hit(@runist, 100, "burning flesh", "flaming") if damage
#         @runist.output "Your tattoo crumbles into dust." if not damage
#         @runist.equipment[ @slot.to_sym ] = nil
#     end

#     def lore
#         super + %Q(
# Tattoo will last for another #{ @duration.to_i } seconds.)
#     end

#     def paint
#         modifiers = {}
#         noun = nil
#         adjectives = []
#         ( count = rand(1..4) ).times do |i|
#             key = @@stats.sample
#             modifiers[ key ] = modifiers[ key ].to_i + rand(@@greater[key][:min]..@@greater[key][:max])
#             noun = @@greater[key][:noun] if i == 0
#             adjectives.push( @@greater[key][:adjective] ) if i > 0
#         end
#         @brilliant = ( count >=3 )
#         return { keywords: ["tattoo", noun] + adjectives, modifiers: modifiers, long_description: "a tattoo of a #{ adjectives.uniq.join(", ") } #{ noun }", short_description: "a tattoo of a #{ adjectives.uniq.join(", ") } #{ noun }"}
#     end

# end
