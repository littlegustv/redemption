require_relative 'affect.rb'

class AffectEnchantArmor < Affect

    def initialize(target, source = nil, level = 0)
        super(
            target, # target
            source, # source
            level, # level
            0, # duration
            nil, # modifiers: nil
            nil, # period: nil
            true, # permanent: false
            :normal, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "enchant armor",
            keywords: ["enchant armor"],
            existing_affect_selection: :affect_id,
            application_type: :stack,
        }
    end

end

class AffectEnchantWeapon < Affect

    def initialize(target, source = nil, level = 0)
        super(
            target, # target
            source, # source
            level, # level
            0, # duration
            nil, # modifiers: nil
            nil, # period: nil
            true, # permanent: false
            :normal, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "enchant weapon",
            keywords: ["enchant weapon"],
            existing_affect_selection: :affect_id,
            application_type: :stack,
        }
    end

end

class AffectEssence < Affect

    def initialize(target, source = nil, level = 0)
        super(
            target, # target
            source, # source
            level, # level
            0, # duration
            nil, # modifiers: nil
            nil, # period: nil
            true, # permanent: false
            :passive, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "essence",
            keywords: ["essence"],
            existing_affect_selection: :affect_id,
            application_type: :overwrite,
        }
    end

    def start
        add_event_listener(@target, :on_deal_magic_damage, :do_essence)
    end

    def do_essence( data )
        if data[:target] == @target
            # can't essence yourself (?)
            return
        end
        affect_classes = {
                :acid => AffectCorroded,
                :cold => AffectChilled,
                :drowning => AffectFlooded,
                :fire => AffectFireBlind,
                :lightning => AffectShocked,
                :poison => AffectPoisoned,
            }
        e = data[:noun].element.symbol
        chance = 5 + (data[:damage] / 8).to_i
        if affect_classes.dig(e) && dice(1, 100) <= chance
            affect_classes[e].new(@target, data[:target], @target.level).apply
        end
    end

end
