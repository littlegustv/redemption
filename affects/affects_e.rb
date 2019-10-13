require_relative 'affect.rb'

class AffectEnchantWeapon < Affect

    def initialize(source:, target:, level:, game:)
        super(
            game: game,
            source: source,
            target: target,
            keywords: ["enchant weapon"],
            name: "enchant weapon",
            level:  level,
            duration: 0,
            permanent: true,
            application_type: :global_stack
        )
    end

end

class AffectEssence < Affect

    def initialize(source:, target:, level:, game:)
        super(
            game: game,
            source: source,
            target: target,
            keywords: ["essence"],
            name: "essence",
            level:  level,
            duration: 0,
            permanent: true,
            application_type: :global_stack
        )
    end

end
