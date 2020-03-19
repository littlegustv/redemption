require_relative 'spell.rb'

class Formula

    def initialize(definition)
        @definition = definition.gsub(/\s+/, "")
    end

    def formula_for_player(player)
        player_formula = @definition
        player_formula.gsub!("level", player.level.to_s)
        return player_formula
    end

    def evaluate(player)
        return calculate(formula_for_player(player)).to_i
    end

    def calculate(substr)
        last_substr = ""
        number = 0
        loop do
            last_substr = substr
            substr.scan(/(\(([^()]*)\))/).each do |bracket, content|
                substr.sub!(bracket, calculate(content))
            end
            substr.scan(/((-?\d+)d(-?\d+))/).each do |dice_str, count, sides|
                substr.sub!(dice_str, dice(count.to_i, sides.to_i).to_s)
            end
            substr.scan(/((-?\d+)\*(-?\d+))/).each do |multiplication, a, b|
                substr.sub!(multiplication, (a.to_i * b.to_i).to_s)
            end
            substr.scan(/((-?\d+)\/(-?\d+))/).each do |division, dividend, divisor|
                substr.sub!(division, (dividend.to_i / divisor.to_i).to_i.to_s)
            end
            substr.scan(/((-?\d+)\+(-?\d+))/).each do |addition, a, b|
                substr.sub!(addition, (a.to_i + b.to_i).to_s)
            end
            substr.scan(/((-?\d+)-(-?\d+))/).each do |subtraction, a, b|
                substr.sub!(subtraction, (a.to_i - b.to_i).to_s)
            end
            break if last_substr == substr
        end
        return substr
    end

end

class SpellAcidBlast < Spell

    def initialize
        super(
            name: "acid blast",
            keywords: ["acid", "blast", "acid blast"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 10
        )
        @damage_formula = Formula.new("(1+level/8)d(10+level/25)+15")
    end

    def cast( actor, cmd, args, input )
    	if args.first.nil? && actor.attacking.nil?
    		actor.output "Cast the spell on who, now?"
            return
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
        damage = @damage_formula.evaluate(actor)
        actor.deal_damage(target: target, damage: damage, noun:"acid blast", element: Constants::Element::ACID, type: Constants::Damage::MAGICAL)
        return true
    end
end

class SpellAlarmRune < Spell

    def initialize
        super(
            name: "alarm rune",
            keywords: ["alarm rune"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
        data = {success: true}
        Game.instance.fire_event(actor, :event_try_alarm_rune, data)
        if !data[:success]
            actor.output "You already sense others."
            return false
        elsif actor.room.affected? "alarm rune"
            actor.output "This room is already being sensed."
            return false
        else
            actor.output "You place an alarm rune on the ground, increasing your senses."
            (actor.room.occupants - [actor]).each_output "0<N> places a strange rune on the ground.", [actor]
            actor.room.apply_affect( AffectAlarmRune.new( actor, actor.room, actor.level ) )
            return true
        end
    end
end

class SpellArmor < Spell


    def initialize
        super(
            name: "armor",
            keywords: ["armor"],
            lag: 0.25,
            position: Constants::Position::STAND,
            mana_cost: 10
        )
    end

    def attempt( actor, cmd, args, input, level )
        actor.apply_affect( AffectArmor.new( nil, actor, actor.level ) )
    end

end
