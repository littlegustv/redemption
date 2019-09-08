require_relative 'command.rb'

class CommandSay < Command

    def initialize
        super()
        @name = "say"
        @keywords = ["say", "'"]
        @position = Position::REST
    end

    def attempt( actor, cmd, args )
        if args.length <= 0
            actor.output 'Say what?'
        else
            actor.output "{yYou say '#{args.join(' ')}'{x"
            actor.broadcast "{y%s says '#{args.join(' ')}'{x", actor.target( { :not => actor, :room => actor.room }), [actor]
        end
    end

end

class CommandScore < Command

    def initialize
        super
        @name = "score"
        @keywords = ["score"]
    end

    def attempt( actor, cmd, args )
        actor.output actor.score
    end
end

class CommandSkills < Command

    def initialize
        super
        @name = "skills"
        @keywords = ["skills"]
    end

    def attempt( actor, cmd, args )
        actor.output %Q(Skills:
Level  1: #{ actor.skills.each_slice(2).map{ |row| "#{row[0].to_s.ljust(18)} 100%      #{row[1].to_s.ljust(18)} 100%" }.join("\n" + " "*10)}
        )
    end

end

class CommandSpells < Command

    def initialize
        super
        @name = "spells"
        @keywords = ["spells"]
    end

    def attempt( actor, cmd, args )
        actor.output %Q(Spells:
Level  1: #{ actor.spells.each_slice(2).map{ |row| "#{row[0].to_s.ljust(18)} 100%      #{row[1].to_s.ljust(18)} 100%" }.join("\n" + " "*10)}
        )
    end

end

class CommandSleep < Command

    def initialize
        super
        @name = "sleep"
        @keywords = ["sleep"]
        @usable_in_combat = false
    end

    def attempt( actor, cmd, args )
        case actor.position
        when Position::SLEEP
            actor.output "You are already asleep."
        when Position::REST, Position::STAND
            actor.output "You go to sleep."
            actor.broadcast "%s lies down and goes to sleep.", actor.target( { :not => actor, :room => actor.room }), [actor]
        else
            actor.output "You can't quite get comfortable enough."
        end
        actor.position = Position::SLEEP
    end
end

class CommandStand < Command

    def initialize
        super
        @name = "stand"        
        @keywords = ["stand"]
    end

    def attempt( actor, cmd, args )
        case actor.position
        when Position::SLEEP
            actor.output "You wake and stand up."
            actor.broadcast "%s wakes and stands up.", actor.target( { :not => actor, :room => actor.room }), [actor]
            actor.position = Position::STAND
            actor.look_room
        when Position::REST
            actor.output "You stand up."
            actor.broadcast "%s stands up.", actor.target( { :not => actor, :room => actor.room }), [actor]
            actor.position = Position::STAND
        when Position::STAND
            actor.output "You are already standing."
        else
            actor.output "You can't quite get comfortable enough."
        end
    end
end
