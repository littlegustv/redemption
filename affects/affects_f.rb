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
            # Visibility::NORMAL, # visibility
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
        (@target.room.occupants - [@target]).each_output "{r0<N> is blinded by smoke!{x", [@target]
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
            Visibility::NORMAL, # visibility
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
        @target.occupants.each_output "The rune of flames on this room vanishes."
    end

    def do_fire_rune(data)
    	if data[:mobile] == @source
    		@source.output "You sense the power of the room's rune and avoid it!"
    	elsif rand(0..100) < 50
    		data[:mobile].output "You are engulfed in flames as you enter the room!"
    		(@target.room.occupants - [data[:mobile]]).each_output "%N has been engulfed in flames!", [data[:mobile]]
            data[:mobile].receive_damage(@source, 100, :fireball)
	    else
	    	data[:mobile].output "You sense the power of the room's rune and avoid it!"
	    end
    end

    def fire_rune_description(data)
        data[:extra_show] += "\nA rune is on the floor, glowing a vibrant orange."
    end

end

class AffectFlamingWeapon < Affect

    def initialize(source, target, level)
        super(
            source, # source
            target, # target
            level, # level
            60, # duration
            nil, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            Visibility::NORMAL, # visibility
            true # savable
        )
        @data = {
            chance: 5
        }
    end

    def self.affect_info
        return @info || @info = {
            name: "flaming",
            keywords: ["flaming"],
            application_type: :global_single,
        }
    end

    def start
        Game.instance.add_event_listener(@target, :event_item_wear, self, :add_flag)
        Game.instance.add_event_listener(@target, :event_item_unwear, self, :remove_flag)
        if @target.equipped?
            Game.instance.add_event_listener(@target.carrier, :event_on_hit, self, :do_flag)
        end
    end

    def complete
        Game.instance.remove_event_listener(@target, :event_item_wear, self)
        Game.instance.remove_event_listener(@target, :event_item_unwear, self)
        if @target.equipped?
            Game.instance.remove_event_listener(@target.carrier, :event_on_hit, self)
        end
    end

    def add_flag(data)
        Game.instance.add_event_listener(@target.carrier, :event_override_hit, self, :do_flag)
    end

    def remove_flag(data)
        Game.instance.remove_event_listener(@target.carrier, :event_override_hit, self)
    end

    def do_flag(data)
        if data[:weapon] == @target && data[:target].active
            data[:target].output "0<N> burns your flesh!", [@target]
            (data[:target].room.occupants | data[:source].room.occupants).each_output "0<N> is burned by 1<n>'s 2<n>.", [data[:target], data[:source], @target]
            if dice(1, 100) <= @data[:chance]
                AffectFireBlind.new(data[:source], data[:target], @target.level).apply
            end
        end
    end

end

class AffectFloodingWeapon < Affect

    def initialize(source, target, level)
        super(
            source, # source
            target, # target
            level, # level
            60, # duration
            nil, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            Visibility::NORMAL, # visibility
            true # savable
        )
        @data = {
            chance: 5
        }
    end

    def self.affect_info
        return @info || @info = {
            name: "flooding",
            keywords: ["flooding"],
            application_type: :global_single,
        }
    end

    def start
        Game.instance.add_event_listener(@target, :event_item_wear, self, :add_flag)
        Game.instance.add_event_listener(@target, :event_item_unwear, self, :remove_flag)
        if @target.equipped?
            Game.instance.add_event_listener(@target.carrier, :event_on_hit, self, :do_flag)
        end
    end

    def complete
        Game.instance.remove_event_listener(@target, :event_item_wear, self)
        Game.instance.remove_event_listener(@target, :event_item_unwear, self)
        if @target.equipped?
            Game.instance.remove_event_listener(@target.carrier, :event_on_hit, self)
        end
    end

    def add_flag(data)
        Game.instance.add_event_listener(@target.carrier, :event_override_hit, self, :do_flag)
    end

    def remove_flag(data)
        Game.instance.remove_event_listener(@target.carrier, :event_override_hit, self)
    end

    def do_flag(data)
        if data[:weapon] == @target && data[:target].active
            data[:target].output "You are smothered in water from 0<n>.", [@target]
            (data[:target].room.occupants | data[:source].room.occupants).each_output "0<N> is smothered in water from 1<n>'s 2<n>.", [data[:target], data[:source], @target]
            if dice(1, 100) <= @data[:chance]
                AffectFlooded.new(data[:source], data[:target], @target.level).apply
            end
        end
    end

end

class AffectFlooded < Affect

    def initialize(source, target, level)
        super(
            source, # source
            target, # target
            level, # level
            30, # duration
            { attack_speed: -1, dex: -1 }, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            Visibility::NORMAL, # visibility
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
        @target.room.occupants.each_output "{b0<N> cough0<,s> and choke0<,s> on the water.{x", [@target]
    end

    def send_refresh_messages
        @target.room.occupants.each_output "{b0<N> cough0<,s> and choke0<,s> on the water.{x", [@target]
    end

    def send_complete_messages
        @target.output "The water clinging to you evaporates."
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
            Visibility::NORMAL, # visibility
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
        @target.room.occupants.each_output "0<N>'s feet rise off the ground.", [@target]
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
            Visibility::HIDDEN, # visibility
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
        @target.output "You now follow 0<n>.", [@source]
        @source.output "0<N> now follows you.", [@target]
    end

    def send_complete_messages
        @target.output "You stop following 0<n>.", [@source]
        @source.output "0<N> stops following you.", [@target]
    end

    def start
        Game.instance.add_event_listener(@target, :event_observe_mobile_exit, self, :do_follow)
    end

    def complete
        Game.instance.remove_event_listener(@target, :event_observe_mobile_exit, self)
    end

    def do_follow( data )
        if data[:mobile] == @source
            # p data[:direction]
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
                damroll: (level / 6).to_i,
                hitroll: (level / 6).to_i,
                ac_pierce: level + 9,
                ac_bash: level + 9,
                ac_slash: level + 9
            }, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            Visibility::NORMAL, # visibility
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
        (@target.room.occupants - [@target]).each_output("0<N> gets a wild look in their eyes!", @target)
        @target.output "You are filled with holy wrath!"
    end

    def complete
        @target.output "Your rage ebbs."
    end
end

class AffectFrostWeapon < Affect


        def initialize(source, target, level)
            super(
                source, # source
                target, # target
                level, # level
                60, # duration
                nil, # modifiers: nil
                nil, # period: nil
                false, # permanent: false
                Visibility::NORMAL, # visibility
                true # savable
            )
            @data = {
                chance: 5
            }
        end

        def self.affect_info
            return @info || @info = {
                name: "frost",
                keywords: ["frost"],
                application_type: :global_single,
            }
        end

        def start
            Game.instance.add_event_listener(@target, :event_item_wear, self, :add_flag)
            Game.instance.add_event_listener(@target, :event_item_unwear, self, :remove_flag)
            if @target.equipped?
                Game.instance.add_event_listener(@target.carrier, :event_on_hit, self, :do_flag)
            end
        end

        def complete
            Game.instance.remove_event_listener(@target, :event_item_wear, self)
            Game.instance.remove_event_listener(@target, :event_item_unwear, self)
            if @target.equipped?
                Game.instance.remove_event_listener(@target.carrier, :event_on_hit, self)
            end
        end

        def add_flag(data)
            Game.instance.add_event_listener(@target.carrier, :event_override_hit, self, :do_flag)
        end

        def remove_flag(data)
            Game.instance.remove_event_listener(@target.carrier, :event_override_hit, self)
        end

        def do_flag(data)
            if data[:weapon] == @target && data[:target].active
                data[:target].output "The cold touch of 0<n> surrounds you with ice.", [@target]
                (data[:target].room.occupants | data[:source].room.occupants).each_output "0<N> is frozen by 1<n>'s 2<n>.", [data[:target], data[:source], @target]
                if dice(1, 100) <= @data[:chance]
                    AffectChilled.new(data[:source], data[:target], @target.level).apply
                end
            end
        end

end
