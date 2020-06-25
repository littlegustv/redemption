require_relative 'affect.rb'

class AffectLair < Affect

    def initialize(target, source = nil, level = 0)
        super(
            target, # target
            source, # source
            level, # level
            level * 60, # duration
            nil, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            :normal, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "lair",
            keywords: ["lair"],
            existing_affect_selection: :affect_id,
            application_type: :overwrite,
        }
    end

    def start
        add_event_listener(@target, :try_where_room, :do_lair)
        add_event_listener(@target, :calculate_room_description, :lair_description)
    end

    def lair_description(data)
        data[:extra_show] += "\nA dragon has set up their lair in this room."
    end

    def send_start_messages
        @source.output "Welcome to your new lair!"
        (@target.occupants - [@source]).each_output "0<N> has claimed this room as their lair.", [@source]
    end

    def send_complete_messages
        @target.occupants.each_output "The dragon's lair vanishes as the sands of time claim it once again."
    end

    def do_lair( data )
        data[:chance] *= 0
    end

end

class AffectLivingStone < Affect

    def initialize(target, source = nil, level = 0)
        super(
            target, # target
            source, # source
            level, # level
            60, # duration
            {
                damage_roll: 20,
                hit_roll: 20,
                attack_speed: 3,
                armor_class: -20
            }, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            :normal, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "living stone",
            keywords: ["living stone"],
            existing_affect_selection: :affect_id,
            application_type: :overwrite,
        }
    end

    def send_start_messages
        @target.output "You are now affected by stone form."
        (@target.room.occupants - [@target]).each_output("0<N>'s flesh turns to stone.", [@target] )
    end

    def send_complete_messages
        @target.output "Your flesh feels more supple."
        (@target.room.occupants - [@target]).each_output("0<N>'s flesh looks more supple.", [@target] )
    end

end
