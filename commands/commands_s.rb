require_relative 'command.rb'

class CommandSay < Command

    def initialize(game)
        super(
            game: game,
            name: "say",
            keywords: ["say", "'"],
            position: Constants::Position::REST
        )
    end

    def attempt( actor, cmd, args, input )
        if args.length <= 0
            actor.output 'Say what?'
            return false
        else
            message = input[/#{cmd} (.*)/, 1]
            
            data = { text: message }
            @game.fire_event( actor, :event_communicate, data )
            message = data[:text]

            actor.output "{yYou say '#{message}'{x"
            actor.broadcast "{y%s says '#{message}'{x", actor.room.occupants - [actor], [actor]
            return true
        end
    end

end

class CommandScore < Command

    def initialize(game)
        super(
            game: game,
            name: "score",
            keywords: ["score"]
        )
    end

    def attempt( actor, cmd, args, input )
        actor.output actor.score
        return true
    end
end

class CommandSell < Command

    def initialize(game)
        super(
            game: game,
            name: "sell",
            keywords: ["sell"],
            lag: 0,
            position: Constants::Position::REST
        )
    end

    # buy and sell need a default quantity of '1', since otherwise the targeting system would buy the entire stock of a shop at once

    def attempt( actor, cmd, args, input )
        if ( shopkeeper = actor.target({ visible_to: actor, list: actor.room.occupants, affect: "shopkeeper", not: actor }).first )
            actor.target({ visible_to: actor, list: actor.inventory.items }.merge( args.first.to_s.to_query( 1 ) ) ).each do |sale|
                
                # we are selling, the shopkeeper is buying, so wer use the shopkeeper 'buy price'

                if shopkeeper.spend( shopkeeper.buy_price( sale ) )
                    sale.move(shopkeeper.inventory)
                    actor.earn( shopkeeper.buy_price( sale ) )
                    actor.output( "You sell #{sale} for #{ shopkeeper.buy_price( sale ) }." )
                else
                    shopkeeper.do_command "say I'm afraid I don't have enough wealth to buy #{ sale }"
                end
            end
        else
            actor.output "You can't do that here."
            return false
        end
    end

end

class CommandSkills < Command

    def initialize(game)
        super(
            game: game,
            name: "skills",
            keywords: ["skills"]
        )
    end

    def attempt( actor, cmd, args, input )
        actor.output %Q(Skills:
Level  1: #{ actor.skills.each_slice(2).map{ |row| "#{row[0].to_s.lpad(18)} 100%      #{row[1].to_s.lpad(18)} 100%" }.join("\n" + " "*10)})
        return true
    end

end

class CommandSpells < Command

    def initialize(game)
        super(
            game: game,
            name: "spells",
            keywords: ["spells"]
        )
    end

    def attempt( actor, cmd, args, input )
        actor.output %Q(Spells:
Level  1: #{ actor.spells.each_slice(2).map{ |row| "#{row[0].to_s.lpad(18)} 100%      #{row[1].to_s.lpad(18)} 100%" }.join("\n" + " "*10)})
        return true
    end

end

class CommandSleep < Command

    def initialize(game)
        super(
            game: game,
            name: "sleep",
            keywords: ["sleep"],
            usable_in_combat: false
        )
    end

    def attempt( actor, cmd, args, input )
        case actor.position
        when Constants::Position::SLEEP
            actor.output "You are already asleep."
            return false
        when Constants::Position::REST, Constants::Position::STAND
            actor.output "You go to sleep."
            actor.broadcast "%s lies down and goes to sleep.", actor.room.occupants - [actor], [actor]
        else
            actor.output "You can't quite get comfortable enough."
            return false
        end
        actor.position = Constants::Position::SLEEP
        return true
    end
end

class CommandStand < Command

    def initialize(game)
        super(
            game: game,
            name: "stand",
            keywords: ["stand"],
            priority: 200
        )
    end

    def attempt( actor, cmd, args, input )
        case actor.position
        when Constants::Position::SLEEP
            actor.output "You wake and stand up."
            actor.broadcast "%s wakes and stands up.", actor.room.occupants - [actor], [actor]
            actor.position = Constants::Position::STAND
            actor.look_room
            return true
        when Constants::Position::REST
            actor.output "You stand up."
            actor.broadcast "%s stands up.", actor.room.occupants - [actor], [actor]
            actor.position = Constants::Position::STAND
            return true
        when Constants::Position::STAND
            actor.output "You are already standing."
            return false
        else
            actor.output "You can't quite get comfortable enough."
            return false
        end
    end
end
