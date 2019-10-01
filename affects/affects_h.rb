require_relative 'affect.rb'

class AffectHaste < Affect

    def initialize(source:, target:, level:, game:)
        super(
            game: game,
            source: source,
            target: target,
            keywords: ["haste"],
            name: "haste",
            level:  level,
            duration: 120,
            modifiers: {dex: [1, (level / 10).to_i].max, attack_speed: 1, str: 10}
        )
    end

    def send_start_messages
        @target.output "You feel yourself moving more quickly."
        @target.broadcast("%s starts moving more quickly.", @target.target({list: @target.room.occupants, not: @target}), @target)
    end

    def send_complete_messages
        @target.output "You feel yourself slow down."
        @target.broadcast("%s slows down.", @target.target({list: @target.room.occupants, not: @target}), @target)
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

    def initialize(source:, target:, level:, game:)
        super(
            game: game,
            source: source,
            target: target,
            keywords: ["hatchling"],
            name: "hatchling",
            level:  level,
            permanent: true,
            hidden: true,
            application_type: :global_single
        )
    end

    def start
        @target.add_event_listener(:event_on_level_up, self, :hatch)
    end

    def complete
        @target.delete_event_listener(:event_on_level_up, self)
    end

    def hatch(data)
        if data[:level] >= 2
            race_name = @@HATCHLING_MESSAGES.keys.sample
            @target.set_race_id(@game.race_data.select { |k, v| v[:name] == race_name }.first[0])
            @target.output("#{@@HATCHLING_MESSAGES[ race_name ].join("\n")}")
            self.clear(silent: true)
        end
    end

end
