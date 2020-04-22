require_relative 'command.rb'

class CommandBlind < Command

    def initialize
        super(
            name: "blind",
            keywords: ["blind"],
            lag: 0.4,
            position: :standing
        )
    end

    def attempt( actor, cmd, args, input )
        if not actor.affected? "blind"
            actor.output "You have been blinded!"
            AffectBlind.new( actor, actor, actor.level ).apply
            return true
        else
            actor.output "You are already blind!"
            return false
        end
    end
end

class CommandBuy < Command

    def initialize
        super(
            name: "buy",
            keywords: ["buy"],
            lag: 0,
            position: :resting
        )
    end

    # buy and sell need a default quantity of '1', since otherwise the targeting system would buy the entire stock of a shop at once

    def attempt( actor, cmd, args, input )
        ( shopkeepers = actor.target( list: actor.room.mobiles, affect: "shopkeeper", visible_to: actor, not: actor ) ).each do |shopkeeper|
            ( actor.target({ list: shopkeeper.inventory.items, visible_to: actor }.merge( args.first.to_s.to_query( 1 ) )) ).each do |purchase|
                if actor.spend( shopkeeper.sell_price( purchase ) )
                    actor.output( "You buy 0<n> for #{ shopkeeper.sell_price( purchase ).to_worth }.", [purchase] )
                    shopkeeper.earn( shopkeeper.sell_price( purchase ) )
                    purchase.move( actor.inventory )
                end
            end
        end.empty? and begin
            actor.output "You can't do that here."
            return false
        end
    end

end
