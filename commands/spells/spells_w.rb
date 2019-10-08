require_relative 'spell.rb'

class SpellWeaken < Spell

    def initialize(game)
        super(
            game: game,
            name: "weaken",
            keywords: ["weaken"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 10
        )
    end

    def cast( actor, cmd, args )
        if args.first.nil? && actor.attacking.nil?
            actor.output "Cast the spell on who, now?"
        else
            super
        end
    end

    def attempt( actor, cmd, args, level )
        target = nil
        if args.first.nil? && actor.attacking
            target = actor.attacking
        elsif !args.first.nil?
            target = actor.target({ list: actor.room.occupants, visible_to: actor }.merge( args.first.to_s.to_query )).first
        end
        if !target
            actor.output "They aren't here."
            return false
        end
        target.apply_affect( AffectWeaken.new( source: actor, target: target, level: actor.level, game: @game ) )
        target.start_combat( actor )
        return true
    end
    
end
