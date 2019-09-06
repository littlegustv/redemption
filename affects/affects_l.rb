require_relative 'affect.rb'

class AffectLivingStone < Affect
    def start
        @target.output "You are now affected by stone form."
    end

    def complete
        @target.output "Your flesh feels more supple."
    end
end