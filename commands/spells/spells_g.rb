require_relative 'spell.rb'

class SpellGate < Spell

    def initialize
        super(
            name: "gate",
            keywords: ["gate"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 25
        )
    end

    def attempt( actor, cmd, args, input, level )
        target = nil
        if actor.can_see?(nil)
            target = actor.filter_visible_targets(Game.instance.target_global_mobiles(args.first.to_s.to_query).shuffle, 1).first
        end
        if target
            actor.output "You step through a gate and vanish."
            (target.room.occupants - [actor]).each_output "0<N> steps through a gate and vanishes.",actor.room.occupants - [actor], [actor]
            actor.move_to_room target.room
            (target.room.occupants - [actor]).each_output "0<N> has arrived through a gate.", [actor]
        else
            actor.output "You can't find anyone with that name."
        end
    end

end

class SpellGrandeur < Spell
    def initialize
        super(
            name: "grandeur",
            keywords: ["grandeur"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
        actor.apply_affect( AffectGrandeur.new( nil, actor, actor.level ) )
    end
end
