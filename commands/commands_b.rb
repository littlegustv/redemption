require_relative 'command.rb'

class CommandBlind < Command

    def initialize(game)
        super(
            game: game,
            name: "blind",
            keywords: ["blind"],
            lag: 0.4,
            position: Position::STAND
        )
    end

    def attempt( actor, cmd, args )
        if not actor.affected? "blind"
            actor.output "You have been blinded!"
            actor.apply_affect(AffectBlind.new(source: actor, target: actor, level: actor.level, game: @game))
        else
            actor.output "You are already blind!"
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
            position: Position::REST
        )
    end

    def attempt( actor, cmd, args )
        ( shopkeepers = actor.target( list: actor.room.mobiles, affect: "shopkeeper" ) ).each do |shopkeeper|
            if ( purchase = ( actor.target({ list: shopkeeper.inventory }.merge( args.first.to_s.to_query )) ).first )
                if actor.spend( purchase.cost )
                    actor.output( "You buy #{purchase} for #{ purchase.to_price }." )
                    actor.inventory.push actor.game.load_item( purchase.id, nil )
                    return
                else
                    shopkeeper.do_command "say You can't afford to buy #{ purchase }"
                    return
                end
            end
        end.empty? and begin
            actor.output "You can't do that here."
        end
    end

end
