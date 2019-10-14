require_relative 'command.rb'

class CommandBlind < Command

    def initialize(game)
        super(
            game: game,
            name: "blind",
            keywords: ["blind"],
            lag: 0.4,
            position: Constants::Position::STAND
        )
    end

    def attempt( actor, cmd, args, input )
        if not actor.affected? "blind"
            actor.output "You have been blinded!"
            actor.apply_affect(AffectBlind.new(source: actor, target: actor, level: actor.level, game: @game))
            return true
        else
            actor.output "You are already blind!"
            return false
        end
    end
end

class CommandBuy < Command

    def initialize(game)
        super(
            game: game,
            name: "buy",
            keywords: ["buy"],
            lag: 0,
            position: Constants::Position::REST
        )
    end

    def attempt( actor, cmd, args, input )
        ( shopkeepers = actor.target( list: actor.room.mobiles, affect: "shopkeeper", visible_to: actor ) ).each do |shopkeeper|
            ( actor.target({ list: shopkeeper.inventory.items, visible_to: actor }.merge( args.first.to_s.to_query )) ).each do |purchase|

                if actor.spend( purchase.cost )
                    actor.output( "You buy #{purchase} for #{ purchase.to_price }." )
                    actor.inventory.items.unshift @game.load_item( purchase.id, nil )
                end
            end
        end.empty? and begin
            actor.output "You can't do that here."
            return false
        end
    end

end
