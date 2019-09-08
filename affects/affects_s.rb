require_relative 'affect.rb'

class AffectSneak < Affect
    def start
        @target.output "You attempt to move silently."
    end

    def complete
        @target.output "You are now visible."
    end
end

class AffectSlow < Affect    
    def start
        @target.output "You find yourself moving more slowly."
    end

    def complete
        @target.output "You speed up."
    end
end

class AffectStun < Affect    
    def start
        @target.output "You are stunned but will probably recover."
    end

    def complete
        @target.output "You are no longer stunned."
    end
end