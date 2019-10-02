require_relative 'affect.rb'

class AffectBerserk < Affect

    def initialize(source:, target:, level:, game:)
        super(
            game: game,
            source: source,
            target: target,
            keywords: ["berserk"],
            name: "berserk",
            level:  level,
            duration: 60,
            modifiers: {damroll: (level / 10).to_i, hitroll: (level / 10).to_i},
            period: 1
        )
    end

    def send_start_messages
        @target.broadcast("%s gets a wild look in %x eyes!", @target.target({list:@target.room.occupants, not: @target}), @target)
        @target.output "Your pulse races as you are consumed by rage!"
    end

    def periodic
        @target.regen 10
    end

    def complete
        @target.output "You feel yourself being less berzerky."
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

    def initialize(source:, target:, level:, game:)
        super(
            game: game,
            source: source,
            target: target,
            keywords: ["blade rune", "rune"],
            name: "blade rune",
            level:  level,
            duration: 60
        )
        @message, @modifiers = @@TYPES.sample
    end

    def send_start_messages
        @source.broadcast("%s empowers %s with a blade rune.", @source.target({list: @source.room.occupants, not: @source}), [@source, @target])
        @source.output "You empower the %s with a blade rune!", @target
        @source.output @message
    end

    def send_complete_messages
        @source.output "The blade rune on %s fades away.", [@target]
    end
end

class AffectBlind < Affect

    def initialize(source:, target:, level:, game:)
        super(
            game: game,
            source: source,
            target: target,
            keywords: ["blind"],
            name: "blind",
            level:  level,
            duration: 30,
            modifiers: {hitroll: -5},
            application_type: :global_single
        )
    end

    def start
        @target.add_event_listener(:event_try_can_see, self, :do_blindness)
    end

    def complete
        @target.delete_event_listener(:event_try_can_see, self)
    end

    def send_start_messages
        @target.broadcast "%s is blinded!", @game.target({ not: @target, room: @target.room }), [@target]
        @target.output "You can't see a thing!"
    end

    def send_complete_messages
        @target.output "You can see again."
    end

    def do_blindness(data)
        data[:chance] *= 0
    end

end

class AffectBurstRune < Affect

    def initialize(source:, target:, level:, game:)
        super(
            game: game,
            source: source,
            target: target,
            keywords: ["burst rune", "rune"],
            name: "burst rune",
            level:  level,
            duration: 60
        )
        @elements = [
            ["flooding", "Your weapon carries the {Dstrength{x of the {Btides!{x", "A {Dblack{x and {Bblue{x rune appears.", Constants::Element::DROWNING],
            ["corrosive", "Your attack explodes into {Gcorrosive {Bacid{x!", "A {Ggreen{x and {Bblue{x rune appears.", Constants::Element::ACID],
            ["frost", "The air is {Wtinged{x with {Bfrost{x as you strike!", "A {Bblue{x and {Wwhite{x rune appears.", Constants::Element::COLD],
            ["poison", "Your weapon discharges a {Gvirulent {Dspray!{x", "A {Ggreen{x and {Dblack{x rune appears.", Constants::Element::POISON],
            ["shocking", "You strike with the force of a {Ythunder {Bbolt!{x", "A {Ygold{x and {Bblue{x rune appears.", Constants::Element::LIGHTNING],
            ["flaming", "A {Wblast{x of {Rflames{x explodes from your weapon!", "A {Rred{x and {Wwhite{x rune appears.", Constants::Element::FIRE]
        ]
        overwrite_data(@data)
        @noun = "elemental charged strike"
    end

    def overwrite_data(data)
        @data = data
        @data[:index] = rand(@elements.length) if !@data[:index]
        @element_string, @hit_message, @apply_message, @element = @elements[@data[:index]]
    end

    def start
        @target.add_event_listener(:event_override_hit, self, :do_burst_rune)
    end

    def complete
        @target.delete_event_listener(:event_override_hit, self)
    end

    def do_burst_rune(data)
        if data[:confirm] == false && data[:weapon] == @target && data[:target] && rand(1..100) <= 25
            data[:source].output @hit_message
            data[:source].deal_damage(target: data[:target], damage: 100, noun: @noun, element: @element, type: Constants::Damage::MAGICAL)
            data[:confirm] = true
        end
    end

    def send_start_messages
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
