require_relative 'skill.rb'

class SkillBackstab < Command

    def initialize
        super(
            name: "backstab",
            keywords: ["backstab"],
            lag: 1,
            position: :standing
        )
    end

    def attempt( actor, cmd, args, input )
        if args.length <= 0 and actor.attacking.nil?
            actor.output "Who did you want to backstab?"
            return false
        end
        if actor.attacking and args.length <= 0
            do_backstab( actor, actor.attacking )
            return true
        elsif ( kill_target = actor.target({ list: actor.room.occupants, not: actor, visible_to: actor }.merge( args.first.to_s.to_query )).first )
            do_backstab( actor, kill_target )
            return true
        else
            actor.output "I can't find anyone with that name."
            return false
        end
    end

    def do_backstab( actor, target )
        if target.condition_percent >= 50
            actor.weapon_hit(target, actor.level, actor.level, nil, nil, "backstab")

        else
            actor.output "0<N> is hurt and suspicious... you can't sneak up.", [target]
        end
    end
end

class SkillBash < Skill

    def initialize
        super(
            name: "bash",
            keywords: ["bash"],
            lag: 2,
            position: :standing
        )
        @data[:target_lag] = 0.5
    end

    def attempt( actor, cmd, args, input )
        target = nil
        if args.length > 0
            target = actor.target({ list: actor.room.occupants + actor.room.exits.values, visible_to: actor }.merge( args.first.to_s.to_query )).first
        else
            target = actor.attacking
        end
        if target.nil?
            actor.output "Who did you want to bash?"
            return false
        end
        if target == actor
            actor.output "You fall flat on your face!"
            return true
        end
        do_bash( actor, target )
        return true
    end

    def do_bash( actor, target )
        if target.class == Exit
            unlocked = target.unlock( actor, silent: true, override: true )
            opened = target.open( actor, silent: true, override: true )
            # check both opened and unlocked seperately, since you might be bashing a closed, unlocked door
            if opened || unlocked
                actor.output "Bang!* You bash the door in."
                (actor.room.occupants - [actor]).each_output "0<N> bashes in the #{ target.short }.", actor.room.occupants - [actor], [actor]
                if target.pair
                    (target.pair.origin.occupants - [actor]).each_output "The #{ target.short } is suddenly thrown backwards!"
                end
            else
                #
            end
        else
            actor.output "You slam into 0<n>, and send 0<o> flying!", [target]
            (actor.room.occupants - [actor]).each_output "0<N> sends 1<n> flying with a powerful bash!", [actor, target]
            target.receive_damage(actor, 100, :bash)
            target.lag += @data[:target_lag]
        end
    end
end

class SkillBerserk < Skill

    def initialize
        super(
            name: "berserk",
            keywords: ["berserk"],
            lag: 0.5,
            position: :standing
        )
    end

    def attempt( actor, cmd, args, input )
        if not actor.affected? "berserk"
            AffectBerserk.new( actor, actor, actor.level ).apply
            return true
        else
            actor.output "You are already pretty mad."
            return false
        end
    end
end
