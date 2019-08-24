class Command

    def initialize( keywords, lag = 0, position = Position::STAND )
        @keywords = keywords
        @lag = lag
        @position = position
    end

    def check( cmd )
        @keywords.select{ |keyword| keyword.fuzzy_match( cmd ) }.any?
    end

    def execute( actor, args )
        attempt( actor, args )
        actor.lag += @lag
    end

    def attempt( actor, args )
        actor.delayed_output
    end

end

class Down < Command
    def attempt( actor, args )
        actor.move "down"
    end
end

class Up < Command
    def attempt( actor, args )
        actor.move "up"
    end
end

class East < Command
    def attempt( actor, args )
        actor.move "east"
    end
end

class West < Command
    def attempt( actor, args )
        actor.move "west"
    end
end

class North < Command
    def attempt( actor, args )
        actor.move "north"
    end
end

class South < Command
    def attempt( actor, args )
        actor.move "south"
    end
end

class Who < Command
    def attempt( actor, args )
        targets = actor.target( { type: "Player", visible_to: actor } )
        actor.output %Q(
----==== Characters on Terra ====----

#{ targets.select{ |t| t.room.continent == "terra" }.map(&:who).join("\n") }

----==== Characters on Dominia ====----

#{ targets.select{ |t| t.room.continent == "dominia" }.map(&:who).join("\n") }

Players found: #{targets.count})
    end
end

class Where < Command
    def attempt( actor, args )
        targets = actor.target( { type: "Player", area: actor.room.area, visible_to: actor } )
        actor.output %Q(
Current Area: #{ actor.room.area }. Level Range: ? ?
Players near you:
#{ targets.map{ |t| "#{t.to_s.ljust(28)} #{t.room}" }.join("\n") }
        )
    end
end

class Help < Command

    def initialize( keywords, helps )
        @helps = helps
        super( keywords, 0, Position::SLEEP )
    end

    def attempt( actor, args )
        if args.count == 0
            args.push("summary")
        end
        matches = []
        @helps.each do |help|
            valid_help = true
            args.each do |arg|
                if !help[:keywords].any? { |keyword| keyword.fuzzy_match( arg ) }
                    valid_help = false
                    break
                end
            end
            if valid_help
                matches.push help
            end
        end

        help_out = matches.map{ |row| "#{ row[:keywords].join(" ") }\n\n#{ row[:text] }" }.join("\n\n#{"=" * 80}\n\n")

        actor.output(help_out)
    end
end

class Qui < Command
    def attempt( actor, args )
        actor.output "If you want to QUIT, you'll have to spell it out."
    end
end

class Quit < Command
    def attempt( actor, args )
        actor.quit
    end
end

class Look < Command
    def attempt( actor, args )
        if args.length <= 0
            actor.output actor.room.show( actor )
        elsif ( target = actor.target({
            room: actor.room,
            keyword: args.first.gsub(/\A(\d+)\./, ""),
            type: ["Mobile"],
            visible_to: actor,
            offset: args.first.match(/\A\d+\./).to_s.to_i
        }).first )
            actor.output %Q(
#{target.full}
#{target.condition}

#{target} is using:
#{target.show_equipment}
            )
        end
    end
end

class Say < Command
    def attempt( actor, args )
        if args.length <= 0
            actor.output 'Say what?'
        else
            actor.output "{yYou say '#{args.join(' ')}'{x"
            actor.broadcast "{y%s says '#{args.join(' ')}'{x", actor.target( { :not => actor, :room => actor.room }), [actor]
        end
    end
end

class Yell < Command
    def attempt( actor, args )
        if args.length <= 0
            actor.output 'Yell what?'
        else
            actor.output "{RYou yell '#{args.join(' ')}'{x"
            actor.broadcast "{R%s yells '#{args.join(' ')}'{x", actor.target( { :not => actor, :area => actor.room.area }), [actor]
        end
    end
end

class Kill < Command
    def attempt( actor, args )
        if actor.position < Position::STAND
            actor.output "You have to stand up first."
        elsif actor.position >= Position::FIGHT
            actor.output "You are already fighting!"
        elsif ( kill_target = actor.target({ room: actor.room, not: actor, keyword: args.first.to_s, type: ["Mobile", "Player"], visible_to: actor }).first )
            actor.start_combat kill_target
            kill_target.start_combat actor
        else
            actor.output "I can't find anyone with that name."
        end
    end
end

class Flee < Command
    def attempt( actor, args )
        if actor.position < Position::FIGHT
            actor.output "But you aren't fighting anyone!"
        elsif rand(0..10) < 5
            actor.output "You flee from combat!"
            actor.broadcast "%s has fled!", actor.target({ room: actor.room }), [ actor ]
            actor.stop_combat
            actor.do_command(actor.room.exits.select{ |k, v| not v.nil? }.keys.sample.to_s)
        else
            actor.output "PANIC! You couldn't escape!"
        end
    end
end

class Peek < Command
    def attempt( actor, args )
        if ( target = actor.target({ room: actor.room, keyword: args.first.to_s, type: ["Mobile"], visible_to: actor }).first )
            if target.inventory.count > 0
                actor.output "#{target} is carrying:\n#{target.inventory.map(&:to_s).join("\n")}"
            else
                actor.output "#{target} is carrying:\nNothing."
            end
        else
            actor.output "You cannot seem to catch a glimpse."
        end
    end
end

class Get < Command
    def attempt( actor, args )
        if ( target = actor.target({ room: actor.room, keyword: args.first.to_s, type: ["Item", "Weapon"], visible_to: actor }).first )
            target.room = nil
            actor.inventory.push target
            actor.output "You get #{ target }."
            actor.broadcast "%s gets %s.", actor.target({ not: actor, room: actor.room, type: "Player" }), [actor, target]
        else
            actor.output "You don't see that here."
        end
    end
end

class Drop < Command
    def attempt( actor, args )
        if ( target = actor.inventory.select { |item| item.fuzzy_match( args.first.to_s ) && actor.can_see?(item) }.first )
            target.room = actor.room
            actor.inventory.delete target
            actor.output "You drop #{target}."
            actor.broadcast "%s drops %s.", actor.target({ not: actor, room: actor.room, type: "Player" }), [actor, target]
        else
            actor.output "You don't have that."
        end
    end
end

class Inventory < Command
    def attempt( actor, args )
        actor.output %Q(
Inventory:
#{ actor.inventory.map{ |i| "#{ actor.can_see?(i) ? i.to_s : i.to_someone }" }.join("\n") }
        )
    end
end

class Wear < Command
    def attempt( actor, args )
        actor.wear args
    end
end

class Remove < Command
    def attempt( actor, args )
        actor.unwear args
    end
end

class Equipment < Command
    def attempt( actor, args )
        actor.output %Q(
You are using:
#{ actor.show_equipment }
        )
    end
end

class Blind < Command
    def attempt( actor, args )
        if not actor.affected? "blind"
            actor.output "You have been blinded!"
            actor.affects.push( AffectBlind.new( actor, ["blind"], 30, { hitroll: -5 } ) )
        else
            actor.output "You are already blind!"
        end
    end
end

class Recall < Command
    def attempt( actor, args )
        actor.recall
    end
end

class GoTo < Command

    def initialize( keywords, game )
        @game = game
        super( keywords, 0, Position::SLEEP )
    end

    def attempt( actor, args )
        area = @game.area_with_name( args.join(" ") )
        room = @game.first_room_in_area( area ) if area
        if !area || !room
            actor.output "Nothing by that name."
            return
        end
        actor.move_to_room( room )
    end
end

class Score < Command
    def attempt( actor, args )
        actor.output actor.score
    end
end

class Inspect < Command
    def attempt( actor, args )
        if ( target = actor.target({ room: actor.room, keyword: args.first.to_s, type: ["Mobile"], visible_to: actor }).first )
            actor.output target.score
        end
    end
end

class Lore < Command
    def attempt( actor, args )
        if ( target = ( actor.inventory + actor.equipment.values ).reject(&:nil?).select { |item| item.fuzzy_match( args.first.to_s ) && actor.can_see?(item) }.first )
            actor.output target.lore
        end
    end
end

class Consider < Command
    def attempt( actor, args )
        if ( target = actor.target({ room: actor.room, keyword: args.first.to_s, type: ["Mobile"], visible_to: actor }).first )
            case  target.level - actor.level
            when -51..-10
                actor.output "You can kill #{target} naked and weaponless."
            when -9..-5
                actor.output "#{target} is no match for you."
            when -6..-2
                actor.output "#{target} looks like an easy kill."
            when -1..1
                actor.output "The perfect match!"
            when 2..4
                actor.output "#{target} says 'Do you feel lucky, punk?'."
            when 5..9
                actor.output "#{target} laughs at you mercilessly."
            else
                actor.output "Death will thank you for your gift.";
            end
        end
    end
end

class Affects < Command
    def attempt( actor, args )
        actor.output %Q(
You are affected by the following spells:
#{ actor.affects.map(&:summary).join("\n") }
        )
    end
end

class Quicken < Command
    def attempt( actor, args )
        if not actor.affected? "haste"
            actor.affects.push AffectHaste.new( actor, ["quicken", "haste"], 120, { dex: 5, attack_speed: 1 } )
        else
            actor.output "You are already moving as fast as you can!"
        end
    end
end

class Berserk < Command
    def attempt( actor, args )
        if not actor.affected? "berserk"
            actor.affects.push AffectBerserk.new( actor, ["berserk"], 60, { damroll: 10, hitroll: 10 } )
        else
            actor.output "You are already pretty mad."
        end
    end
end