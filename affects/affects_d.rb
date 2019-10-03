require_relative 'affect.rb'

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
        @target.add_event_listener(:event_on_die, self, :do_death_rune)        
    end

    def complete
        @target.delete_event_listener(:event_on_die, self)
    end

    def send_start_messages
        @target.output "You scribe a rune of death on your chest."
        @target.broadcast "%s is marked by a rune of death.", @game.target({ list: @target.room.occupants, not: @target }), [@target]
    end

    def send_refresh_messages
        @target.output "You refresh your rune of death."
    end

    def send_complete_messages
        @target.output "The rune of death on your chest vanishes."
    end

    def do_death_rune( data )
        @target.broadcast "A rune of death suddenly explodes!", @game.target({ list: @target.room.occupants })
        ( @level * 3 ).times do 
            @target.broadcast "A flaming meteor crashes into the ground nearby and explodes!", @game.target({ list: @target.room.area.occupants - @target.room.occupants })
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
end
