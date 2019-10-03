require_relative 'affect.rb'

class AffectCharm < Affect

    def initialize(source:, target:, level:, game:)
        super(
            game: game,
            source: source,
            target: target,
            keywords: ["charm"],
            name: "charm",
            level:  level,
            duration: 60 * level,
            hidden: true,
            application_type: :global_single
        )
    end

    def send_start_messages
        @target.output "Isn't %s just so nice?", [@source]
        @source.output "%s looks at you with adoring eyes.", [@target]
    end

    def send_complete_messages
        @source.output "%s stops looking up to you", [@target] 
        @target.output "You feel more self-confident."
    end

    def start
        @target.add_event_listener(:event_order, self, :do_order)
    end

    def complete
        @target.delete_event_listener(:event_order, self)
    end

    def do_order( data )
        if data[:master] == @source
            @target.do_command data[:command]
        end
    end

end

class AffectCloakOfMind < Affect

    def initialize(source:, target:, level:, game:)
        super(
            game: game,
            source: nil,
            target: target,
            keywords: ["cloak of mind"],
            name: "cloak of mind",
            level:  level,
            duration: 60 * level,
            hidden: true,
            application_type: :global_single
        )
    end

    def send_start_messages
        @target.output "You cloak yourself from the wrath of mobiles."
        @target.broadcast "%s cloaks themselves from the wrath of mobiles.", @game.target({ list: @target.room.occupants, not: @target }), [@target]
    end

    def send_complete_messages
        @target.output "You are no longer hidden from mobiles."
        @target.broadcast "%s is no longer invisible to mobiles.", @game.target({ list: @target.room.occupants, not: @target }), [@target]
    end
end

class AffectCorrosive < Affect

    def initialize(source:, target:, level:, game:)
        super(
            game: game,
            source: source,
            target: target,
            keywords: ["corrosive"],
            name: "corrosive",
            modifiers: {ac_pierce: -10, ac_slash: -10, ac_bash: -10},
            level:  level,
            duration: 30,
            application_type: :global_stack
        )
    end

    def send_start_messages
        @target.broadcast "{g%s flesh burns away, revealing vital areas!{x", @game.target({ not: @target, list: @target.room.occupants }), [@target]
        @target.output "{gChunks of your flesh melt away, exposing vital areas!{x"
    end

    def send_refresh_messages
        @target.broadcast "{g%s flesh burns away, revealing vital areas!{x", @game.target({ not: @target, list: @target.room.occupants }), [@target]
        @target.output "{gChunks of your flesh melt away, exposing vital areas!{x"
    end

    def send_complete_messages
        @target.output "Your flesh begins to heal."
    end

end
