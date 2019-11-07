require_relative 'affect.rb'

class AffectBarkSkin < Affect

    def initialize(source, target, level, game)
        super(
            game, # game
            source, # source
            target, # target
            level, # level
            300, # duration
            { ac_bash: 40 }, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            Constants::AffectVisibility::NORMAL, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "bark skin",
            keywords: ["barkskin", "armor"],
            application_type: :source_overwrite,
        }
    end

    def send_start_messages
        @target.output "You are as mighty as an oak."
        @target.broadcast "%s looks as mighty as an oak", @target.room.occupants - [@target], [@target]
    end

    def send_complete_messages
        @target.output "The bark on your skin flakes off."
        @target.broadcast "The bark on %s's skin flakes off.", @target.room.occupants - [@target], [@target]
    end

end

class AffectBerserk < Affect

    def initialize(source, target, level, game)
        super(
            game, # game
            source, # source
            target, # target
            level, # level
            60, # duration
            {damroll: (level / 10).to_i, hitroll: (level / 10).to_i}, # modifiers: nil
            1, # period: nil
            false, # permanent: false
            Constants::AffectVisibility::NORMAL, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "berserk",
            keywords: ["berserk"],
            application_type: :source_overwrite,
        }
    end

    def send_start_messages
        @target.broadcast("%s gets a wild look in %x eyes!", @target.room.occupants - [@target], @target)
        @target.output "Your pulse races as you are consumed by rage!"
    end

    def periodic
        @target.regen 10, 0, 0
    end

    def complete
        @target.output "You feel your pulse slow down."
    end

    def summary
        super + "\n" + (" " * 24) + " : regenerating #{ ( 10 * @duration / @period ).floor } hitpoints"
    end
end

class AffectBladeRune < Affect

    @@TYPES = [
        [ "The weapon begins to move faster.", { attack_speed: 1 } ],
        [ "The weapon becomes armor-piercing.", { hitroll: 20 } ],
        # [ "The weapon will deflect incoming attacks.", { none: 0 } ],
        # [ "The weapon becomes more accurate.", { none: 0 } ],
        [ "The weapon surrounds you with a glowing aura.", { ac_pierce: -20, ac_bash: -20, ac_slash: -20 } ],
        [ "The weapon is endowed with killing dweomers.", { damroll: 10 } ]
    ]

    def initialize(source, target, level, game)
        super(
            game, # game
            source, # source
            target, # target
            level, # level
            60, # duration
            nil, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            Constants::AffectVisibility::NORMAL, # visibility
            true # savable
        )
        @message, @modifiers = @@TYPES.sample
    end

    def self.affect_info
        return @info || @info = {
            name: "blade rune",
            keywords: ["blade rune", "rune"],
            application_type: :source_overwrite,
        }
    end

    def send_start_messages
        @source.broadcast("%s empowers %s with a blade rune.", @target.room.occupants - [@source], [@source, @target])
        @source.output "You empower the %s with a blade rune!", @target
        @source.output @message
    end

    def send_complete_messages
        @source.output "The blade rune on %s fades away.", [@target]
    end
end

class AffectBless < Affect

    def initialize(source, target, level, game)
        super(
            game, # game
            source, # source
            target, # target
            level, # level
            300, # duration
            { hitroll: 5, saves: -5 }, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            Constants::AffectVisibility::NORMAL, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "bless",
            keywords: ["bless"],
            application_type: :source_overwrite,
        }
    end

    def send_start_messages
        @target.output "You feel righteous."
        @target.broadcast "%s glows with a holy aura.", @target.room.occupants - [@target], [@target]
    end

    def send_complete_messages
        @target.output "You feel less righteous."
        @target.broadcast "%s's holy aura fades.", @target.room.occupants - [@target], [@target]
    end

end

class AffectBlind < Affect

    def initialize(source, target, level, game)
        super(
            game, # game
            source, # source
            target, # target
            level, # level
            30, # duration
            { hitroll: -5 }, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            Constants::AffectVisibility::NORMAL, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "blind",
            keywords: ["blind"],
            application_type: :global_single,
        }
    end

    def start
        @game.add_event_listener(@target, :event_try_can_see, self, :do_blindness)
    end

    def complete
        @game.remove_event_listener(@target, :event_try_can_see, self)
    end

    def send_start_messages
        @target.broadcast "%s is blinded!", @target.room.occupants - [@target], [@target]
        @target.output "You can't see a thing!"
    end

    def send_complete_messages
        @target.output "You can see again."
    end

    def do_blindness(data)
        data[:chance] *= 0
    end

end

class AffectBlur < Affect

    def initialize(source, target, level, game)
        super(
            game, # game
            source, # source
            target, # target
            level, # level
            300, # duration
            { ac_slash: 40 }, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            Constants::AffectVisibility::NORMAL, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "blur",
            keywords: ["blur", "armor"],
            application_type: :global_overwrite,
        }
    end

    def send_start_messages
        @target.output "You become blurry."
        @target.broadcast "%s's outline turns blurry.", @target.room.occupants - [@target], [@target]
    end

    def send_complete_messages
        @target.output "You come into focus."
        @target.broadcast "%s comes into focus.", @target.room.occupants - [@target], [@target]
    end

end

class AffectBurstRune < Affect


    @@NOUN = "elemental charged strike"

    def initialize(source, target, level, game)
        super(
            game, # game
            source, # source
            target, # target
            level, # level
            60, # duration
            nil, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            Constants::AffectVisibility::NORMAL, # visibility
            true # savable
        )
        @Elements = [
            ["flooding", "Your weapon carries the {Dstrength{x of the {Btides!{x", "A {Dblack{x and {Bblue{x rune appears.", Constants::Element::DROWNING],
            ["corrosive", "Your attack explodes into {Gcorrosive {Bacid{x!", "A {Ggreen{x and {Bblue{x rune appears.", Constants::Element::ACID],
            ["frost", "The air is {Wtinged{x with {Bfrost{x as you strike!", "A {Bblue{x and {Wwhite{x rune appears.", Constants::Element::COLD],
            ["poison", "Your weapon discharges a {Gvirulent {Dspray!{x", "A {Ggreen{x and {Dblack{x rune appears.", Constants::Element::POISON],
            ["shocking", "You strike with the force of a {Ythunder {Bbolt!{x", "A {Ygold{x and {Bblue{x rune appears.", Constants::Element::LIGHTNING],
            ["flaming", "A {Wblast{x of {Rflames{x explodes from your weapon!", "A {Rred{x and {Wwhite{x rune appears.", Constants::Element::FIRE]
        ]
        overwrite_data(Hash.new)
    end

    def self.affect_info
        return @info || @info = {
            name: "burst rune",
            keywords: ["burst rune", "rune"],
            application_type: :global_single,
        }
    end

    def overwrite_data(data)
        @data = data
        @data[:index] = rand(@elements.length) if !@data[:index]
        @element_string, @hit_message, @apply_message, @element = @ELEMENTS[@data[:index]]
    end

    def start
        @game.add_event_listener(@target, :event_item_wear, self, :add_burst_rune)
        @game.add_event_listener(@target, :event_item_unwear, self, :remove_burst_rune)
        if @target.equipped?
            @game.add_event_listener(@target.carrier, :event_override_hit, self, :do_burst_rune)
        end
    end

    def complete
        @game.remove_event_listener(@target, :event_item_wear, self)
        @game.remove_event_listener(@target, :event_item_unwear, self)
        if @target.equipped?
            @game.remove_event_listener(@target.carrier, :event_override_hit, self)
        end
    end

    def add_burst_rune(data)
        @game.add_event_listener(@target.carrier, :event_override_hit, self, :do_burst_rune)
    end

    def remove_burst_rune(data)
        @game.remove_event_listener(@target.carrier, :event_override_hit, self)
    end

    def do_burst_rune(data)
        if data[:confirm] == false && data[:weapon] == @target && data[:target] && rand(1..100) <= 125
            data[:source].output @hit_message
            data[:source].deal_damage(target: data[:target], damage: 100, noun: @@NOUN, element: @element, type: Constants::Damage::MAGICAL)
            data[:confirm] = true
        end
    end

    def send_start_messages
        @source.broadcast("%s empowers %s with a burst rune.", @target.room.occupants - [@source], [@source, @target])
        @source.output "You empower the weapon with an elemental burst rune!"
        @source.output @apply_message
    end

    def send_complete_messages
        @source.output "The burst rune on %s fades away.", [@target]
    end

    def summary
        "Spell: burst rune adds #{@element_string} elemental charged strike for #{@duration.to_i} seconds"
    end
end
