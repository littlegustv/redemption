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
            Constants::AffectVisibility::NORMAL, # visibility
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
        @target.output "You turn translucent."
        @target.broadcast "%s turns translucent.", @target.room.occupants - [@target], [@target]
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
            Constants::AffectVisibility::NORMAL, # visibility
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
        @target.output "You scream in agony as plague sores erupt from your skin."
        @target.broadcast "%s screams in agony as plague sores erupt from their skin.", @target.room.occupants - [@target], [@target]
    end

    def send_refresh_messages
        @target.output "You scream in agony as plague sores erupt from your skin."
        @target.broadcast "%s screams in agony as plague sores erupt from their skin.", @target.room.occupants - [@target], [@target]
    end

    def periodic
        @target.broadcast "%s writhes in agony as plague sores erupt from their skin.", @target.room.occupants - [@target], [@target]
        @target.output "You writhe in agony from the plague."
        @target.receive_damage(source: nil, damage: 10, element: Constants::Element::DISEASE, type: Constants::Damage::MAGICAL, silent: true)
        (@target.room.occupants - [@target]).each do |occupant|
            occupant.apply_affect( AffectPlague.new( nil, occupant, @level ) ) if rand(1...100) < 50
        end
    end

    def send_complete_messages
        @target.output "You feel better!"
    end

    def summary
        super + "\n" + (" " * 24) + " : damage over time for #{ duration.to_i } seconds"
    end
end

class AffectPoison < Affect

    def initialize(source, target, level)
        super(
            source, # source
            target, # target
            level, # level
            180, # duration
            { str: -1 }, # modifiers: nil
            10, # period: nil
            false, # permanent: false
            Constants::AffectVisibility::NORMAL, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "poison",
            keywords: ["poison"],
            application_type: :source_stack,
        }
    end

    def send_start_messages
        @target.broadcast "{m%s looks very ill.{x", @target.room.occupants - [@target], [@target]
        # @target.output "{mYou feel poison coursing through your veins.{x"
        @target.output "You feel very sick."
    end

    def send_refresh_messages
        @target.broadcast "{m%s looks very ill.{x", @target.room.occupants - [@target], [@target]
        # @target.output "{mYou feel poison coursing through your veins.{x"
        @target.output "You feel very sick."
    end

    def periodic
        @target.output "You shiver and suffer."
        @target.broadcast("%s shivers and suffers.", @target.room.occupants - [@target], @target)
        @target.receive_damage(source: nil, damage: 10, element: Constants::Element::POISON, type: Constants::Damage::MAGICAL, silent: true)
    end

    def send_complete_messages
        @target.output "You feel better!"
    end

    def summary
        super + "\n" + (" " * 24) + " : damage over time for #{ duration.to_i } seconds"
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
            Constants::AffectVisibility::NORMAL, # visibility
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
        data[:mobile].output "You enter %s.", [@target]
        Game.instance.broadcast "%s steps into %s.", @target.room.occupants - [data[:mobile]], [data[:mobile], @target]
        data[:mobile].move_to_room( @destination )
        Game.instance.broadcast "%s has arrived through %s.", @destination.occupants - [data[:mobile]], [data[:mobile], @target]
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
            Constants::AffectVisibility::NORMAL, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "protection evil",
            keywords: ["protect_evil", "protection evil", "protect"],
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
        @target.broadcast "%s is protected from evil.", @target.room.occupants - [@target], [@target]
    end

    def send_complete_messages
        @target.output "You feel less protected."
    end

    def do_protection_evil( data )
        return if !data[:source]
        if data[:source].alignment > 333
            data[:damage] = ( data[:damage] * Constants::Damage::PROTECTION_MULTIPLIER ).to_i
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
            Constants::AffectVisibility::NORMAL, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "protection good",
            keywords: ["protect_good", "protection good", "protect"],
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
        @target.broadcast "%s is protected from good.", @target.room.occupants - [@target], [@target]
    end

    def send_complete_messages
        @target.output "You feel less protected."
    end

    def do_protection_good( data )
        return if !data[:source]
        if data[:source].alignment < -333
            data[:damage] = ( data[:damage] * Constants::Damage::PROTECTION_MULTIPLIER ).to_i
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
            Constants::AffectVisibility::NORMAL, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "protection neutral",
            keywords: ["protect_neutral", "protection neutral", "protect"],
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
        @target.broadcast "%s is protected from neutral.", @target.room.occupants - [@target], [@target]
    end

    def send_complete_messages
        @target.output "You feel less protected."
    end

    def do_protection_neutral( data )
        return if !data[:source]
        if data[:source].alignment <= 333 && data[:source].alignment >= -333
            data[:damage] = ( data[:damage] * Constants::Damage::PROTECTION_MULTIPLIER ).to_i
        end
    end

end
