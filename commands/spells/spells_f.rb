require_relative 'spell.rb'

class SpellFarsight < Spell

    @@descriptors = [ "right there", "close by to the", "not too far", "off in the distance" ]

    def initialize
        super(
            name: "farsight",
            keywords: ["farsight"],
            lag: 0.25,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
        target = nil
        if actor.can_see?(nil)
            target = actor.filter_visible_targets(Game.instance.target_global_mobiles(args.first.to_s.to_query).shuffle, 1).first
        end
        if target
            # right there!
            actor.output target.room.occupants.map{ |occupant| "#{occupant}, #{describe(0, nil)}" }.join("\n")
            # each direction
            Game.instance.directions.each do |direction|
                actor.output "You scan intently #{direction.name}"
                actor.output scan( target.room, direction, 1 )
            end
        else
            actor.output "You can't find anyone with that name."
        end
    end

    def describe( distance, direction )
        if distance == 0
            return @@descriptors[ distance ]
        else
            return "#{@@descriptors[ distance ]} #{direction.to_s}"
        end
    end

    def scan( room, direction, distance )
        output = ""
        if distance >= 3
            return ""
        elsif ( newroom = room.exits.find { |exit| exit.direction == direction } )
            output += newroom.occupants.map{ |occupant| "#{occupant}, #{describe(distance, direction)}" }.join("\n")
            return output + scan( newroom, direction, distance + 1 )
        else
            return ""
        end
    end
end

class SpellFireball < Spell

    def initialize
        super(
            name: "fireball",
            keywords: ["fireball"],
            lag: 0.25,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
        (actor.room.occupants - [actor]).each_output "0<N> summons a burning ball of fire!", [actor]
        actor.output "You summon a fireball!"
        ( targets = actor.target( list: actor.room.occupants - [actor] )).each do |target|
            target.receive_damage(actor, 100, :fireball)
        end
        return true
    end
end

class SpellFireRune < Spell

    def initialize
        super(
            name: "fire rune",
            keywords: ["fire rune"],
            lag: 0.25,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
    	if actor.room.affected? "fire rune"
    		actor.output "This room is already affected by the power of flames."
            return false
    	else
    		actor.output "You place a fiery rune on the ground to singe your foes."
            (actor.room.occupants - [actor]).each_output "0<N> places a strange rune on the ground.", [actor]
    		AffectFireRune.new( actor.room, actor, actor.level ).apply
            return true
    	end
    end
end

class SpellFlamestrike < Spell

    def initialize
        super(
            name: "flamestrike",
            keywords: ["flamestrike"],
            lag: 0.25
        )
    end

    def cast( actor, cmd, args, input )
        if args.first.nil? && actor.attacking.nil?
            actor.output "Cast the spell on who, now?"
        else
            super
        end
    end

    def attempt( actor, cmd, args, input, level )
        target = nil
        if args.first.nil? && actor.attacking
            target = actor.attacking
        elsif !args.first.nil?
            target = actor.target( argument: args[0], list: actor.room.occupants ).first
        end
        if !target
            actor.output "They aren't here."
            return false
        end
        target.receive_damage(actor, 100, :flamestrike)
        return true
    end
end

class SpellFly < Spell

    def initialize
        super(
            name: "fly",
            keywords: ["fly"],
            lag: 0.25,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
        if args.first.nil?
            AffectFly.new( actor, actor, actor.level ).apply
        elsif ( target = actor.target( argument: args[0], list: actor.room.occupants - [actor] ).first )
            AffectFly.new( target, actor, actor.level ).apply
        else
            actor.output "There is no one here with that name."
        end
    end
end

class SpellFrenzy < Spell
    def initialize
        super(
            name: "frenzy",
            keywords: ["frenzy"],
            lag: 0.25,
            mana_cost: 10,
        )
    end

    def attempt( actor, cmd, args, input, level )
        if args.first.nil?
            AffectFrenzy.new( actor, nil, level || actor.level ).apply
        elsif ( target = actor.target( argument: args[0], list: actor.room.occupants - [actor] ).first )
            AffectFrenzy.new( target, nil, level || actor.level ).apply
        else
            actor.output "There is no one here with that name."
        end
    end
end
