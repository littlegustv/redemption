require_relative 'skill.rb'

class SkillDisarm < Skill

    def initialize
        super(
            name: "disarm",
            keywords: ["disarm"],
            lag: 2,
            position: Constants::Position::STAND
        )
    end

    def attempt( actor, cmd, args, input )
        if not actor.attacking
        	actor.output "But you aren't fighting anyone!"
            return false
        elsif not actor.attacking.wielded.first
        	actor.output "They aren't wielding a weapon."
            return false
        else
            target = actor.attacking
            weapon = target.wielded.shuffle.first
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
            position: Constants::Position::STAND
        )
    end

    def attempt( actor, cmd, args, input )
        if args.length <= 0 and actor.attacking.nil?
            actor.output "Who did you want to dirt kick?"
            return false
        end
        if actor.position < Constants::Position::STAND
            actor.output "You have to stand up first."
            return false
        elsif actor.attacking and args.length <= 0
            do_dirtkick( actor, actor.attacking )
            return true
        elsif ( kill_target = actor.target({ list: actor.room.occupants, not: actor, type: ["Mobile", "Player"], visible_to: actor }.merge( args.first.to_s.to_query )).first )
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
            target.apply_affect(AffectBlind.new( actor, target, actor.level ))
            actor.deal_damage(target: target, damage: 5, noun:"bash", element: Constants::Element::NONE, type: Constants::Damage::PHYSICAL, silent: true)
        else
            target.output "They are already blind!"
        end
    end
end
