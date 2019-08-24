class Affect

    attr_accessor :name

    def initialize( target, keywords, duration, modifiers = {} )
        @target = target
        @keywords = keywords
        @name = @keywords.first
        @duration = duration
        @modifiers = modifiers
        start
    end

    def start
        @target.output "Affect has started: #{@duration} seconds remain."
    end

    def update( elapsed )
        @duration -= elapsed
        if @duration <= 0
            @target.affects.delete self
            complete
        end
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
%Q(Spell: #{@name.ljust(17)} : #{ @modifiers.map{ |key, value| "modifies #{key} by #{value} for #{@duration.to_i} hours" }.join("\n" + (" " * 24) + " : ") } )
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

    def complete
        @target.output "You feel yourself being less berzerky."
    end
end