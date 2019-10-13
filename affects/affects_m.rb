require_relative 'affect.rb'

class AffectMirrorImage < Affect

    def initialize(source:, target:, level:, game:)
        super(
            game: game,
            source: source,
            target: target,
            keywords: ["mirror image"],
            name: "mirror image",
            level:  level,
            duration: 120,
            application_type: :global_single
        )
        @health = 5
    end

    def start
        @game.add_event_listener(@target, :event_override_receive_hit, self, :do_mirror_image)
    end

    def complete
        @game.remove_event_listener(@target, :event_override_receive_hit, self)
    end

    def send_start_messages
    	@target.output "You create a mirror image of yourself."
    	@target.broadcast "%s creates a mirror image.", @target.room.occupants - [@target], [@target]
    end

    def send_complete_messages
        @target.output "Your mirror image shatters to pieces!", [data[:source]]
        @target.broadcast "%s's mirror image shatters to pieces!", @target.room.occupants - [@target], [ @target ]
    end

    def do_mirror_image(data)
        if data[:confirm] == false && @source == data[:target]
	        @health -= 1
	        if @health <= 0
	        	clear
	        else
	        	@target.output "Your mirror image takes %s's hit!", [data[:source]]
	        	@target.broadcast "%s's mirror image absorbs the shock.", @target.room.occupants - [@target], [ @target ]
	        end
	        data[:confirm] = true
	    end
    end

end
