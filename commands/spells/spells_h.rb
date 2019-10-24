require_relative 'spell.rb'

class SpellHarm < Spell

    def initialize(game)
        super(
            game: game,
            name: "harm",
            keywords: ["harm"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 50
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
            target = actor.target({ list: actor.room.occupants, visible_to: actor }.merge( args.first.to_s.to_query )).first
        end
        if !target
            actor.output "They aren't here."
            return false
        end
        actor.deal_damage(target: target, damage: 100, noun:"harm", element: Constants::Element::HOLY, type: Constants::Damage::MAGICAL)
        return true
    end
end

class SpellHeal < Spell

    def initialize(game)
        super(
            game: game,
            name: "heal",
            keywords: ["heal"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 10,
            priority: 13
        )
    end

    def attempt( actor, cmd, args, input, level )
        quantity = 100
        if ( target = actor.target({ list: actor.room.occupants, visible_to: actor }.merge( args.first.to_s.to_query )).first )
            target.output "You feel better!"
            target.regen( quantity, 0, 0 )
        elsif args.first.nil?
            actor.output "You feel better"
            actor.regen( quantity, 0, 0 )
        else
            actor.output "They aren't here."
        end
    end
    
end

class SpellHolyWord < Spell

    def initialize(game)
        super(
            game: game,
            name: "holy word",
            keywords: ["holy word"],
            lag: 0.5,
            position: Constants::Position::STAND,
            mana_cost: 25
        )
    end

    def attempt( actor, cmd, args, input, level )
        if args.first.nil?
            actor.output "A warm feeling runs through your body."
            actor.regen 100, 0, 0
            actor.apply_affect( AffectBless.new( source: nil, target: actor, level: actor.level, game: @game ) )
            actor.apply_affect( AffectFrenzy.new( source: nil, target: actor, level: actor.level, game: @game ) )
        elsif ( target = @game.target({ list: actor.items + actor.room.occupants - [actor] }.merge( args.first.to_s.to_query )).first )
            target.output "A warm feeling runs through your body."
            target.regen 100, 0, 0
            target.apply_affect( AffectBless.new( source: nil, target: target, level: actor.level, game: @game ) )
            target.apply_affect( AffectFrenzy.new( source: nil, target: target, level: actor.level, game: @game ) )
        else
            actor.output "There is no one here with that name."
        end
    end

end

class SpellHurricane < Spell

    def initialize(game)
        super(
            game: game,
            name: "hurricane",
            keywords: ["hurricane"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
        actor.broadcast "%s summons the power of a hurricane!", actor.room.occupants - [actor], [actor]
        actor.output "You summon a hurricane!"
    	( targets = actor.target({ not: actor, list: actor.room.occupants })).each do |target|
    		actor.deal_damage(target: target, damage: 100, noun:"hurricane", element: Constants::Element::DROWNING, type: Constants::Damage::MAGICAL)
    	end
        return true
    end
end

class SpellHypnosis < Spell

    def initialize(game)
        super(
            game: game,
            name: "hypnosis",
            keywords: ["hypnosis"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
        if ( target = actor.target({ list: actor.room.occupants, not: actor, visible_to: actor }.merge( args.shift.to_s.to_query ) ).first )
            actor.output "You hypnotize %s", [target]
            target.output "%s hypnotizes you to '#{args.join(" ")}'", [actor]
            target.do_command args.join(" ")
        else
            actor.output "Order whom to do what?"
        end
    end
end