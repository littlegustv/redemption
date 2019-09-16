require_relative 'affect.rb'

class AffectHaste < Affect

    def initialize(source:, target:, level:)
        super(
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

    def initialize(source:, target:, level:, race_data:)
        super(
            source: source,
            target: target,
            keywords: ["hatchling"],
            name: "hatchling",
            level:  level,
            modifiers: {none: 0},
            permanent: true,
            hidden: true
        )

        @race_data = race_data
        @conditions.push( AffectCondition.new(@target, [:race_id], :==, @target.race_id, []) )
    end

    def start
        @target.output "You feel yourself moving more hatchlingly."
    end

    def hook
        @target.add_event_listener(:event_on_level_up, self, :hatch)
    end

    def unhook
        @target.delete_event_listener(:event_on_level_up, self)
    end

    def hatch(data)
        if data[:level] >= 2
            race_name = Constants::HATCHLING_MESSAGES.keys.sample
            puts @race_data.select { |k, v| v[:name] == race_name }
            @target.race_id = @race_data.select { |k, v| v[:name] == race_name }.first[0]
            @target.output("#{Constants::HATCHLING_MESSAGES[ race_name ].join("\n")}")
        end
    end

end
