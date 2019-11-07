require_relative 'affect.rb'

class AffectAggressive < Affect

    def initialize(source, target, level, game)
        super(
            game, # game
            source, # source
            target, # target
            0, # level
            0, # duration
            nil, # modifiers
            2, # period
            true, # permanent
            Constants::AffectVisibility::HIDDEN, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "aggressive",
            keywords: ["aggressive"],
            application_type: :global_overwrite,
        }
    end

    # def start
    #     @game.add_event_listener(@target, :event_observe_mobile_enter, self, :do_aggro)
    # end
    #
    # def complete
    #     @game.remove_event_listener(@target, :event_observe_mobile_enter, self)
    # end
    #
    # def do_aggro(data)
    #     if @target.can_see?(data[:mobile]) && !data[:mobile].affected?("cloak of mind")
    #         @game.broadcast "%s screams and attacks!!", @target.room.occupants - [@target], [@target]
    #         @target.start_combat data[:mobile]
    #         @target.do_round_of_attacks(target: data[:mobile])
    #     end
    # end

    def periodic
        players = @target.room.players
        if players.empty?
            return
        end
        player = players.select{ |t| @target.can_see?(t) }.shuffle!.first
        if player && !@target.attacking
            @game.broadcast "%s screams and attacks!!", @target.room.occupants - [@target], [@target]
            @target.start_combat player
            @target.do_round_of_attacks(target: player)
        end
    end

end

class AffectAlarmRune < Affect

    def initialize(source, target, level, game)
        super(
            game, # game
            source, # source
            target, # target
            level, # level
            120, # duration
            nil, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            Constants::AffectVisibility::NORMAL, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "alarm rune",
            keywords: ["alarm rune", "rune"],
            application_type: :source_overwrite,
        }
    end

    def start
        @game.add_event_listener(@target, :event_calculate_room_description, self, :alarm_rune_description)
        @game.add_event_listener(@target, :event_room_mobile_enter, self, :do_alarm_rune)
        @game.add_event_listener(@source, :event_try_alarm_rune, self, :stop_alarm_rune)
    end

    def complete
        @game.remove_event_listener(@target, :event_calculate_room_description, self)
        @game.remove_event_listener(@target, :event_room_mobile_enter, self)
        @game.remove_event_listener(@source, :event_try_alarm_rune, self)
    end

    def send_complete_messages
    	@source.output "Your connection with the alarm rune is broken."
    	@source.broadcast "The rune of warding on this room vanishes.", @target.occupants
    end

    def do_alarm_rune(data)
    	if data[:mobile] == @source
    		@source.output "You sense the power of the room's rune and avoid it!"
    	else
    		@source.output "{R%s has triggered your alarm rune!{x", [data[:mobile]]
	    end
    end

    def stop_alarm_rune(data)
        data[:success] = false
    end

    def alarm_rune_description(data)
        data[:extra_show] += "\nA rune is on the floor, glowing softly."
    end

end

class AffectArmor < Affect

    def initialize(source, target, level, game)
        super(
            game, # game
            source, # source
            target, # target
            level, # level
            300, # duration
            { ac_pierce: 10, ac_slash: 10, ac_bash: 10, ac_magic: 10 }, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            Constants::AffectVisibility::NORMAL, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "armor",
            keywords: ["armor"],
            application_type: :source_overwrite,
        }
    end

    def send_start_messages
        @target.output "You feel someone protecting you."
    end

    def send_complete_messages
        @target.output "You feel less armored."
    end

end
