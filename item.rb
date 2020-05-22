    class Item < GameObject

    attr_accessor :active
    attr_accessor :weight
    attr_accessor :cost
    attr_reader :id
    attr_reader :parent_inventory
    attr_reader :material
    attr_reader :level

    def initialize( model, parent_inventory, reset = nil )
        super(nil, nil, reset, model)
        @model = model
        @id = @model.id
        @name = nil
        @short_description = nil
        @level = model.level
        @weight = model.weight
        @cost = @model.cost
        @material = @model.material

        @active = true
        @parent_inventory = nil
        @modifiers = model.modifiers.dup
        move(parent_inventory)
        if @model.affect_models
            @model.affect_models.each do |affect_model|
                self.apply_affect_model(affect_model, true)
            end
        end

    end

    def destroy
        super
        self.move(nil)
        Game.instance.destroy_item(self)
    end

    def name
         @name || @model.name
    end

    def short_description
        @short_description || @model.short_description
    end

    def type_name
        "item"
    end

    def to_s
        return self.name
    end

    def to_someone
        "something"
    end

    def to_store_listing( quantity )
        "[#{@level.to_s.lpad(2)} #{carrier.sell_price( self ).to_s.lpad(7)} #{ [quantity, 99].min.to_s.lpad(2) } ] #{self.name}"
    end

    def modifier( key )
        return @modifiers.nil? ? 0 : @modifiers.dig(key).to_i
    end

    def lore
        output = self.pre_lore
        output += self.post_lore
        return output
    end

    def pre_lore
        output = "Object '#{ self.name }' is of type #{ self.type_name }.\n"
        output += "Description: #{ self.short_description }\n"
        output += "Keywords '#{ self.keyword_string }'\n"
        output += "Weight #{ @weight } lbs, Value #{ @cost } silver, level is #{ @level }, Material is #{ @material.name }."
        return output
    end

    def post_lore
        output = ""
        if wear_locations.size > 0
            output += "\nItem can #{wear_locations.map(&:display_string).to_list("or")}."
        end
        if @modifiers
            output += "\n" + @modifiers.map { |stat, value| "Object modifies #{stat.name} by #{value}#{stat.percent?}." }.join("\n")
        end
        if @affects && @affects.size > 0
            output += "\n" + show_affects(observer: nil, full: false)
        end
        return output
    end

    # move this item to another inventory - nil is passed when an item is going to be destroyed
    def move(new_inventory)
        if @reset && @parent_inventory && @parent_inventory.owner.active && (new_inventory.nil? || @parent_inventory.owner != new_inventory.owner)
            @reset.activate(false, @parent_inventory.owner)
            unlink_reset
        end
        if @parent_inventory
            if equipped?
                Game.instance.fire_event(self, :event_item_unwear, {mobile: carrier})
            end
            @parent_inventory.remove_item(self)
        end
        @parent_inventory = new_inventory
        if new_inventory
            new_inventory.add_item(self)
            if equipped?
                Game.instance.fire_event(self, :event_item_wear, {mobile: carrier})
            end
        end
    end

    def unlink_reset
        @reset = nil
    end

    # gets the room this object is in, whether it's in a room directly, in a mobile inventory/equip_slot,
    # or in another item
    def room
        if @parent_inventory.nil?
            return Room.inactive_room
        end
        return @parent_inventory.owner.room
    end

    # returns the gameobject that carries this item, whether it's the room that this object is on
    # the floor in, a mobile with this item in a container, or just a mobile with this in an equip_slot
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

    # true or false - item is equipped?
    def equipped?
        @parent_inventory.is_a?(EquipSlot)
    end

    def wear_locations
        @model.wear_locations.to_a
    end

    def fixed
        @model.fixed
    end

    def db_source_type_id
        return 3
    end

end

class Weapon < Item

	attr_accessor :noun, :flags, :genre

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

	def damage
        dice( @dice_count, @dice_sides )
	end

    def attack_speed
        @genre.attack_speed
    end

end

class Container < Item

    attr_accessor :inventory

	def initialize( model, parent_inventory, reset = nil )
        super(model, parent_inventory, reset)
        @max_item_weight = model.max_item_weight
        @weight_multiplier = model.weight_multiplier
        @max_total_weight = model.max_total_weight
        @key_id = model.key_id
        @inventory = Inventory.new(self)
    end

    def type_name
        "container"
    end

    def get_item(item)
        item.move(@inventory)
    end

    def unlink_reset
        @reset = nil
        if @inventory
            @inventory.items.each do |item|
                item.unlink_reset
            end
        end
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

    def consume( actor )
        @ability_instances.each do |ability, level|
            ability.attempt(actor, ability.name, [], "", level)
        end
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

    attr_reader :exit

    def initialize(model, parent_inventory, reset = nil)
        super(model, parent_inventory, reset)
        @exit = Exit.new(
            nil,
            nil,
            Game.instance.rooms.dig(model.to_room_id),
            self.keyword_string,
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
    end

    def destroy
        super
        if @exit
            @exit.destroy
        end
    end

    def move(new_inventory)
        super(new_inventory)
        if @parent_inventory
            room = new_inventory.owner.room
        end
    end

    def set_destination(room)
        @exit.set_destination(room)
    end

end

class Tattoo < Item

    attr_reader :brilliant

    @@stats = [ :wis, :int, :con, :dex, :str, :damroll, :hitroll ]

    @@lesser = {
        wis: { min: 1, max: 1, noun: "fairy", adjective: "wise" },
        int: { min: 1, max: 1, noun: "wizard", adjective: "smart" },
        con: { min: 1, max: 1, noun: "stallion", adjective: "tough" },
        dex: { min: 1, max: 1, noun: "fox", adjective: "agile" },
        str: { min: 1, max: 1, noun: "bear", adjective: "muscular" },
        damroll: { min: 1, max: 1, noun: "blade", adjective: "powerful" },
        hitroll: { min: 1, max: 1, noun: "eyeball", adjective: "focused" },
        hitpoints: { min: 10, max: 10, noun: "sun", adjective: "bloody" },
        manapoints: { min: 10, max: 10, noun: "moon", adjective: "glowing" },
        saves: { min: -1, max: -1, noun: "shield", adjective: "guardian" },
        age: { min: 10, max: 10, noun: "turtle", adjective: "aging" },
    }

    @@greater = {
        wis: { min: 1, max: 4,  noun: "unicorn", adjective: "sage" },
        int: { min: 1, max: 4, noun: "sphinx", adjective: "brilliant" },
        con: { min: 1, max: 4, noun: "gorgon", adjective: "resilient" },
        dex: { min: 1, max: 4, noun: "wyvern", adjective: "flying" },
        str: { min: 1, max: 4, noun: "titan", adjective: "red" },
        damroll: { min: 1, max: 4, noun: "warlord", adjective: "flaming" },
        hitroll: { min: 1, max: 4, noun: "archer", adjective: "precise" },
        hitpoints: { min: 10, max: 40, noun: "gryphon", adjective: "huge" },
        manapoints: { min: 10, max: 40, noun: "dragon", adjective: "pulsating" },
        saves: { min: 1, max: 5, noun: "pentagram", adjective: "sealed" },
        age: { min: 10, max: 30, noun: "hourglass", adjective: "ancient" },
    }

    def initialize( runist, slot, reset = nil )
        super({
            level: runist.level,
            weight: 0,
            cost: 0,
            material: "tattoo",
            extraFlags: "noremove",
        }.merge( paint ), runist.inventory, reset)
        @runist = runist
        @duration = 600.0 * runist.level
        @slot = slot
    end

    def type_name
        "tattoo"
    end

    def update(elapsed)
        super(elapsed)
        @duration -= elapsed
        if @duration <= 0 && @runist.equipment[ @slot.to_sym ] == self
            destroy
        end
    end

    def destroy( damage = false )
        @runist.magic_hit(@runist, 100, "burning flesh", "flaming") if damage
        @runist.output "Your tattoo crumbles into dust." if not damage
        @runist.equipment[ @slot.to_sym ] = nil
    end

    def lore
        super + %Q(
Tattoo will last for another #{ @duration.to_i } seconds.)
    end

    def paint
        modifiers = {}
        noun = nil
        adjectives = []
        ( count = rand(1..4) ).times do |i|
            key = @@stats.sample
            modifiers[ key ] = modifiers[ key ].to_i + rand(@@greater[key][:min]..@@greater[key][:max])
            noun = @@greater[key][:noun] if i == 0
            adjectives.push( @@greater[key][:adjective] ) if i > 0
        end
        @brilliant = ( count >=3 )
        return { keywords: ["tattoo", noun] + adjectives, modifiers: modifiers, long_description: "a tattoo of a #{ adjectives.uniq.join(", ") } #{ noun }", short_description: "a tattoo of a #{ adjectives.uniq.join(", ") } #{ noun }"}
    end

end
