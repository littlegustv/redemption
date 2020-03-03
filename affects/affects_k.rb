require_relative 'affect.rb'

class AffectKarma < Affect

    @@TEXTS = {
        str: "%s karma grows stronger!",
        dex: "%s karma moves faster!",
        con: "%s karma gets tougher!",
        int: "%s karma looks smarter!",
        wis: "%s karma grows more enlightened!",
        saves: "%s karma is now protected!",
        hitroll: "%s karma is more accurate!",
        damroll: "%s karma is more deadly!"
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
            Constants::AffectVisibility::NORMAL, # visibility
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
        @target.output @texts[ @mod ], ["Your"]
        @target.broadcast @texts[ @mod ], @target.room.occupants - [@target], [@target]
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
            Constants::AffectVisibility::HIDDEN, # visibility
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
        Game.instance.add_event_listener(@target, :event_calculate_aura_description, self, :do_killer_flag)
    end

    def complete
        Game.instance.remove_event_listener(@target, :event_calculate_aura_description, self)
    end

    def do_killer_flag(data)
        data[:description] = "{R(KILLER){x " + data[:description]
    end

    def send_start_messages
        @target.output "*** You are now a KILLER!! ***"
    end
end
