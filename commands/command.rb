class Command

    attr_reader :priority, :name

    def initialize(
        game: nil,
        name: "defaultcommand",
        priority: 100,
        keywords: ["defaultcommand"],
        lag: 0,
        usable_in_combat: true,
        position: Position::SLEEP,
        hp_cost: 0,
        mana_cost: 0,
        movement_cost: 0
    )
        @game = game
        @priority = priority
        @keywords = keywords
        @lag = lag
        @name = name
        @usable_in_combat = usable_in_combat
        @position = position
        @hp_cost = hp_cost
        @mana_cost = mana_cost
        @movement_cost = movement_cost
    end

    def check( cmd )
        @keywords.select{ |keyword| keyword.fuzzy_match( cmd ) }.any?
    end

    def to_s
        @name
    end

    def execute( actor, cmd, args )
        if actor.position < @position # Check position
            case actor.position
            when Position::SLEEP
                actor.output "In your dreams, or what?"
            when Position::REST
                actor.output "Nah... You feel too relaxed..."
            else
                actor.output "You can't quite get comfortable enough."
            end
            return false
        end
        if actor.position >= Position::FIGHT && !@usable_in_combat
            actor.output "No way! You're still fighting!"
            return false
        end

        success = attempt( actor, cmd, args )
        actor.lag += @lag if success
        return success
    end

    def attempt( actor, cmd, args )
        actor.output "Default command"
    end

end
