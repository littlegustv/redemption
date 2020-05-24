require_relative 'affect.rb'

class AffectKarma < Affect

    @@TEXTS = {
        strength: "karma grows stronger!",
        dexterity: "karma moves faster!",
        constitution: "karma gets tougher!",
        intelligence: "karma looks smarter!",
        wisdom: "karma grows more enlightened!",
        saves: "karma is now protected!",
        hit_roll: "karma is more accurate!",
        damage_roll: "karma is more deadly!"
    }

    def initialize(target, source = nil, level = 0)
        super(
            target, # target
            source, # source
            level, # level
            level * 60, # duration
            nil, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            Visibility::NORMAL, # visibility
            true # savable
        )
        @mod = @@TEXTS.keys.sample
        overwrite_modifiers({ @mod => 5 })
    end

    def self.affect_info
        return @info || @info = {
            name: "karma",
            keywords: ["karma"],
            application_type: :global_overwrite,
        }
    end

    def send_start_messages
        @target.room.occupants.each_output "0<N>'s #{@@TEXTS[ @mod ]}", [@target]
    end

    def send_complete_messages
        @target.output "Your karma is no longer altered."
    end

end


class AffectKiller < Affect

    def initialize(target, source = nil, level = 0)
        super(
            target, # target
            source, # source
            level, # level
            1, # duration
            nil, # modifiers: nil
            nil, # period: nil
            true, # permanent: false
            Visibility::HIDDEN, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "killer",
            keywords: ["killer"],
            application_type: :global_overwrite,
        }
    end

    def start
        add_event_listener(@target, :event_calculate_long_auras, :do_long_killer_flag)
        add_event_listener(@target, :event_calculate_short_auras, :do_short_killer_flag)
    end

    def do_long_killer_flag(data)
        data[:description] = "{R(KILLER){x " + data[:description]
    end

    def do_short_killer_flag(data)
        data[:description] = "{R(K){x " + data[:description]
    end

    def send_start_messages
        @target.output "*** You are now a KILLER!! ***"
    end
end
