require_relative 'command.rb'

class CommandLook < Command

    def initialize
        super({
            keywords: ["look"],
            priority: 200,
            position: Position::REST
        })
    end

    def attempt( actor, cmd, args )
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

class CommandLore < Command

    def initialize
        super({
            keywords: ["lore"],
            position: Position::REST
        })
    end

    def attempt( actor, cmd, args )
        if args.length <= 0
            actor.output "What did you want to lore?"
            return
        end
        if ( target = ( actor.inventory + actor.equipment.values ).reject(&:nil?).select { |item| item.fuzzy_match( args.first.to_s ) && actor.can_see?(item) }.first )
            actor.output target.lore
        end
    end
end
