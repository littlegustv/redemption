require_relative 'affect.rb'

class AffectMinimation < Affect

    def initialize(source, target, level)
        super(
            source, # source
            target, # target
            level, # level
            level * 60, # duration
            {
                damroll: 20,
                hitroll: 20,
                attack_speed: 3,
                ac_pierce: -20,
                armor_slash: -20
            }, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            Visibility::NORMAL, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "minimation",
            keywords: ["minimation", "grandeurminimation"],
            application_type: :global_single,
        }
    end

    def start
        Game.instance.add_event_listener(@target, :event_show_condition, self, :do_condition)
    end

    def complete
        Game.instance.remove_event_listener(@target, :event_show_condition, self)
    end

    def send_start_messages
        @target.output "You now appear invincible!"
        (@target.room.occupants - [@target]).each_output "0<N> suddenly looks alot tougher.", [@target]
    end

    def send_complete_messages
        @target.output "You appear pretty strong to others."
        (@target.room.occupants - [@target]).each_output "0<N> does not look so tough.", [ @target ]
    end

    def do_condition(data)
        data[:percent] = 100
    end
end

class AffectMirrorImage < Affect

    def initialize(source, target, level)
        super(
            source, # source
            target, # target
            level, # level
            120, # duration
            nil, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            Visibility::NORMAL, # visibility
            true # savable
        )
        @health = 5
    end

    def self.affect_info
        return @info || @info = {
            name: "mirror image",
            keywords: ["mirror image"],
            application_type: :global_single,
        }
    end

    def start
        Game.instance.add_event_listener(@target, :event_override_receive_hit, self, :do_mirror_image)
    end

    def complete
        Game.instance.remove_event_listener(@target, :event_override_receive_hit, self)
    end

    def send_start_messages
    	@target.room.occupants.each_output "0<N> create0<,s> a mirror image of 0<r>.", [@target, @target]
    end

    def send_complete_messages
    	@target.room.occupants.each_output "0<N>'s mirror image shatters to pieces!", [@target, @target]
    end

    def do_mirror_image(data)
        if data[:confirm] == false && @source == data[:target]
	        @health -= 1
	        if @health <= 0
	        	clear
	        else
	        	@target.room.occupants.each_output "0<N>'s mirror image takes 0<n>'s hit!", [@target, data[:source]]
	        end
	        data[:confirm] = true
	    end
    end

end
