class Item < GameObject

	attr_accessor :wear_location
    attr_accessor :weight
    attr_accessor :room
    attr_accessor :type
    attr_reader :cost
    attr_reader :id
    attr_reader :wear_flags
    attr_reader :parent_inventory

    def initialize( data, game, parent_inventory )
        super(data[:short_description], game)
        @id = data[:id]
        @short_description = data[:short_description]
        @keywords = data[:keywords]
        @level = data[:level]
        @weight = data[:weight]
        @cost = data[:cost]
        @long_description = data[:long_description]
        @type = data[:type]
        @wear_location = data[:wear_location]
        @material = data[:material]
        @extra_flags = data[:extra_flags]
        @wear_flags = data[:wear_flags]
        @modifiers = data[:modifiers].merge( data[:ac] )
        # @ac = data[:ac] || [0,0,0,0]

        move(parent_inventory)
    end

    def to_s
    	@short_description
    end

    def to_someone
        "something"
    end

    def to_store_listing
        "[#{@level.to_s.rjust(2)} #{@cost.to_s.rjust(5)} -- ] #{@short_description}"
    end

    def to_price
        gold = ( @cost / 1000 ).floor
        silver = ( @cost - gold * 1000 )
        gold > 0 ? "#{ gold } gold and #{ silver } silver" : "#{ silver } silver"
    end

    def long
    	@long_description
    end

    def modifier( key )
        return @modifiers[ key ].to_i
    end

    def update(elapsed)
        @affects.each{ |affect| affect.update(elapsed) }
    end

    def lore
%Q(
Object '#{ @short_description }' is of type #{ @type }. [Clanner Only]
Description: #{ @long_description }
Keywords '#{ @keywords.join(' ') }'
Weight #{ @weight } lbs, Value #{ @cost } silver, level is #{ @level }, Material is #{ @material }.
Extra flags: #{ @extraFlags }
#{ @modifiers.map { |key, value| "Object modifies #{key} by #{value}" }.join("\n\r") }
) +  affects.map(&:summary).join("\n")
    end

    # move this item to another inventory - nil is passed when an item is going to be destroyed
    def move(new_inventory)
        if @parent_inventory
            @parent_inventory.remove_item(self)
        end
        if new_inventory
            new_inventory.add_item(self)
        end
        @parent_inventory = new_inventory
    end

    # alias for @game.destroy_item(self)
    def destroy
        @game.destroy_item(self)
    end

    def db_source_type
        return "Item"
    end

end

class Weapon < Item

	attr_accessor :noun, :element, :flags

	def initialize( data, game, room )
		super data, game, room

		@noun = data[:noun] || "pierce"
		@flags = data[:flags] || []
		@element = data[:element] || "iron"
		@dice_count = data[:dice_count] || 2
		@dice_sides = data[:dice_sides] || 6
	end

	def damage
        dice( @dice_count, @dice_sides )
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
            wear_location: slot.gsub(/\_\d/, ""),
            material: "tattoo",
            extraFlags: "noremove",
            ac: { ac_pierce: -10, ac_bash: -10, ac_slash: -10, ac_magic: -10 }
        }.merge( paint ), runist.game, nil)
        @runist = runist
        @duration = 600.0 * runist.level
        @slot = slot
        @game.items.push self
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
        @game.items.delete self
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
