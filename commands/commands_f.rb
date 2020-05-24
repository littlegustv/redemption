require_relative 'command.rb'

class CommandFind < Command

    def initialize
        super(
            name: "find",
            keywords: ["find"],
            lag: 0,
            position: :sleeping
        )
    end


    def attempt( actor, cmd, args, input )
        if args.length <= 0
            actor.output "Syntax: find <keywords>"
            return false
        else
            args = args.map{ |arg| arg.split(/[' ]/) }.flatten.reject(&:nil?).reject(&:empty?)
            item_models = Game.instance.item_models.values
            args.each do |arg|

                item_models = item_models.reject { |model| !model.keywords.any? { |keyword| keyword.fuzzy_match(arg) } }
            end
            if item_models.size == 0
                actor.output "No items found."
            else
                actor.output "    ID  Level  Name"
                actor.output item_models.map { |model| "#{model.id.to_s.lpad(6)}  #{model.level.to_s.lpad(5)}  #{model.name}" }.join("\n")
            end
            return true
        end
    end

end

class CommandFlee < Command

    def initialize
        super(
            name: "flee",
            keywords: ["flee"],
            lag: 0.5,
            position: :standing
        )
    end

    def attempt( actor, cmd, args, input )
        if !actor.attacking
            actor.output "But you aren't fighting anyone!"
            return false
        elsif rand(0..10) < 5
            actor.output "You flee from combat!"
            (actor.room.occupants - [actor]).each_output "0<N> has fled!", [ actor ]
            actor.stop_combat
            actor.do_command(actor.room.exits.map(&:direction).sample.name)
            return true
        else
            actor.output "PANIC! You couldn't escape!"
            return true
        end
    end
end

class CommandFollow < Command

    def initialize
        super(
            name: "follow",
            keywords: ["follow"],
            lag: 0,
            position: :standing
        )
    end

    def attempt( actor, cmd, args, input )
        if args.first.nil?
            actor.remove_affect("follow")
        elsif ( target = actor.target({ list: actor.room.occupants, not: actor, visible_to: actor }.merge( args.first.to_s.to_query )).first )
            AffectFollow.new( actor, target, 1 ).apply
        else
            actor.output "They aren't here"
        end
    end
end
