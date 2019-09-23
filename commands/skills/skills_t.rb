require_relative 'skill.rb'

class SkillTrip < Skill

    def initialize(game)
        super(
            game: game,
            name: "trip",
            keywords: ["trip"],
            lag: 2,
            position: Position::STAND
        )
    end

    def attempt( actor, cmd, args )
        if args.length <= 0 and actor.attacking.nil?
            actor.output "Who did you want to bash?"
            return false
        end
        if actor.position < Position::STAND
            actor.output "You have to stand up first."
            return false
        elsif actor.attacking and args.length <= 0
            do_trip( actor, actor.attacking )
            return true
        elsif ( kill_target = actor.target({ room: actor.room, not: actor, type: ["Mobile", "Player"], visible_to: actor }.merge( args.first.to_s.to_query )).first )
            kill_target.start_combat actor
            actor.start_combat kill_target
            do_trip( actor, kill_target )
            return true
        else
            actor.output "I can't find anyone with that name."
            return false
        end
    end

    def do_trip( actor, target )
        actor.output "You trip %s and %s goes down!", [target, target]
        target.output "%s trips you and you go down!", [actor]
        actor.broadcast "%s trips %s, sending them to the ground.", actor.target({ quantity: "all", not: [ actor, target ], room: actor.room }), [actor, target]
		actor.hit 5, "trip", target
        target.apply_affect(Affect.new( name: "tripped", keywords: ["tripped", "stun"], source: actor, target: target, level: actor.level, duration: 1, modifiers: { success: -50 }, game: @game))
    end
end
