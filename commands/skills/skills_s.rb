require_relative 'skill.rb'

class SkillSneak < Skill

    def initialize(game)
        super(
            game: game,
            name: "sneak",
            keywords: ["sneak"],
            lag: 0,
            position: Constants::Position::STAND
        )
    end

    def attempt( actor, cmd, args, input )
        actor.apply_affect(AffectSneak.new(source: actor, target: actor, level: actor.level, game: @game))
        return true
    end
end

class SkillSteal < Skill

    def initialize(game)
        super(
            game: game,
            name: "steal",
            keywords: ["steal"],
            lag: 0.25,
            position: Constants::Position::STAND,
            usable_in_combat: false
        )
    end

    def attempt( actor, cmd, args, input )
        if ( mobile_target = actor.target({ list: actor.room.occupants, not: actor, visible_to: actor }.merge( args[1].to_s.to_query )).first )
            if ( item_target = actor.target({ list: mobile_target.inventory.items, visible_to: actor }.merge( args[0].to_s.to_query )).first )                
                actor.output "You pocket %s.", [ item_target ]
                actor.output "Got it!"
                item_target.move(actor.inventory)
                return true
            else
                actor.output "%s isn't carrying any '#{args[0]}'", [mobile_target]
            end
        else
            actor.output "Steal from whom now?"
            return false
        end
    end
end