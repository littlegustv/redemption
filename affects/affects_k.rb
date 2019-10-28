require_relative 'affect.rb'

class AffectKarma < Affect

    def initialize(source:, target:, level:, game:)
        @texts = {
            str: "%s karma grows stronger!",
            dex: "%s karma moves faster!",
            con: "%s karma gets tougher!",
            int: "%s karma looks smarter!",
            wis: "%s karma grows more enlightened!",
            saves: "%s karma is now protected!",
            hitroll: "%s karma is more accurate!",
            damroll: "%s karma is more deadly!"
        }
        super(
            game: game,
            source: source,
            target: target,
            keywords: ["karma"],
            name: "karma",
            level: level,
            duration: level * 60,
        )        
        @mod = @texts.keys.sample
        overwrite_modifiers({ @mod => 5 })
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

    def initialize(source:, target:, level:, game:)
        super(
            game: game,
            source: source,
            target: target,
            keywords: ["killer"],
            name: "killer",
            level:  0,
            duration: 1,
            permanent: true,
            hidden: true
        )
    end

    def start
        @game.add_event_listener(@target, :event_calculate_aura_description, self, :do_killer_flag)
    end

    def complete
        @game.remove_event_listener(@target, :event_calculate_aura_description, self)
    end

    def do_killer_flag(data)
        data[:description] = "{R(KILLER){x " + data[:description]
    end

    def send_start_messages
        @target.output "*** You are now a KILLER!! ***"
    end
end
