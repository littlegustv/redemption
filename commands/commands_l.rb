require_relative 'command.rb'

class CommandLeave < Command
  def initialize
    super({
      keywords: ["leave"],
      position: Position::REST
    })
  end

  def attempt( actor, cmd, args )
    if actor.group.any?
      actor.output "You can't leave the group, you're the leader!"
    elsif actor.in_group.nil?
      actor.output "You're not in a group."
    else
      actor.remove_from_group
    end
  end
end

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
        elsif ( target = actor.target({ room: actor.room, type: ["Mobile"], visible_to: actor }.merge( args.first.to_s.to_query )).first )
            actor.output %Q(#{target.full}
#{target.condition}

#{target} is using:
#{target.show_equipment})
        else
            actor.output "You don't see anyone like that here."
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
        if (target = actor.target({ list: actor.inventory + actor.equipment.values, visible_to: actor }.merge( args.first.to_s.to_query ).merge({ quantity: 1 })).to_a.first)
            actor.output target.lore
        else
            actor.output "You can't find it."
        end
    end
end
