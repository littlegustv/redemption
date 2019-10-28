require_relative 'affect.rb'

class AffectLair < Affect

    def initialize(source:, target:, level:, game:)
        super(
            game: game,
            source: source,
            target: target,
            keywords: ["lair"],
            name: "lair",
            level:  level,
            duration: 60 * level,
        )
    end

    def start
        @game.add_event_listener(@target, :event_try_where_room, self, :do_lair)
        @game.add_event_listener(@target, :event_calculate_room_description, self, :lair_description)
    end

    def complete
        @game.remove_event_listener(@target, :event_try_where_room, self)
        @game.remove_event_listener(@target, :event_calculate_room_description, self)
    end

    def lair_description(data)
        data[:extra_show] += "\nA dragon has set up their lair in this room."
    end

    def send_start_messages
        @source.output "Welcome to your new lair!"
        @game.broadcast "%s has claimed this room as their lair.", @target.occupants - [@source], [@source]
    end

    def send_complete_messages
        @game.broadcast "The dragon's lair vanishes as the sands of time claim it once again.", @target.occupants
    end

    def do_lair( data )
        data[:chance] *= 0
    end

end

class AffectLivingStone < Affect

    def initialize(source:, target:, level:, game:)
        super(
            game: game,
            source: source,
            target: target,
            keywords: ["living stone"],
            name: "living stone",
            level:  level,
            duration: 60,
            modifiers: { damroll: 20, hitroll: 20, attack_speed: 3, ac_pierce: -20, armor_slash: -20 }
        )
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
