require_relative 'command.rb'

class CommandQuest < Command

    def initialize
        super(
            name: "quest",
            keywords: ["quest"],
            lag: 0,
            position: Constants::Position::REST
        )
    end

    def attempt( actor, cmd, args, input )
        if args.first.to_s.fuzzy_match "INFO"
            if actor.affected? "quest"
                actor.output "QUEST DESCRIPTION"
            else
                actor.output "You aren't currently on a quest."
            end
        elsif args.first.to_s.fuzzy_match "TIME"
            if actor.affected? "quest"
                actor.output "QUEST TIME"
            else
                actor.output "{RYou may now quest again.{x"
            end
        elsif args.first.to_s.fuzzy_match "REQUEST"
            if actor.affected? "quest"
                actor.output "You are already on a quest!"
            else
                if ( questmaster = actor.target( list: actor.room.mobiles, affect: "questmaster", visible_to: actor, not: actor ).first )
                    actor.apply_affect( AffectQuest.new( actor, actor, actor.level ) )
                else
                    actor.output "You can't do that here."
                end
            end
        elsif args.first.to_s.fuzzy_match "COMPLETE"
            if actor.affected? "quest"
                if ( questmaster = actor.target( list: actor.room.mobiles, affect: "questmaster", visible_to: actor, not: actor ).first )
                    actor.output "QUEST COMPLETE"
                else
                    actor.output "You can't do that here."
                end
            else
                actor.output "I never sent you on a quest!  Perhaps you're thinking of someone else."
            end
        elsif args.first.to_s.fuzzy_match "RESET"
            if actor.affected? "quest"
                actor.remove_affect( "quest" )
            else
                actor.output "I never sent you on a quest!  Perhaps you're thinking of someone else."
            end
        else
            actor.output "QUEST commands: !POINTS INFO TIME REQUEST COMPLETE !LIST !BUY !TALK !DOUBLE."
            actor.output "For more information, type 'HELP QUEST'."
        end        
    end

end

class CommandQuicken < Command

    def initialize
        super(
            name: "quicken",
            keywords: ["quicken"],
            lag: 0.5,
            position: Constants::Position::STAND
        )
    end

    def attempt( actor, cmd, args, input )
        if not actor.affected? "haste"
            actor.apply_affect(AffectHaste.new( actor, actor, actor.level ))
            return true
        else
            actor.output "You are already moving as fast as you can!"
            return false
        end
    end

end

class CommandQuit < Command

    def initialize
        super(
            name: "quit",
            keywords: ["quit"],
            priority: 0,
            usable_in_combat: false
        )
    end

    def attempt( actor, cmd, args, input )
        if cmd.downcase != "quit"
            actor.output "If you want to QUIT, you'll have to spell it out."
            return
        end
        if actor.respond_to?(:quit)
            return actor.quit
        else
            actor.output "Only players can quit!"
            return false
        end
    end

end
