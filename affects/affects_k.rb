require_relative 'affect.rb'

class AffectKarma < Affect

    @@TEXTS = {
        str: "karma grows stronger!",
        dex: "karma moves faster!",
        con: "karma gets tougher!",
        int: "karma looks smarter!",
        wis: "karma grows more enlightened!",
        saves: "karma is now protected!",
        hitroll: "karma is more accurate!",
        damroll: "karma is more deadly!"
    }

    def initialize(source, target, level)
        super(
            source, # source
            target, # target
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

    def initialize(source, target, level)
        super(
            source, # source
            target, # target
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
        Game.instance.add_event_listener(@target, :event_calculate_long_auras, self, :do_long_killer_flag)
        Game.instance.add_event_listener(@target, :event_calculate_short_auras, self, :do_short_killer_flag)
    end

    def complete
        Game.instance.remove_event_listener(@target, :event_calculate_long_auras, self)
        Game.instance.remove_event_listener(@target, :event_calculate_short_auras, self)
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
