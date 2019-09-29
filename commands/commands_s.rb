require_relative 'command.rb'

class CommandSay < Command

    def initialize(game)
        super(
            game: game,
            name: "say",
            keywords: ["say", "'"],
            position: Position::REST
        )
    end

    def attempt( actor, cmd, args )
        if args.length <= 0
            actor.output 'Say what?'
            return false
        else
            actor.output "{yYou say '#{args.join(' ')}'{x"
            actor.broadcast "{y%s says '#{args.join(' ')}'{x", actor.target( { :not => actor, :room => actor.room }), [actor]
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

    def attempt( actor, cmd, args )
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
            position: Position::REST
        )
    end

    def attempt( actor, cmd, args )
        if ( shopkeeper = actor.target({ list: actor.room.occupants, affect: "shopkeeper" }).first )
            actor.target({ list: actor.inventory }.merge( args.first.to_s.to_query ) ).each do |sale|
                if shopkeeper.spend( sale.cost )
                    shopkeeper.inventory.push sale
                    actor.inventory.delete sale
                    actor.earn( sale.cost )
                    actor.output( "You sell #{sale} for #{ sale.to_price }." )
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

    def attempt( actor, cmd, args )
        actor.output %Q(Skills:
Level  1: #{ actor.skills.each_slice(2).map{ |row| "#{row[0].to_s.ljust(18)} 100%      #{row[1].to_s.ljust(18)} 100%" }.join("\n" + " "*10)})
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

    def attempt( actor, cmd, args )
        actor.output %Q(Spells:
Level  1: #{ actor.spells.each_slice(2).map{ |row| "#{row[0].to_s.ljust(18)} 100%      #{row[1].to_s.ljust(18)} 100%" }.join("\n" + " "*10)})
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

    def attempt( actor, cmd, args )
        case actor.position
        when Position::SLEEP
            actor.output "You are already asleep."
            return false
        when Position::REST, Position::STAND
            actor.output "You go to sleep."
            actor.broadcast "%s lies down and goes to sleep.", actor.target( { :not => actor, :room => actor.room }), [actor]
        else
            actor.output "You can't quite get comfortable enough."
            return false
        end
        actor.position = Position::SLEEP
        return true
    end
end

class CommandStand < Command

    def initialize(game)
        super(
            game: game,
            name: "stand",
            keywords: ["stand", "wake"],
            priority: 200
        )
    end

    def attempt( actor, cmd, args )
        keyword = @keywords.select{ |keyword| keyword.fuzzy_match( cmd ) }.first
        if keyword == "wake" && actor.position != Position::SLEEP
            actor.output "You're already awake!"
            return false
        end
        case actor.position
        when Position::SLEEP
            actor.output "You wake and stand up."
            actor.broadcast "%s wakes and stands up.", actor.target( { :not => actor, :room => actor.room }), [actor]
            actor.position = Position::STAND
            actor.look_room
            return true
        when Position::REST
            actor.output "You stand up."
            actor.broadcast "%s stands up.", actor.target( { :not => actor, :room => actor.room }), [actor]
            actor.position = Position::STAND
            return true
        when Position::STAND
            actor.output "You are already standing."
            return false
        else
            actor.output "You can't quite get comfortable enough."
            return false
        end
    end
end
