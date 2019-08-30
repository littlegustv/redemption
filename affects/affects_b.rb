require_relative 'affect.rb'

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

class AffectBlind < Affect
    def start
        @target.output "You can't see a thing!"
    end

    def complete
        @target.output "You can see again."
    end
end
