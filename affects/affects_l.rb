require_relative 'affect.rb'

class AffectLivingStone < Affect
    def start
        @target.add_event_listener(:event_on_hit, self, :test)
        @target.output "You are now affected by stone form."
    end

    def complete
        @target.delete_event_listener(:event_on_hit, self)
        @target.output "Your flesh feels more supple."
    end

    def test(data)
        @target.output "Event!"
    end
end
