require_relative 'affect.rb'

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
