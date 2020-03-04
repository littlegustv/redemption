require_relative 'affect.rb'

class AffectLair < Affect

    def initialize(source, target, level)
        super(
            source, # source
            target, # target
            level, # level
            level * 60, # duration
            nil, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            Constants::AffectVisibility::NORMAL, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "lair",
            keywords: ["lair"],
            application_type: :global_overwrite,
        }
    end

    def start
        Game.instance.add_event_listener(@target, :event_try_where_room, self, :do_lair)
        Game.instance.add_event_listener(@target, :event_calculate_room_description, self, :lair_description)
    end

    def complete
        Game.instance.remove_event_listener(@target, :event_try_where_room, self)
        Game.instance.remove_event_listener(@target, :event_calculate_room_description, self)
    end

    def lair_description(data)
        data[:extra_show] += "\nA dragon has set up their lair in this room."
    end

    def send_start_messages
        @source.output "Welcome to your new lair!"
        Game.instance.broadcast "%s has claimed this room as their lair.", @target.occupants - [@source], [@source]
    end

    def send_complete_messages
        Game.instance.broadcast "The dragon's lair vanishes as the sands of time claim it once again.", @target.occupants
    end

    def do_lair( data )
        data[:chance] *= 0
    end

end

class AffectLivingStone < Affect

    def initialize(source, target, level)
        super(
            source, # source
            target, # target
            level, # level
            60, # duration
            {
                damroll: 20,
                hitroll: 20,
                attack_speed: 3,
                ac_pierce: -20,
                armor_slash: -20
            }, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            Constants::AffectVisibility::NORMAL, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "living stone",
            keywords: ["living stone"],
            application_type: :global_overwrite,
        }
    end

    def send_start_messages
        @target.output "You are now affected by stone form."
        @target.broadcast("%s's flesh turns to stone.", @target.room.occupants - [@target], [@target] )
    end

    def send_complete_messages
        @target.output "Your flesh feels more supple."
        @target.broadcast("%s's flesh looks more supple.", @target.room.occupants - [@target], [@target] )
    end

end
