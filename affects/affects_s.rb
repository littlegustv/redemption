require_relative 'affect.rb'

class AffectSneak < Affect
    def start
        @target.output "You attempt to move silently."
    end

    def complete
        @target.output "You are now visible."
    end
end