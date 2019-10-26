require_relative 'skill.rb'

class SkillEnvenom < Skill

    def initialize(game)
        super(
            game: game,
            name: "envenom",
            keywords: ["envenom"],
            lag: 0.25,
            position: Constants::Position::STAND,
        )
    end

    def attempt( actor, cmd, args, input )
        if ( target = @game.target({ list: actor.items, item_type: "weapon", visible_to: actor }.merge( args.first.to_s.to_query ) ).first )
	        target.apply_affect( AffectPoison.new( source: nil, target: target, level: actor.level, game: @game ) )
        end
        return true
    end
end