class Item < GameObject

    attr_accessor :active
    attr_accessor :weight
    attr_accessor :type
    attr_accessor :cost
    attr_reader :id
    attr_reader :wear_flags
    attr_reader :parent_inventory
    attr_reader :material
    attr_reader :level

    def initialize( data, parent_inventory )
        super(data[:short_desc], data[:keywords])
        @id = data[:id]
        @short_description = data[:short_desc]
        @level = data[:level]
        @weight = data[:weight]
        @cost = data[:cost]
        @long_description = data[:long_desc]
        @type = data[:type]
        @material = data[:material]
        @extra_flags = data[:extra_flags]
        @wear_flags = data[:wear_flags]
        @active = true
        @parent_inventory = nil
        @modifiers = Hash.new
        @level = data[:level] || 0
        # @ac = data[:ac] || [0,0,0,0]

        apply_affect_flags( @extra_flags, silent: true )

        move(parent_inventory)
    end

    def to_s
        return @short_description
    end

    def to_someone
        "something"
    end

    def to_store_listing( quantity )
        "[#{@level.to_s.lpad(2)} #{carrier.sell_price( self ).to_s.lpad(5)} #{ [quantity, 99].min.to_s.lpad(2) } ] #{@short_description}"
    end

    def to_price
        gold = ( @cost / 1000 ).floor
        silver = ( @cost - gold * 1000 )
        gold > 0 ? "#{ gold } gold and #{ silver } silver" : "#{ silver } silver"
    end

    def name
        data = { description: @name }
        Game.instance.fire_event( self, :event_calculate_aura_description, data )
        return data[:description]
    end

    def long
        data = { description: @long_description }
        Game.instance.fire_event( self, :event_calculate_aura_description, data )
        return data[:description]
    end

    def modifier( key )
        return @modifiers.nil? ? 0 : @modifiers[ key ].to_i
    end

    def lore
%Q(
Object '#{ @short_description }' is of type #{ @type }.
Description: #{ @long_description }
Keywords '#{ @keyword_string }'
Weight #{ @weight } lbs, Value #{ @cost } silver, level is #{ @level }, Material is #{ @material }.
Extra flags: #{ @extraFlags }
#{ @modifiers.map { |key, value| "Object modifies #{key} by #{value}" }.join("\n\r") if not @modifiers.nil? }
) +  show_affects(observer: nil, full: false)
    end

    # move this item to another inventory - nil is passed when an item is going to be destroyed
    def move(new_inventory)
        if @parent_inventory
            if equipped?
                Game.instance.fire_event(self, :event_item_unwear, {mobile: carrier})
            end
            @parent_inventory.remove_item(self)
        end
        if new_inventory
            new_inventory.add_item(self)
            if equipped?
                Game.instance.fire_event(self, :event_item_wear, {mobile: carrier})
            end
        end
        @parent_inventory = new_inventory
    end

    # alias for Game.instance.destroy_item(self)
    def destroy
        Game.instance.destroy_item(self)
    end

    def db_source_type
        return "Item"
    end

    # gets the room this object is in, whether it's in a room directly, in a mobile inventory/equip_slot,
    # or in another item
    def room
        return @parent_inventory.owner.room
    end

    # returns the gameobject that carries this item, whether it's the room that this object is on
    # the floor in, a mobile with this item in a container, or just a mobile with this in an equip_slot
    def carrier
        owner = @parent_inventory.owner
        while Item === owner
            owner = owner.parent_inventory.owner
        end
        return owner
    end

    # true or false - item is equipped?
    def equipped?
        EquipSlot === @parent_inventory
    end

end

class Weapon < Item

	attr_accessor :noun, :element, :flags, :genre

	def initialize( data, parent_inventory )
		super(data, parent_inventory)

		@noun = data[:noun] || "pierce"
		@flags = data[:flags] || []
		@element = data[:element] || "iron"
        @genre = data[:genre] || "exotic"
		@dice_count = data[:dice_count] || 2
		@dice_sides = data[:dice_sides] || 6
        @dice_bonus = data[:dice_bonus] || 0
	end

	def damage
        dice( @dice_count, @dice_sides ) + @dice_bonus
	end

end

class Container < Item

    attr_accessor :inventory

	def initialize( data, parent_inventory )
        super(data, parent_inventory)
        @flags = data[:flags]
        @max_item_weight = data[:max_item_weight]
        @weight_multiplier = data[:weight_multiplier]
        @max_total_weight = data[:max_total_weight]
        @key_id = data[:key_id]
        @inventory = Inventory.new(self)
    end

    def get_item(item)
        item.move(@inventory)
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

    def initialize( runist, slot )
        super({
            level: runist.level,
            weight: 0,
            cost: 0,
            type: "tattoo",
            material: "tattoo",
            extraFlags: "noremove",
            ac: { ac_pierce: -10, ac_bash: -10, ac_slash: -10, ac_magic: -10 }
        }.merge( paint ), runist.game, runist.inventory)
        @runist = runist
        @duration = 600.0 * runist.level
        @slot = slot
        Game.instance.items.add self
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
        Game.instance.items.delete self
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
