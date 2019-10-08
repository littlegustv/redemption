require_relative 'spell.rb'

class SpellGate < Spell

    def initialize(game)
        super(
            game: game,
            name: "gate",
            keywords: ["gate"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 25
        )
    end

    def attempt( actor, cmd, args, input, level )
        if ( target = @game.target({ type: ["Mobile", "Player"], visible_to: actor }.merge( args.first.to_s.to_query )).first )
            actor.output "You step through a gate and vanish."
            @game.broadcast "%s steps through a gate and vanishes.", @game.target({ list: actor.room.occupants, not: actor }), [target]
            actor.move_to_room target.room
            @game.broadcast "%s has arrived through a gate.", @game.target({ list: target.room.occupants, not: actor }), [target]
        else
            actor.output "You can't find anyone with that name."
        end
    end

end