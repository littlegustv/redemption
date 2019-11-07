require_relative 'affect.rb'

class AffectEnchantArmor < Affect

    def initialize(source, target, level, game)
        super(
            game: game,
            source: source,
            target: target,
            keywords: ["enchant armor"],
            name: "enchant armor",
            level:  level,
            duration: 0,
            permanent: true,
            application_type: :global_stack
        )
    end

end

class AffectEnchantWeapon < Affect

    def initialize(source, target, level, game)
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

    def initialize(source, target, level, game)
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
