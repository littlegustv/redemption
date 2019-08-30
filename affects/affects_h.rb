require_relative 'affect.rb'

class AffectHaste < Affect
    def start
        @target.output "You feel yourself moving more quickly."
    end

    def complete
        @target.output "You feel yourself slow down."
    end
end
