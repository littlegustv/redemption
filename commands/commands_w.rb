require_relative 'command.rb'

class CommandWake < Command

    def initialize
        super(
            name: "wake",
            keywords: ["wake"],
            priority: 200
        )
    end

    def attempt( actor, cmd, args, input )
        target = actor
        if args.first
            target = actor.target({ visible_to: actor, list: actor.room.occupants - [actor] }.merge( args.first.to_s.to_query(1) )).first
        end
        if target == actor
            if actor.position == :sleeping
                data = { success: true }
                Game.instance.fire_event( actor, :event_try_wake, data )
                if data[:success]
                    actor.output "You wake and stand up."
                    (actor.room.occupants - [actor]).each_output "0<N> wakes and stands up.", [actor]
                    actor.position = :standing.to_position
                    actor.look_room
                    return true
                else
                    actor.output "You can't wake up!"
                    return false
                end
            elsif actor.position == :resting || actor.position == :standing
                actor.output "You are already awake."
                return false
            else
                actor.output "You can't quite get comfortable enough."
                return false
            end
        elsif target
            if target
                if target.position == :sleeping
                    data = { success: true }
                    Game.instance.fire_event( actor, :event_try_wake, data )
                    if data[:success]
                        actor.room.occupants.each_ouptut "0<N> wake0<,s> 1<n> up.", [actor, target]
                        target.position = :standing.to_position
                        target.look_room
                        return true
                    else
                        actor.output "You can't wake 0<n>!", [target]
                        return false
                    end
                elsif target.position == :resting || target.position == :standing
                    actor.output "They aren't asleep."
                    return false
                else
                    actor.output "You can't quite get comfortable enough."
                    return false
                end
            end
        else
            actor.output "You don't see anyone like that here."
        end

    end
end

class CommandWear < Command

    def initialize
        super(
            name: "wear",
            keywords: ["wear", "hold", "wield"],
            position: :resting
        )
    end

    def attempt( actor, cmd, args, input )
        if args.first == "all"
            actor.wear_all
            return true
        end
        if ( targets = actor.target({ visible_to: actor, list: actor.inventory.items }.merge( args.first.to_s.to_query(1) )) )
            targets.each do |target|
                actor.wear(item: target)
            end
            return true
        else
            actor.output "You don't have that."
            return false
        end
    end

end

class CommandWeather < Command

    def initialize
        super(
            name: "weather",
            keywords: ["weather"],
            position: :resting
        )
    end

    def attempt( actor, cmd, args, input )
        if actor.room.affected? "indoors"
            actor.output "You can't see the weather indoors!"
        else
            actor.output "The sky is cloudy and a warm southerly breeze blows."
        end
        return true
    end

end

class CommandWhere < Command

    def initialize
        super(
            name: "where",
            keywords: ["where"],
            position: :resting
        )
    end

    def attempt( actor, cmd, args, input )
        targets = actor.target( {  list: actor.room.area.players, visible_to: actor, where_to: actor } )
        actor.output %Q(
Current Area: #{ actor.room.area }. Level Range: ? ?
Players near you:
#{ targets.map{ |t| "#{t.to_s.rpad(28)} #{t.room}" }.join("\n") })
        return true
    end

end

class CommandWhitespace < Command

    def initialize
        super(
            name: "whitespace",
            keywords: [""],
            priority: 99999
        )
    end

    def attempt( actor, cmd, args, input )
        actor.delayed_output
        return true
    end

end

class CommandWho < Command

    def initialize
        super(
            name: "who",
            keywords: ["who"],
            priority: 200
        )
    end

    def attempt( actor, cmd, args, input )
        targets = actor.target( { type: "Player", visible_to: actor } )
        out = ""
        Game.instance.continents.values.each do |continent|
            out += "----==== Characters #{continent.preposition} #{continent.name} ====----\n"
            out += "\n#{ targets.select{ |t| t.room.continent == continent }.map(&:who).join("\n")}\n\n"
        end
        out += "Players found: #{targets.count}"
        actor.output(out)
        return true
    end

end

class CommandWorth < Command

    def initialize
        super(
            name: "worth",
            keywords: ["worth"],
            priority: 200,
            lag: 0
        )
    end

    def attempt( actor, cmd, args, input )
        actor.output "You have #{actor.wealth.to_worth}"
        return true
    end

end
