require_relative 'skill.rb'

class SkillTrip < Skill

    def initialize
        super(
            name: "trip",
            keywords: ["trip"],
            lag: 2,
            position: :standing
        )
    end

    def attempt( actor, cmd, args, input )
        target = nil
        if args.length <= 0 and actor.attacking.nil?
            actor.output "Who did you want to trip?"
            return false
        end
        if actor.attacking and args.length <= 0
            target = actor.attacking
        elsif ( kill_target = actor.target({ list: actor.room.occupants, not: actor, visible_to: actor }.merge( args.first.to_s.to_query )).first )
            target = kill_target
        else
            actor.output "I can't find anyone with that name."
            return false
        end
        do_trip(actor, target)
        return true
    end

    def do_trip( actor, target )
        [actor, target].each_output "0<N> trip0<,s> 1<n> and 1<u> go0<es,> down!", [actor, target]
        (actor.room.occupants - [actor, target]).each_output "0<N> trips 1<n>, sending 1<o> to the ground.", [actor, target]
        target.receive_damage(actor, 5, :trip)
        AffectStun.new( target, nil, actor.level ).apply
    end

end
