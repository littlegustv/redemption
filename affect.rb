class Affect

    attr_accessor :name

    def initialize( target, keywords, duration, modifiers = {}, period = 60 )
        @target = target
        @keywords = keywords
        @period = period
        @name = @keywords.first
        @duration = duration
        @clock = 0
        @modifiers = modifiers
        start
    end

    def start
        @target.output "Affect has started: #{@duration} seconds remain."
    end

    def update( elapsed )
        @duration -= elapsed
        @clock += elapsed
        if @clock >= @period
            periodic
            @clock = 0
        end
        if @duration <= 0
            @target.affects.delete self
            complete
        end
    end

    def periodic        
    end

    def complete
        @target.output "Affect has worn off."
    end

    def check( key )
        @keywords.include?( key )
    end

    def modifier( key )
        return @modifiers[ key ].to_i
    end

    def summary
%Q(Spell: #{@name.ljust(17)} : #{ @modifiers.map{ |key, value| "modifies #{key} by #{value} for #{ duration } hours" }.join("\n" + (" " * 24) + " : ") } )
    end

    def duration
        @duration.to_i
    end

end

class AffectBlind < Affect
    def start
        @target.output "You can't see a thing!"
    end

    def complete
        @target.output "You can see again."
    end
end

class AffectHaste < Affect
    def start
        @target.output "You feel yourself moving more quickly."
    end

    def complete
        @target.output "You feel yourself slow down."
    end
end

class AffectBerserk < Affect
    def start
        @target.output "Your pulse races as you are consumed by rage!"
    end

    def periodic
        @target.regen 10
    end

    def complete
        @target.output "You feel yourself being less berzerky."
    end

    def summary
        super + "\n" + (" " * 24) + " : regenerating #{ ( 10 * @duration / @period ).floor } hitpoints"
    end
end

class AffectPoison < Affect
    def start
        @target.output "You feel very sick."
    end

    def periodic
        @target.output "You shiver and suffer."
        @target.damage 10, @target
    end

    def complete
        @target.output "You feel better!"
    end

    def summary
        super + "\n" + (" " * 24) + " : damage over time for #{ duration } hours"
    end
end