require_relative 'affect.rb'

class AffectBerserk < Affect

    def initialize(source:, target:, level:)
        super(
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

    def start
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

class AffectBlind < Affect

    def initialize(source:, target:, level:)
        super(
            source: source,
            target: target,
            keywords: ["blind"],
            name: "blind",
            level:  level,
            duration: 30,
            modifiers: {hitroll: -5}
        )
    end

    def hook
        @target.add_event_listener(:event_try_can_see, self, :do_blindness)
    end

    def unhook
        @target.delete_event_listener(:event_try_can_see, self)
    end

    def start
        @target.output "You can't see a thing!"
    end

    def complete
        @target.output "You can see again."
    end

    def do_blindness(data)
        data[:chance] *= 0
    end

end

class AffectBurstRune < Affect

    @@ELEMENTS = [
        ["flooding", "Your weapon carries the {Dstrength{x of the {Btides!{x", "A {Dblack{x and {Bblue{x rune appears."],
        ["corrosive", "Your attack explodes into {Gcorrosive {Bacid{x!", "A {Ggreen{x and {Bblue{x rune appears."],
        ["frost", "The air is {Wtinged{x with {Bfrost{x as you strike!", "A {Bblue{x and {Wwhite{x rune appears."],
        ["poison", "Your weapon discharges a {Gvirulent {Dspray!{x", "A {Ggreen{x and {Dblack{x rune appears."],
        ["shocking", "You strike with the force of a {Ythunder {Bbolt!{x", "A {Ygold{x and {Bblue{x rune appears."],
        ["flaming", "A {Wblast{x of {Rflames{x explodes from your weapon!", "A {Rred{x and {Wwhite{x rune appears."]
    ]

    def initialize(source:, target:, level:)
        super(
            source: source,
            target: target,
            keywords: ["burst rune"],
            name: "burst rune",
            level:  level,
            duration: 60            
        )
        @element, @hit, @message = @@ELEMENTS.sample
        @noun = "elemental charged strike"
    end

    def hook
        @target.add_event_listener(:event_on_hit, self, :do_burst_rune)
    end

    def unhook
        @target.delete_event_listener(:event_on_hit, self)
    end

    def do_burst_rune(data)
        if @source.attacking && rand(0..100) < 50
            @source.output @hit
            @source.magic_hit( @source.attacking, 100, @noun, @element) 
        end
    end

    def start
        @source.output "You empower the weapon with an elemental burst rune!"
        @source.output @message
    end

    def complete
    end
end