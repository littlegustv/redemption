require_relative 'affect.rb'

class AffectCalm < Affect

    def initialize(source, target, level)
        super(
            source, # source
            target, # target
            level, # level
            60, # duration
            { hitroll: -5, damroll: -5 }, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            Constants::AffectVisibility::NORMAL, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "calm",
            keywords: ["calm"],
            application_type: :global_single,
        }
    end

    def send_complete_messages
        @target.output "You have lost your peace of mind."
    end

end

class AffectCharm < Affect

    def initialize(source, target, level)
        super(
            source, # source
            target, # target
            level, # level
            210 + level * 10, # duration
            nil, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            Constants::AffectVisibility::NORMAL, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "charm",
            keywords: ["charm"],
            application_type: :global_single,
        }
    end

    def send_start_messages
        @target.output "Isn't 0<n> just so nice?", [@source]
        @source.output "0<N> looks at you with adoring eyes.", [@target]
    end

    def send_complete_messages
        @source.output "0<N> stops looking up to you.", [@target]
        @target.output "You feel more self-confident."
    end

    def start
        Game.instance.add_event_listener(@source, :event_order, self, :do_order)
    end

    def complete
        Game.instance.remove_event_listener(@source, :event_order, self)
    end

    def do_order( data )
        @target.do_command data[:command]
    end

end

class AffectChilled < Affect

    def initialize(source, target, level)
        super(
            source, # source
            target, # target
            level, # level
            30, # duration
            { str: -2 }, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            Constants::AffectVisibility::NORMAL, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "chilled",
            keywords: ["chilled"],
            application_type: :global_stack,
        }
    end

    def send_start_messages
        (@target.room.occupants - [@target]).each_output "{C0<N> turns blue and shivers.{x", [@target]
        @target.output "{CA chill sinks deep into your bones.{x"
    end

    def send_refresh_messages
        (@target.room.occupants - [@target]).each_output "{C0<N> turns blue and shivers.{x", [@target]
        @target.output "{CA chill sinks deep into your bones.{x"
    end

    def send_complete_messages
        @target.output "You start to warm up."
    end

end

class AffectCloakOfMind < Affect

    def initialize(source, target, level)
        super(
            source, # source
            target, # target
            level, # level
            27 * level * 3, # duration
            nil, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            Constants::AffectVisibility::NORMAL, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "cloak of mind",
            keywords: ["cloak of mind"],
            application_type: :global_single,
        }
    end

    def start
        Game.instance.add_event_listener(@target, :event_try_can_be_seen, self, :do_cloak_of_mind)
        Game.instance.add_event_listener(@target, :event_on_start_combat, self, :clear)
    end

    def complete
        Game.instance.remove_event_listener(@target, :event_try_can_be_seen, self)
        Game.instance.remove_event_listener(@target, :event_on_start_combat, self)
    end

    def do_cloak_of_mind(data)
        if !data[:observer].is_player?
            detect_data = { success: false }
            Game.instance.fire_event(data[:observer], :event_try_detect_invis, detect_data)
            if !detect_data[:success]
                data[:chance] = 0
            end
        end
    end

    def send_start_messages
        @target.room.occupants.each_output "0<N> cloak0<,s> 0<r> from the wrath of mobiles.", [@target]
    end

    def send_complete_messages
        @target.room.occupants.each_output "0<N> 0<is, are> no longer invisible to mobiles.", [@target]
    end
end

class AffectCloudkill < Affect

    def initialize(source, target, level)
        super(
            source, # source
            target, # target
            level, # level
            70 + level, # duration
            nil, # modifiers: nil
            10, # period: nil
            false, # permanent: false
            Constants::AffectVisibility::NORMAL, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "cloudkill",
            keywords: ["cloudkill"],
            application_type: :global_single,
        }
    end

    def start
        Game.instance.add_event_listener(@target, :event_calculate_room_description, self, :cloudkill_description)
        Game.instance.add_event_listener(@target, :event_room_mobile_enter, self, :add_damage_listener)
        Game.instance.add_event_listener(@target, :event_room_mobile_exit, self, :remove_damage_listener)
        @target.occupants.each do |t|
            Game.instance.add_event_listener(t, :event_calculate_damage, self, :cloudkill_poison_damage_calc)
        end
    end

    def complete
        Game.instance.remove_event_listener(@target, :event_calculate_room_description, self)
        Game.instance.remove_event_listener(@target, :event_room_mobile_enter, self)
        Game.instance.remove_event_listener(@target, :event_room_mobile_exit, self)
        @target.occupants.each do |t|
            Game.instance.remove_event_listener(t, :event_calculate_damage, self)
        end
    end

    def cloudkill_description(data)
        data[:extra_show] += "\nA cloud of chlorine gas covers everything!"
    end

    def add_damage_listener(data)
        Game.instance.add_event_listener(data[:mobile], :event_calculate_damage, self, :cloudkill_poison_damage_calc)
    end

    def remove_damage_listener(data)
        Game.instance.remove_event_listener(data[:mobile], :event_calculate_damage, self)
    end

    def cloudkill_poison_damage_calc(data)
        if data[:element] == Constants::Element::POISON && data[:type] == Constants::Damage::MAGICAL
            data[:damage] *= 2
        end
    end

    def periodic
        @target.occupants.each do |t|
            t.receive_damage(source: @source, damage: dice(2, 6), noun: "The caustic gas", element: Constants::Element::POISON, type: Constants::Damage::MAGICAL, anonymous: true)
        end
    end

    def send_start_messages
        @source.output "You exhale a cloud of toxic gas to cover the room!"
        (@target.occupants - [@source]).each_output("0<N> emits a greenish cloud of poison gas!", @source)
    end

    def send_complete_messages
        @target.occupants.each_output "The cloud of poison gas slowly dissipates."
    end

end

class AffectCorroded < Affect

    def initialize(source, target, level)
        super(
            source, # source
            target, # target
            level, # level
            30, # duration
            { ac_pierce: -10, ac_slash: -10, ac_bash: -10 }, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            Constants::AffectVisibility::NORMAL, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "corroded",
            keywords: ["corroded"],
            application_type: :global_stack,
        }
    end

    def send_start_messages
        (@target.room.occupants - [@target]).each_output "{g0<N>'s flesh burns away, revealing vital areas!{x", [@target]
        @target.output "{gChunks of your flesh melt away, exposing vital areas!{x"
    end

    def send_refresh_messages
        (@target.room.occupants - [@target]).each_output "{g0<N>'s flesh burns away, revealing vital areas!{x", [@target]
        @target.output "{gChunks of your flesh melt away, exposing vital areas!{x"
    end

    def send_complete_messages
        @target.output "Your flesh begins to heal."
    end

end

class AffectCorrosiveWeapon < Affect

    def initialize(source, target, level)
        super(
            source, # source
            target, # target
            level, # level
            60, # duration
            nil, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            Constants::AffectVisibility::NORMAL, # visibility
            true # savable
        )
        @data = {
            chance: 5
        }
    end

    def self.affect_info
        return @info || @info = {
            name: "corrosive",
            keywords: ["corrosive"],
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
        Game.instance.add_event_listener(@target.carrier, :event_override_hit, self, :do_flag)
    end

    def remove_flag(data)
        Game.instance.remove_event_listener(@target.carrier, :event_override_hit, self)
    end

    def do_flag(data)
        if data[:weapon] == @target && data[:target].active
            data[:target].output "Your flesh is dissolved by 0<n>.", [@target]
            (data[:target].room.occupants | data[:source].room.occupants).each_output "0<N>'s flesh is dissolved by 1<n>'s 2<n>.", [data[:target], data[:source], @target]
            if dice(1, 100) <= @data[:chance]
                data[:target].apply_affect(AffectCorroded.new(data[:source], data[:target], @target.level))
            end
        end
    end

end

class AffectCurse < Affect

    def initialize(source, target, level)
        super(
            source, # source
            target, # target
            level, # level
            69 + level, # duration
            { hitroll: -5 }, # modifiers: nil
            nil, # period: nil
            false, # permanent: false
            Constants::AffectVisibility::NORMAL, # visibility
            true # savable
        )
    end

    def self.affect_info
        return @info || @info = {
            name: "curse",
            keywords: ["curse"],
            application_type: :global_single,
        }
    end

    def send_start_messages
        @target.output "You feel unclean."
        (@target.room.occupants - [@target]).each_output "0<N> looks very uncomfortable.", [@target]
    end

    def send_complete_messages
        @target.output "You feel better."
    end

    def start
        Game.instance.add_event_listener(@target, :event_try_recall, self, :do_cursed)
    end

    def complete
        Game.instance.remove_event_listener(@target, :event_try_recall, self)
    end

    def do_cursed( data )
        data[:success] = false
    end

end
