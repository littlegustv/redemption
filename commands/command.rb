class Command

    attr_reader :priority

    def initialize( options )
        @priority = 100
        @keywords = ["CommandDefault"]
        @lag = 0
        @starts_combat = false
        @usable_while_fighting = true
        @position = Position::SLEEP
        options.each do |key, value|
            self.instance_variable_set("@#{key}", value)
        end
    end

    def check( cmd )
        @keywords.select{ |keyword| keyword.fuzzy_match( cmd ) }.any?
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
            return
        end
        if actor.position >= Position::FIGHT && !@usable_while_fighting
            actor.output "No way! You're still fighting!"
            return
        end

        attempt( actor, cmd, args )
        actor.lag += @lag
    end

    def attempt( actor, cmd, args )
        actor.output "Default command"
    end

end
