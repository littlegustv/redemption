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

    def hook
        @target.add_event_listener(:event_override_hit, self, :do_mirror_image)
    end

    def unhook
        @target.delete_event_listener(:event_override_hit, self)
    end

    def complete
    end

    def start
    	@source.output "You create a mirror image of yourself."
    	@source.broadcast "%s creates a mirror image.", @source.target( room: @source.room, not: @source ), [@source]
    end

    def do_mirror_image(data)
        if data[:confirm] == false && @source == data[:target]
	        @health -= 1
	        if @health <= 0
	        	@source.output "Your mirror image shatters to pieces!", [data[:source]]
	        	@source.broadcast "%s's mirror image shatters to pieces!", @source.target( room: @source.room, not: @source ), [ @source ]
	        	@source.remove_affect("mirror image")
	        else
	        	@source.output "Your mirror image takes %s's hit!", [data[:source]]
	        	@source.broadcast "%s's mirror image absorbs the shock.", @source.target( room: @source.room, not: @source ), [ @source ]	        	
	        end
	        data[:confirm] = true
	    end
    end

end
