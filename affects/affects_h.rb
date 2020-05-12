require_relative 'affect.rb'

class AffectHaste < Affect

    def initialize(source, target, level)
        super(
            source, # source
            target, # target
            level, # level
            120, # duration
            {
                dexterity: 1 + level / 12,
                attack_speed: 1
            }, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            Visibility::NORMAL, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "haste",
            keywords: ["haste"],
            application_type: :global_overwrite,
        }
    end

    def send_start_messages
        @target.output "You feel yourself moving more quickly."
        (@target.room.occupants - [@target]).each_output "0<N> starts moving more quickly.", @target
    end

    def send_complete_messages
        @target.output "You feel yourself slow down."
        (@target.room.occupants - [@target]).each_output "0<N> slows down.", @target
    end
end

# Affect to make hatchlings become coloured dragons at a certain level
class AffectHatchling < Affect

    @@HATCHLING_MESSAGES = {
        "black dragon" => [ "You feel acid course through your veins.", "Black wings unfold off your back.", "Saliva turned acid drips from your maw." ],
        "blue dragon" => [ "The sky clouds over and lightning crackles in the distance.", "Energy ripples, and your entire body vibrates with each pulse.", "Your scales harden into blue metallic plates." ],
        "green dragon" => [ "A stench crawls its way up your nasal passage.", "Poison seeps through your body and clouds your eyes.", "Your green tail lashes about behind you, with fearsome power." ],
        "red dragon" => [ "A powerful heat rolls up your back, and fills your eyes.", "Red claws stab the air frantically as the burning fills your brain.", "The burning subsides and your new red coat of scales clank together." ],
        "white dragon" => [ "White wings fold up off your body and you test the air with them.", "Breath burns out of your maw, spilling the burning cold frost into the air.", "Your white hind claws cause the ground to harden and freeze." ]
    }

    def initialize(source, target, level)
        super(
            source, # source
            target, # target
            level, # level
            60, # duration
            nil, # modifiers: nil
            nil, # period: nil
            true, # permanent: false
            Visibility::HIDDEN, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "hatchling",
            keywords: ["hatchling"],
            application_type: :global_single,
        }
    end

    def start
        add_event_listener(@target, :event_on_level_up, :hatch)
    end

    def hatch(data)
        if data[:level] >= 2
            race_name = @@HATCHLING_MESSAGES.keys.sample
            @target.set_race(Game.instance.races.values.find { |r| r.name == race_name })
            @target.output("#{@@HATCHLING_MESSAGES[ race_name ].join("\n")}")
        end
    end

end

class AffectHide < Affect

    def initialize(source, target, level)
        super(
            source, # source
            target, # target
            level, # level
            60, # duration
            nil, # modifiers: nil
            nil, # period: nil
            true, # permanent: false
            Visibility::NORMAL, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "hide",
            keywords: ["hide"],
            application_type: :global_overwrite,
        }
    end

    def start
        add_event_listener(@target, :event_on_start_combat, :do_remove_affect)
        add_event_listener(@target, :event_mobile_exit, :do_remove_affect)
        add_event_listener(@target, :event_try_can_be_seen, :do_hide)
        add_event_listener(@target, :event_calculate_long_auras, :do_hide_aura)
    end

    def send_start_messages
        @target.output "You fade out of existence."
        (@target.room.occupants - [@target]).each_output  "0<N> fades from existence.", [@target]
    end

    def send_complete_messages
        @target.output "You fade into existence."
        room  = @target.room
        (@target.room.occupants - [@target]).each_output  "0<N> fades into existence.", [@target]
    end

    def do_remove_affect(data)
        clear
    end

    def do_hide(data)
        if data[:observer].stat(:intelligence) > @target.stat(:dex)
            data[:chance] *= 1
        else
            data[:chance] *= 0
        end
    end

    def do_hide_aura(data)
        data[:description] = "(Hiding) " + data[:description]
    end

end
