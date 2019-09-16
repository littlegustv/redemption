require_relative 'affect.rb'

class AffectBerserk < Affect

    def initialize(source:, target:, level:)
        super(
            source: source,
            target: target,
            keywords: ["berserk"],
            name: "berserk",
            level:  level,
            duration: 60,
            modifiers: {damroll: (level / 10).to_i, hitroll: (level / 10).to_i},
            period: 1
        )
    end

    def start
        @target.output "Your pulse races as you are consumed by rage!"
    end

    def periodic
        @target.regen 10
    end

    def complete
        @target.output "You feel yourself being less berzerky."
    end

    def summary
        super + "\n" + (" " * 24) + " : regenerating #{ ( 10 * @duration / @period ).floor } hitpoints"
    end
end

class AffectBlind < Affect

    def initialize(source:, target:, level:)
        super(
            source: source,
            target: target,
            keywords: ["blind"],
            name: "blind",
            level:  level,
            duration: 30,
            modifiers: {hitroll: -5}
        )
    end

    def hook
        @target.add_event_listener(:event_try_can_see, self, :do_blindness)
    end

    def unhook
        @target.delete_event_listener(:event_try_can_see, self)
    end

    def start
        @target.output "You can't see a thing!"
    end

    def complete
        @target.output "You can see again."
    end

    def do_blindness(data)
        data[:chance] *= 0
    end

end
