require_relative 'affect.rb'

class AffectFireBlind < AffectBlind

    def initialize(source, target, level)
        super(
            source, # source
            target, # target
            level, # level
            # 60, # duration
            # nil, # modifiers: nil
            # nil, # period: nil
            # false, # permanent: false
            # Constants::AffectVisibility::NORMAL, # visibility
            # true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "fireblind",
            keywords: ["fireblind", "blind"],
            application_type: :global_single,
        }
    end

    def send_start_messages
        @target.broadcast "{r%s is blinded by smoke!{x", @target.room.occupants - [@target], [@target]
        @target.output "{rYour eyes tear up from smoke...you can't see a thing!{x"
    end

    def send_complete_messages
        @target.output "The smoke leaves your eyes."
    end

end

class AffectFireRune < Affect

    def initialize(source, target, level)
        super(
            source, # source
            target, # target
            level, # level
            90 + level * 10, # duration
            nil, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            Constants::AffectVisibility::NORMAL, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "fire rune",
            keywords: ["fire rune", "rune"],
            application_type: :global_single,
        }
    end

    def start
        Game.instance.add_event_listener(@target, :event_calculate_room_description, self, :fire_rune_description)
        Game.instance.add_event_listener(@target, :event_room_mobile_enter, self, :do_fire_rune)
    end

    def complete
        Game.instance.remove_event_listener(@target, :event_calculate_room_description, self)
        Game.instance.remove_event_listener(@target, :event_room_mobile_enter, self)
    end

    def send_complete_messages
        @source.broadcast "The rune of flames on this room vanishes.", @target.occupants
    end

    def do_fire_rune(data)
    	if data[:mobile] == @source
    		@source.output "You sense the power of the room's rune and avoid it!"
    	elsif rand(0..100) < 50
    		data[:mobile].output "You are engulfed in flames as you enter the room!"
    		data[:mobile].broadcast "%s has been engulfed in flames!", @target.room.occupants - [data[:mobile]], [data[:mobile]]
            @source.deal_damage(target: data[:mobile], damage: 100, noun:"fireball", element: Constants::Element::FIRE, type: Constants::Damage::MAGICAL)
	    else
	    	data[:mobile].output "You sense the power of the room's rune and avoid it!"
	    end
    end

    def fire_rune_description(data)
        data[:extra_show] += "\nA rune is on the floor, glowing a vibrant orange."
    end

end

class AffectFlooding < Affect

    def initialize(source, target, level)
        super(
            source, # source
            target, # target
            level, # level
            30, # duration
            { attack_speed: -1, dex: -1 }, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            Constants::AffectVisibility::NORMAL, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "flooding",
            keywords: ["flooding", "slow"],
            application_type: :source_overwrite,
        }
    end

    def send_start_messages
        @target.broadcast "{b%s coughs and chokes on the water.{x", @target.room.occupants - [@target], [@target]
        @target.output "{bYou cough and choke on the water.{x"
    end

    def send_refresh_messages
        @target.broadcast "{b%s coughs and chokes on the water.{x", @target.room.occupants - [@target], [@target]
        @target.output "{bYou cough and choke on the water.{x"
    end

    def send_complete_messages
        @target.output "Your flesh begins to heal."
    end

end

class AffectFly < Affect

    def initialize(source, target, level)
        super(
            source, # source
            target, # target
            level, # level
            69 + level, # duration
            nil, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            Constants::AffectVisibility::NORMAL, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "flying",
            keywords: ["flying"],
            application_type: :global_overwrite,
        }
    end

    def send_start_messages
        @target.broadcast "%s's feet rise off the ground.", @target.room.occupants - [@target], [@target]
        @target.output "Your feet rise off the ground."
    end

    def send_complete_messages
        @target.output "You slowly float to the ground."
    end

end

class AffectFollow < Affect

    def initialize(source, target, level)
        super(
            source, # source
            target, # target
            level, # level
            0, # duration
            nil, # modifiers: nil
            nil, # period: nil
            true, # permanent: false
            Constants::AffectVisibility::HIDDEN, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "follow",
            keywords: ["follow"],
            application_type: :global_overwrite,
        }
    end

    def send_start_messages
        @target.output "You now follow %s", [@source]
        @source.output "%s now follows you", [@target]
    end

    def send_complete_messages
        @target.output "You stop following %s", [@source]
        @source.output "%s stops following you", [@target]
    end

    def start
        Game.instance.add_event_listener(@target, :event_observe_mobile_exit, self, :do_follow)
    end

    def complete
        Game.instance.remove_event_listener(@target, :event_observe_mobile_exit, self)
    end

    def do_follow( data )
        if data[:mobile] == @source
            p data[:direction]
            @target.do_command data[:direction]
        end
    end

end

class AffectFrenzy < Affect

    def initialize(source, target, level)
        super(
            source, # source
            target, # target
            level, # level
            90 + level * 10, # duration
            {
                damroll: (level / 10).to_i,
                hitroll: (level / 10).to_i,
                ac_pierce: level * 20,
                ac_bash: level * 20,
                ac_slash: level * 20
            }, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            Constants::AffectVisibility::NORMAL, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "frenzy",
            keywords: ["frenzy"],
            application_type: :global_single,
        }
    end

    def send_start_messages
        @target.broadcast("%s gets a wild look in their eyes!", @target.room.occupants - [@target], @target)
        @target.output "You are filled with holy wrath!"
    end

    def complete
        @target.output "Your rage ebbs."
    end
end

class AffectFrost < Affect

    def initialize(source, target, level)
        super(
            source, # source
            target, # target
            level, # level
            30, # duration
            { str: -2 }, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            Constants::AffectVisibility::NORMAL, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "frost",
            keywords: ["frost"],
            application_type: :global_stack,
        }
    end

    def send_start_messages
        @target.broadcast "{C%s turns blue and shivers.{x", @target.room.occupants - [@target], [@target]
        @target.output "{CA chill sinks deep into your bones.{x"
    end

    def send_refresh_messages
        @target.broadcast "{C%s turns blue and shivers.{x", @target.room.occupants - [@target], [@target]
        @target.output "{CA chill sinks deep into your bones.{x"
    end

    def send_complete_messages
        @target.output "You start to warm up."
    end

end
