require_relative 'skill.rb'

class SkillDisarm < Skill

    def initialize
        super(
            name: "disarm",
            keywords: ["disarm"],
            lag: 2,
            position: :standing
        )
    end

    def attempt( actor, cmd, args, input )
        if not actor.attacking
        	actor.output "But you aren't fighting anyone!"
            return false
        elsif not actor.attacking.equipped(Weapon).first
        	actor.output "They aren't wielding a weapon."
            return false
        else
            target = actor.attacking
            weapon = target.equipped(Weapon).shuffle.first
            if !target.can_unwear(weapon)
                actor.output("Their weapon won't budge!")
                return false
            end
            # stat check here?
        	actor.output "You disarm 0<n>!", [actor.attacking]
        	actor.attacking.output "You have been disarmed!"
        	(actor.room.occupants - [ actor, actor.attacking ]).each_output "0<N> disarms 1<n>!" [actor, actor.attacking]
            weapon.move(actor.attacking.inventory)
            actor.attacking.drop_item(weapon)
            return true
        end
    end
end

class SkillDirtKick < Skill

    def initialize
        super(
            name: "dirt kick",
            keywords: ["dirt kick"],
            lag: 2,
            position: :standing
        )
    end

    def attempt( actor, cmd, args, input )
        if args.length <= 0 and actor.attacking.nil?
            actor.output "Who did you want to dirt kick?"
            return false
        end
        if actor.attacking and args.length <= 0
            do_dirtkick( actor, actor.attacking )
            return true
        elsif ( kill_target = actor.target( argument: args[0], list: actor.room.occupants - [actor] ).first )
            do_dirtkick( actor, kill_target )
            return true
        else
            actor.output "I can't find anyone with that name."
            return false
        end
    end

    def do_dirtkick( actor, target )
        if not target.affected? "blind"
            actor.room.occupants.each_output "0<N> is blinded by the dirt in 0<p> eyes!", [target]
            AffectBlind.new( target, actor, actor.level ).apply
            target.receive_damage(actor, 5, :dirt_kick, true)
        else
            target.output "They are already blind!"
        end
    end
end
