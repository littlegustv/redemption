require_relative 'affect.rb'

class AffectBarkSkin < Affect

    def initialize(target, source = nil, level = 0)
        super(
            target, # target
            source, # source
            level, # level
            300, # duration
            { resist_bash: 5 }, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            :normal, # visibility
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
        (@target.room.occupants - [@target]).each_output "0<N> looks as mighty as an oak", [@target]
    end

    def send_complete_messages
        @target.output "The bark on your skin flakes off."
        (@target.room.occupants - [@target]).each_output "The bark on 0<n>'s skin flakes off.", [@target]
    end

end

class AffectBerserk < Affect

    def initialize(target, source = nil, level = 0)
        super(
            target, # target
            source, # source
            level, # level
            60, # duration
            {
                damage_roll: level / 10,
                hit_roll: level / 10
            }, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            :normal, # visibility
            true # savable
        )
        @healing_left = 3 * level
        if @healing_left > 0
            toggle_periodic(1)
        end
    end

    def self.affect_info
        return @info || @info = {
            name: "berserk",
            keywords: ["berserk"],
            application_type: :source_overwrite,
        }
    end

    def send_start_messages
        @target.output "Your pulse races as you are consumed by rage!"
        (@target.room.occupants - [@target]).each_output("0<N> gets a wild look in 0<p> eyes!", @target)
    end

    def periodic
        heal = [@healing_left, 3].min
        @healing_left -= heal
        @target.regen heal, 0, 0
        if @healing_left == 0
            toggle_periodic(nil)
        end
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
        [ "The weapon surrounds you with a glowing aura.", { armor_class: -30 } ],
        [ "The weapon is endowed with killing dweomers.", { damroll: 10 } ]
    ]

    def initialize(target, source = nil, level = 0)
        super(
            target, # target
            source, # source
            level, # level
            60, # duration
            nil, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            :normal, # visibility
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
        @source.room.occupants.each_output("0<N> empower0<,s> 1<n> with a blade rune0<!,.>", [@source, @target])
        @source.output @message
    end

    def send_complete_messages
        @source.output "The blade rune on %n fades away.", [@target]
    end
end

class AffectBless < Affect

    def initialize(target, source = nil, level = 0)
        super(
            target, # target
            source, # source
            level, # level
            300, # duration
            {
                hit_roll: 5,
                saves: -5
            }, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            :normal, # visibility
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
        (@target.room.occupants - [@target]).each_output "0<N> glows with a holy aura.", [@target]
    end

    def send_complete_messages
        @target.output "You feel less righteous."
        (@target.room.occupants - [@target]).each_output "0<N>'s holy aura fades.", [@target]
    end

end

class AffectBlind < Affect

    def initialize(target, source = nil, level = 0)
        super(
            target, # target
            source, # source
            level, # level
            30, # duration
            {
                hit_roll: -5
            }, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            :normal, # visibility
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
        add_event_listener(@target, :event_try_can_see, :do_blindness)
    end

    def send_start_messages
        (@target.room.occupants - [@target]).each_output "0<N> is blinded!", [@target]
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

    def initialize(target, source = nil, level = 0)
        super(
            target, # target
            source, # source
            level, # level
            300, # duration
            { resist_slash: 5 }, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            :normal, # visibility
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
        @target.room.occupants.each_output "0<N>'s outline turns blurry.", [@target]
    end

    def send_complete_messages
        @target.room.occupants.each_output "0<N> comes into focus.", [@target]
    end

end

class AffectBolster < Affect

    def initialize(target, source = nil, level = 0)
        super(
            target, # target
            source, # source
            level, # level
            60, # duration
            nil, # modifiers: nil
            3, # period: nil
            false, # permanent: false
            :normal, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "bolster",
            keywords: ["bolster"],
            application_type: :global_single,
        }
    end

    def send_complete_messages
        @target.room.occupants.each_output "0<N> 0<are,is> no longer so resolutely holy.", @target
    end

    def start
        old_hp = @target.health
        @target.room.occupants.each_output "0<N> 0<bolster,bolsters> 0<p> faith!", @target
        @target.regen( 3 * @target.level + 25, 0, 0 )
        @healed = @target.health - old_hp
    end

    def periodic
        @target.output "Some divine protection leaves you."
        @target.receive_damage( @target, 1.5 * @healed / 20, :divine_power )
    end
end

class AffectBurstRune < Affect


    @@NOUN_NAME = "elemental charged strike"

    def initialize(target, source = nil, level = 0)
        super(
            target, # target
            source, # source
            level, # level
            60, # duration
            nil, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            :normal, # visibility
            true # savable
        )
        @ELEMENTS = [
            ["flooding", "Your weapon carries the {Dstrength{x of the {Btides!{x", "A {Dblack{x and {Bblue{x rune appears.",:hurricane],
            ["corrosive", "Your attack explodes into {Gcorrosive {Bacid{x!", "A {Ggreen{x and {Bblue{x rune appears.", :acid_blast],
            ["frost", "The air is {Wtinged{x with {Bfrost{x as you strike!", "A {Bblue{x and {Wwhite{x rune appears.", :ice_bolt],
            ["poison", "Your weapon discharges a {Gvirulent {Dspray!{x", "A {Ggreen{x and {Dblack{x rune appears.", :blast_of_rot],
            ["shocking", "You strike with the force of a {Ythunder {Bbolt!{x", "A {Ygold{x and {Bblue{x rune appears.", :lightning_bolt],
            ["flaming", "A {Wblast{x of {Rflames{x explodes from your weapon!", "A {Rred{x and {Wwhite{x rune appears.", :fireball]
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
        super(data)
        @data[:index] = rand(@ELEMENTS.length) if !@data[:index]
        @element_string, @hit_message, @apply_message, @noun = @ELEMENTS[@data[:index]]
    end

    def start
        add_event_listener(@target, :event_override_hit, :do_burst_rune)
    end

    def do_burst_rune(data)
        if data[:confirm] == false && data[:target] && rand(1..100) <= 125
            data[:source].output @hit_message
            data[:target].receive_damage(data[:source], 100, @noun, false, false, @@NOUN_NAME)
            data[:confirm] = true
        end
    end

    def send_start_messages
        @source.room.occupants.each_output("0<N> empower0<,s> 1<n> with a burst rune0<!,.>", [@source, @target])
        @source.output @apply_message
    end

    def send_complete_messages
        @source.output "The burst rune on 0<n> fades away.", [@target]
    end

    def summary
        "Spell: burst rune adds #{@element_string} elemental charged strike for #{@duration.to_i} seconds"
    end
end
