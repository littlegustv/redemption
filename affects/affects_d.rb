require_relative 'affect.rb'

# this is NORMAL darkness, for the room affect, not the super-dark that black dragons get

class AffectDark < Affect

    def initialize(source:, target:, level:, game:)
        super(
            game: game,
            source: source,
            target: target,
            keywords: ["dark"],
            name: "dark",
            level:  level,
            duration: 60,
        )
    end

    def start
        @game.add_event_listener(@target, :event_try_can_see_room, self, :do_dark)
    end

    def complete
        @game.remove_event_listener(@target, :event_try_can_see_room, self)
    end

    def do_dark( data )
        if !@target.affected?("indoors") && @game.daytime?  # a dark room in daytime is lit by the sun (if it is outside)
            # nothing
        elsif !data[:observer].equipped("light").empty?     # a dark room is lit by an equipped light
            # nothing
        elsif data[:target].affected? "glowing"             # a glowing item is visible even in darkness
            # nothing
        elsif data[:observer].affected?("infravision") && ["Mobile", "Player"].include?(data[:target].class.to_s)
            # nothing
        else
            data[:chance] *= 0
        end
        # log "#{data[:observer].affected?("infravision") && ["Mobile", "Player"].include?(data[:target].class.to_s)}"
    end

end

class AffectDeathRune < Affect

    def initialize(source:, target:, level:, game:)
        super(
            game: game,
            source: source,
            target: target,
            keywords: ["death rune"],
            name: "death rune",
            level:  level,
            duration: level.to_i * 60,
            modifiers: { none: 0 }
        )
    end

    def start
        @game.add_event_listener(@target, :event_on_die, self, :do_death_rune)
    end

    def complete
        @game.remove_event_listener(@target, :event_on_die, self)
    end

    def send_start_messages
        @target.output "You scribe a rune of death on your chest."
        @target.broadcast "%s is marked by a rune of death.", @target.room.occupants - [@target], [@target]
    end

    def send_refresh_messages
        @target.output "You refresh your rune of death."
    end

    def send_complete_messages
        @target.output "The rune of death on your chest vanishes."
    end

    def do_death_rune( data )
        @target.broadcast "A rune of death suddenly explodes!", @target.room.occupants
        ( @level * 3 ).times do
            @target.broadcast "A flaming meteor crashes into the ground nearby and explodes!", @target.room.area.occupants - @target.room.occupants
            ( @target.room.occupants - [@target] ).each do |victim|
                @target.deal_damage(target: victim, damage: 100, noun:"meteor's impact", element: Constants::Element::ENERGY, type: Constants::Damage::MAGICAL)
            end
        end
    end

end

class AffectDetectInvisibility < Affect

    def initialize(source:, target:, level:, game:)
        super(
            game: game,
            source: source,
            target: target,
            keywords: ["detect invisibility"],
            name: "detect invisibility",
            level:  level,
            duration: level.to_i * 60,
            modifiers: { none: 0 }
        )
    end

    def send_start_messages
        @target.output "Your eyes tingle."
    end

    def send_complete_messages
        @target.output "You can no longer detect invisibility."
    end

    def start
        @game.add_event_listener(@target, :event_try_detect_invis, self, :do_detect_invis)
    end

    def complete
        @game.remove_event_listener(@target, :event_try_detect_invis, self)
    end

    def do_detect_invis(data)
        data[:success] = true
    end
end
