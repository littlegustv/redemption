require_relative 'skill.rb'

class SkillBash < Command

    def initialize
        super()
        @name = "bash"
        @keywords = ["bash"]
        @lag = 2
        @position = Position::STAND
    end

    def attempt( actor, cmd, args )
        if args.length <= 0 and actor.attacking.nil?
            actor.output "Who did you want to bash?"
            return
        end
        if actor.position < Position::STAND
            actor.output "You have to stand up first."
        elsif actor.attacking and args.length <= 0
            do_bash( actor, actor.attacking )
        elsif ( kill_target = actor.target({ room: actor.room, not: actor, type: ["Mobile", "Player"], visible_to: actor }.merge( args.first.to_s.to_query )).first )
            kill_target.start_combat actor
            actor.start_combat kill_target
            do_bash( actor, kill_target )
        else
            actor.output "I can't find anyone with that name."
        end
    end

    def do_bash( actor, target )
        m, t, r = actor.hit 100, "bash"
        actor.output "You slam into %s, and send him flying!", [target]
        actor.output m, [target]
        target.output "%s sends you flying with a powerful bash!", [actor]
        target.output t, [actor]
        actor.broadcast "%s sends %s flying with a powerful bash!", actor.target({ not: [ actor, target ], room: actor.room }), [actor, target]
        actor.broadcast r, actor.target({ not: [ actor, target ], room: actor.room }), [actor, target]
        target.damage( 100, actor )
        target.lag += 0.5
    end
end

class SkillBerserk < Command

    def initialize
        super()
        @name = "berserk"
        @keywords = ["berserk"]
        @lag = 0.5
        @position = Position::STAND
    end

    def attempt( actor, cmd, args )
        if not actor.affected? "berserk"
            actor.apply_affect(AffectBerserk.new(source: actor, target: actor, level: actor.level))
        else
            actor.output "You are already pretty mad."
        end
    end
end
