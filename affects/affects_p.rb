require_relative 'affect.rb'

class AffectPassDoor < Affect

    def initialize(source, target, level)
        super(
            source, # source
            target, # target
            level, # level
            9 + level, # duration
            nil, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            Visibility::NORMAL, # visibility
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

    def initialize(source, target, level)
        super(
            source, # source
            target, # target
            level, # level
            180, # duration
            { str: -1 }, # modifiers: nil
            10, # period: nil
            false, # permanent: false
            Visibility::NORMAL, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "plague",
            keywords: ["plague"],
            application_type: :source_stack,
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
        @target.receive_damage(nil, 10, :plague, true, true)
        (@target.room.occupants - [@target]).each do |occupant|
            # AffectPlague.new( nil, occupant, @level ).apply if rand(1...100) < 50
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

    def initialize(source, target, level)
        super(
            source, # source
            target, # target
            level, # level
            180, # duration
            { str: -1 }, # modifiers: nil
            10, # period: nil
            false, # permanent: false
            Visibility::NORMAL, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "poisoned",
            keywords: ["poisoned"],
            application_type: :source_stack,
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

    def initialize(source, target, level)
        super(
            source, # source
            target, # target
            level, # level
            60, # duration
            nil, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            Visibility::NORMAL, # visibility
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
            application_type: :global_single,
        }
    end

    def start
        Game.instance.add_event_listener(@target, :event_item_wear, self, :add_flag)
        Game.instance.add_event_listener(@target, :event_item_unwear, self, :remove_flag)
        if @target.equipped?
            Game.instance.add_event_listener(@target.carrier, :event_on_hit, self, :do_flag)
        end
    end

    def complete
        Game.instance.remove_event_listener(@target, :event_item_wear, self)
        Game.instance.remove_event_listener(@target, :event_item_unwear, self)
        if @target.equipped?
            Game.instance.remove_event_listener(@target.carrier, :event_on_hit, self)
        end
    end

    def add_flag(data)
        Game.instance.add_event_listener(@target.carrier, :event_on_hit, self, :do_flag)
    end

    def remove_flag(data)
        Game.instance.remove_event_listener(@target.carrier, :event_on_hit, self)
    end

    def do_flag(data)
        if data[:weapon] == @target && data[:target].active
            if dice(1, 100) <= @data[:chance]
                aff = AffectPoisoned.new(data[:source], data[:target], @target.level)
                aff.duration = 60
                aff.apply
            end
        end
    end
end

class AffectPortal < Affect

    def initialize( target, destination )
        super(
            nil, # source
            target, # target
            0, # level
            0, # duration
            nil, # modifiers: nil
            nil, # period: nil
            true, # permanent: false
            Visibility::NORMAL, # visibility
            true # savable
        )
        @destination = destination
    end

    def self.affect_info
        return @info || @info = {
            name: "portal",
            keywords: ["portal"],
            application_type: :global_single,
        }
    end

    def start
        Game.instance.add_event_listener(@target, :event_try_enter, self, :do_portal)
    end

    def complete
        Game.instance.remove_event_listener(@target, :event_try_enter, self)
    end

    def do_portal( data )
        data[:mobile].output "You enter 0<n>.", [@target]
        (@target.room.occupants - [@target]).each_output"0<N> steps into 1<n>.", [data[:mobile], @target]
        data[:mobile].move_to_room( @destination )
        (@target.room.occupants - [@target]).each_output "0<N> has arrived through 1<n>.", [data[:mobile], @target]
    end

end

class AffectProtectionEvil < Affect

    def initialize(source, target, level)
        super(
            source, # source
            target, # target
            level, # level
            600, # duration
            { saves: -1 }, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            Visibility::NORMAL, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "protection evil",
            keywords: ["protection evil", "protect"],
            application_type: :global_single,
        }
    end

    def start
        Game.instance.add_event_listener(@target, :event_calculate_receive_damage, self, :do_protection_evil)
    end

    def complete
        Game.instance.remove_event_listener(@target, :event_calculate_receive_damage, self)
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

    def initialize(source, target, level)
        super(
            source, # source
            target, # target
            level, # level
            600, # duration
            { saves: -1 }, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            Visibility::NORMAL, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "protection good",
            keywords: ["protection good", "protect"],
            application_type: :global_single,
        }
    end

    def start
        Game.instance.add_event_listener(@target, :event_calculate_receive_damage, self, :do_protection_good)
    end

    def complete
        Game.instance.remove_event_listener(@target, :event_calculate_receive_damage, self)
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

    def initialize(source, target, level)
        super(
            source, # source
            target, # target
            level, # level
            600, # duration
            { saves: -1 }, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            Visibility::NORMAL, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "protection neutral",
            keywords: ["protection neutral", "protect"],
            application_type: :global_single,
        }
    end

    def start
        Game.instance.add_event_listener(@target, :event_calculate_receive_damage, self, :do_protection_neutral)
    end

    def complete
        Game.instance.remove_event_listener(@target, :event_calculate_receive_damage, self)
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
