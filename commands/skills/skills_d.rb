require_relative 'skill.rb'

class SkillDisarm < Skill

    def initialize
        super()
        @name = "disarm"
        @keywords = ["disarm"]
        @lag = 2
        @position = Position::STAND
    end

    def attempt( actor, cmd, args )
        if not actor.attacking
        	actor.output "But you aren't fighting anyone!"
        elsif not actor.attacking.equipment[:wield]
        	actor.output "They aren't wielding a weapon."
        else
        	actor.output "You disard %s!", [actor.attacking]
        	actor.attacking.output "You have been disarmed!"
        	actor.broadcast "%s disarms %s", actor.target({ not: [ actor, actor.attacking ], room: actor.room }), [actor, actor.attacking]
        	actor.attacking.equipment[:wield].room = actor.room
        	actor.attacking.equipment[:wield] = nil
        end
    end
end

class SkillDirtKick < Skill

    def initialize
        super(
            name: "dirt kick",
            keywords: ["blind", "dirt kick"],
            lag: 2,
            position: Position::STAND
        )
    end

    def attempt( actor, cmd, args )
        if args.length <= 0 and actor.attacking.nil?
            actor.output "Who did you want to dirt kick?"
            return
        end
        if actor.position < Position::STAND
            actor.output "You have to stand up first."
        elsif actor.attacking and args.length <= 0
            do_dirtkick( actor, actor.attacking )
        elsif ( kill_target = actor.target({ room: actor.room, not: actor, type: ["Mobile", "Player"], visible_to: actor }.merge( args.first.to_s.to_query )).first )
            kill_target.start_combat actor
            actor.start_combat kill_target
            do_dirtkick( actor, kill_target )
        else
            actor.output "I can't find anyone with that name."
        end
    end

    def do_dirtkick( actor, target )
        if not target.affected? "blind"
            target.output "You are blinded by the dirt in your eyes!"
            actor.broadcast "%s is blinded by the dirt in their eyes!", actor.target({ quantity: "all", room: actor.room,  not: target }), [target]
            target.apply_affect(AffectBlind.new(source: actor, target: target, level: actor.level))
        else
            target.output "They are already blind!"
        end
    end
end