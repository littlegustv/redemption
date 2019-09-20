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
            modifiers: {dex: [1, (level / 10).to_i].max, attack_speed: 1}
        )
    end

    def start
        @target.output "You feel yourself moving more quickly."
    end

    def complete
        @target.output "You feel yourself slow down."
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
        @conditions.push( AffectCondition.new(@target, [:race_id], :==, @target.race_id, []) )
    end

    def hook
        @target.add_event_listener(:event_on_level_up, self, :hatch)
    end

    def unhook
        @target.delete_event_listener(:event_on_level_up, self)
    end

    def hatch(data)
        if data[:level] >= 2
            race_name = @@HATCHLING_MESSAGES.keys.sample
            @target.set_race_id(@game.race_data.select { |k, v| v[:name] == race_name }.first[0])
            @target.output("#{@@HATCHLING_MESSAGES[ race_name ].join("\n")}")
            self.clear(call_complete: false)
        end
    end

end
