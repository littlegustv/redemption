require_relative 'affect.rb'

class AffectPassDoor < Affect

    def initialize(target, source = nil, level = 0)
        super(
            target, # target
            source, # source
            level, # level
            9 + level, # duration
            nil, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            :normal, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "pass door",
            keywords: ["pass door"],
            application_type: :global_single,
        }
    end

    def send_start_messages
        @target.room.occupants.each_output "0<N> turn0<,s> translucent.", [@target]
    end

    def send_complete_messages
        @target.output "You feel solid again."
    end

end

class AffectPlague < Affect

    def initialize(target, source = nil, level = 0)
        super(
            target, # target
            source, # source
            level, # level
            180, # duration
            { strength: -1 }, # modifiers: nil
            10, # period: nil
            false, # permanent: false
            :normal, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "plague",
            keywords: ["plague"],
            existing_affect_selection: :affect_id_with_source,
            application_type: :stack,
        }
    end

    def send_start_messages
        @target.room.occupants.each_output "0<N> scream0<,s> in agony as plague sores erupt from 0<p> skin.", [@target]
    end

    def send_refresh_messages
        @target.room.occupants.each_output "0<N> scream0<,s> in agony as plague sores erupt from 0<p> skin.", [@target]
    end

    def periodic
        (@target.room.occupants - [@target]).each_output "0<N> writhes in agony as plague sores erupt from their skin.", [@target]
        @target.output "You writhe in agony from the plague."
        occupants = @target.room.occupants - [target]
        @target.receive_damage(nil, 10, :plague, true, true)

        occupants.each do |occupant|
            AffectPlague.new( occupant, nil, @level ).apply if rand(1...100) < 50
        end
    end

    def send_complete_messages
        @target.output "You feel better!"
    end

    def summary
        super + "\n#{" " * 24} : damage over time for #{ duration.to_i } seconds"
    end
end

class AffectPoisoned < Affect

    def initialize(target, source = nil, level = 0)
        super(
            target, # target
            source, # source
            level, # level
            180, # duration
            { strength: -1 }, # modifiers: nil
            10, # period: nil
            false, # permanent: false
            :normal, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "poisoned",
            keywords: ["poisoned"],
            existing_affect_selection: :affect_id_with_source,
            application_type: :stack,
        }
    end

    def send_start_messages
        (@target.room.occupants - [@target]).each_output "{m0<N> looks very ill.{x", [@target]
        @target.output "You feel very sick."
    end

    def send_refresh_messages
        (@target.room.occupants - [@target]).each_output "{m0<N> looks very ill.{x", [@target]
        @target.output "You feel very sick."
    end

    def periodic
        @target.room.occupants.each_output("0<N> shiver0<,s> and suffer0<,s>.", @target)
        @target.receive_damage(@source, 10, :poison, true)
    end

    def send_complete_messages
        @target.output "You feel better!"
    end

    def summary
        super + "\n" + (" " * 24) + " : damage over time for #{ duration.to_i } seconds"
    end
end

class AffectPoisonWeapon < Affect

    def initialize(target, source = nil, level = 0)
        super(
            target, # target
            source, # source
            level, # level
            60, # duration
            nil, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            :normal, # visibility
            true # savable
        )
        @data = {
            chance: 5
        }
    end

    def self.affect_info
        return @info || @info = {
            name: "poisonous",
            keywords: ["poisonous"],
            existing_affect_selection: :affect_id,
            application_type: :multiple,
        }
    end

    def start
        add_event_listener(@target, :on_hit, :do_flag)
    end

    def do_flag(data)
        if data[:target].active
            if dice(1, 100) <= @data[:chance]
                aff = AffectPoisoned.new(data[:target], data[:source], @target.level)
                aff.set_duration(60)
                aff.apply
            end
        end
    end
end

class AffectProtectionEvil < Affect

    def initialize(target, source = nil, level = 0)
        super(
            target, # target
            source, # source
            level, # level
            600, # duration
            { saves: -1 }, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            :normal, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "protection evil",
            keywords: ["protection evil", "protect"],
            existing_affect_selection: :keywords,
            application_type: :overwrite,
        }
    end

    def start
        add_event_listener(@target, :calculate_receive_damage, :do_protection_evil)
    end

    def send_start_messages
        @target.output "You feel holy and pure."
        (@target.room.occupants - [@target]).each_output "0<N> is protected from evil.", [@target]
    end

    def send_complete_messages
        @target.output "You feel less protected."
    end

    def do_protection_evil( data )
        return if !data[:source]
        if data[:source].alignment > 333
            data[:damage] = ( data[:damage] * 0.9 ).to_i
        end
    end

end

class AffectProtectionGood < Affect

    def initialize(target, source = nil, level = 0)
        super(
            target, # target
            source, # source
            level, # level
            600, # duration
            { saves: -1 }, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            :normal, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "protection good",
            keywords: ["protection good", "protect"],
            existing_affect_selection: :keywords,
            application_type: :overwrite,
        }
    end

    def start
        add_event_listener(@target, :calculate_receive_damage, :do_protection_good)
    end

    def send_start_messages
        @target.output "You feel aligned with darkness."
        (@target.room.occupants - [@target]).each_output "0<N> is protected from good.", [@target]
    end

    def send_complete_messages
        @target.output "You feel less protected."
    end

    def do_protection_good( data )
        return if !data[:source]
        if data[:source].alignment < -333
            data[:damage] = ( data[:damage] * 0.9 ).to_i
        end
    end

end

class AffectProtectionNeutral < Affect

    def initialize(target, source = nil, level = 0)
        super(
            target, # target
            source, # source
            level, # level
            600, # duration
            { saves: -1 }, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            :normal, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "protection neutral",
            keywords: ["protection neutral", "protect"],
            existing_affect_selection: :keywords,
            application_type: :overwrite,
        }
    end

    def start
        add_event_listener(@target, :calculate_receive_damage, :do_protection_neutral)
    end

    def send_start_messages
        @target.output "You feel aligned with twilight."
        (@target.room.occupants - [@target]).each_output "0<N> is protected from neutral.", [@target]
    end

    def send_complete_messages
        @target.output "You feel less protected."
    end

    def do_protection_neutral( data )
        return if !data[:source]
        if data[:source].alignment <= 333 && data[:source].alignment >= -333
            data[:damage] = ( data[:damage] * 0.9 ).to_i
        end
    end

end
