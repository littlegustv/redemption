require_relative 'mobile_item'

class Mobile < GameObject

    attr_accessor :id, :attacking, :lag, :position, :inventory, :affects, :active
    attr_accessor :level, :group, :in_group, :experience, :quest_points, :alignment, :wealth

    attr_reader :game, :room, :race_id, :class_id, :stats

    include MobileItem

    def initialize( data, game, room )
        super(data[ :short_description ], game)
        @attacking
        @lag = 0
        @keywords = data[:keywords]
        @id = data[ :id ]
        @short_description = data[ :short_description ]
        @long_description = data[ :long_description ]
        @full_description = data[ :full_description ]
        @equip_slots = []
        set_race_id(data[:race_id])
        set_class_id(data[:class_id])
        @skills = []
        @spells = [] + ["lightning bolt", "acid blast", "blast of rot", "pyrotechnics", "ice bolt"]

        @experience = 0
        @experience_to_level = 1000
        @quest_points = 0
        @quest_points_to_remort = 1000
        @alignment = data[ :alignment ].to_i
        @wealth = data[:wealth].to_i
        @wimpy = 0
        @active = true
        @group = []
        @in_group = nil

        @stats = {
            success: 100,
            str: data[:str] || 0,
            con: data[:con] || 0,
            int: data[:int] || 0,
            wis: data[:wis] || 0,
            dex: data[:dex] || 0,
            max_str: data[:max_str] || 0,
            max_con: data[:max_con] || 0,
            max_int: data[:max_int] || 0,
            max_wis: data[:max_wis] || 0,
            max_dex: data[:max_dex] || 0,
            hitroll: data[:hitroll] || rand(5...7),
            damroll: data[:damage] || 50,
            attack_speed: 1,
            ac_pierce: data[:ac].to_a[0].to_i,
            ac_bash: data[:ac].to_a[1].to_i,
            ac_slash: data[:ac].to_a[2].to_i,
            ac_magic: data[:ac].to_a[3].to_i,
        }

        @level = data[:level] || 1
        @hitpoints = data[:hitpoints] || 500
        @basehitpoints = @hitpoints

        @manapoints = data[:manapoints] || 100
        @basemanapoints = @manapoints

        @movepoints = data[:movepoints] || 100
        @basemovepoints = @movepoints

        @damage_range = data[:damage_range] || [ 2, 12 ]
        @noun = data[:attack] || ["entangle", "grep", "strangle", "pierce", "smother", "flaming bite"].sample
        # @armor_class = data[:armor_class] || [0, 0, 0, 0]
        @parts = data[:parts] || Constants::PARTS

        @position = Position::STAND
        @inventory = Inventory.new(owner: self, game: @game)

        @room = room
        @room.mobile_arrive(self) if @room

        apply_affect_flags(data[:affect_flags].to_a)
        apply_affect_flags(data[:specials].to_a)
    end

    # alias for @game.destroy_mobile(self)
    def destroy
        @game.destroy_mobile(self)
    end

    def knows( skill_name )
        (skills + spells).include? skill_name
    end

    def gold
        ( @wealth / 1000 ).floor
    end

    def silver
        ( @wealth - gold * 1000 )
    end

    def to_worth
        gold > 0 ? "#{ gold } gold and #{ silver } silver" : "#{ silver } silver"
    end

    def earn( n )
        @wealth += n
    end

    def spend( n )
        net = @wealth - n
        if net < 0
            return false
        else
            @wealth = net
            return true
        end
    end

    def update( elapsed )
        super elapsed
    end

    def use_mana( n )
        n <= @manapoints ? (@manapoints -= n) : false
    end

    def remove_from_group
        self.output "You leave #{self.in_group}'s group."
        self.in_group.output "#{self} leaves your group."

        self.in_group.group.delete self
        puts "#{self.in_group.group.length} others in group."
        self.in_group = nil
    end

    def add_to_group( leader )
        self.output "You join #{leader}'s group."
        leader.output "#{self} joins your group."

        self.in_group = leader
        leader.group.push self
        puts "#{leader.group.length} others in group."
    end

    def group_info
        group_string = ""

        if self.group.any?
            group_string += "Your group:\n\r\n\r"
            group_string += self.group_desc + "\n\r"
            self.group.each do |target|
                group_string += target.group_desc + "\n\r"
            end
        elsif !self.in_group.nil?
            group_string += "#{self.in_group}'s group:\n\r\n\r"
            group_string += self.in_group.group_desc + "\n\r"
            self.in_group.group.each do |target|
                group_string += target.group_desc + "\n\r"
            end
        else
            group_string = "You're not in a group."
        end

        group_string
    end

    def group_desc
        self.who
    end

    def do_command( input )
        cmd, args = input.sanitize.split " ", 2
        @game.do_command( self, cmd, args.to_s.scan(/(((\d+|all)\*)?((\d+|all)\.)?(\w+|'[\w\s]+'))/i).map(&:first).map{ |arg| arg.gsub("'", "") } )
    end

    # When mobile is attacked, respond automatically unless already in combat targeting someone else
    #
    # When calling 'start_combat', call it first for the 'victim', then for the attacker

    def start_combat( attacker )
        if !@active || !attacker.active || !@room.contains?([self, attacker])
            return
        end

        @game.fire_event( :event_on_start_combat, {}, self )

        # only the one being attacked
        if attacker.attacking != self && @attacking != attacker && is_player?
            attacker.apply_affect( AffectKiller.new(source: attacker, target: attacker, level: 0, game: @game) ) if attacker.is_player?
            do_command "yell 'Help I am being attacked by #{attacker}!'"
        end
        @position = Position::FIGHT
        if @attacking.nil?
            @attacking = attacker
        end
    end

    def stop_combat
        @attacking = nil
        @position = Position::STAND if @position == Position::FIGHT
        target({ attacking: self, type: ["Mobile", "Player"] }).each do |t|
            t.attacking = nil
            if target({ quantity: "all", attacking: t, type: ["Mobile", "Player"] }).empty?
                t.position = Position::STAND if t.position == Position::FIGHT
            end
        end
    end

    # all this does right now is regen some HP
    def tick
        regen 50
    end

    def regen( n )
        @hitpoints = [@hitpoints + n, maxhitpoints].min
    end

    def combat
        if @attacking && @active && @attacking.active
            to_me = []
            to_target = []
            to_room = []
            weapon = wielded.first
            stat( :attack_speed ).times do |attack|
                hit_chance = ( attack_rating - @attacking.defense_rating( weapon ? weapon.element : "bash" ) ).clamp( 5, 95 )
                if rand(0...100) < hit_chance
                    damage = damage_rating
                else
                    damage = 0
                end
                data = { damage: damage, source: self, target: @attacking }
                @game.fire_event( :event_calculate_damage, data, self )

                # :event_override_hit allows for affects to completely replace
                # a normal physical attack - including both aggressively ( burst rune )
                # and defensively ( mirror image )

                # if an override has occurred, it is passed through the 'confirm' field,
                # and the normal hit does not occur

                hit data[:damage]

                return if @attacking.nil?
                weapon_flags if data[:damage] > 0
                return if @attacking.nil?
            end
        end
    end

    def noun
        weapon = wielded.first
        weapon ? weapon.noun : @noun
    end

    def weapon_flags
        weapon = wielded.first
        ( flags = ( weapon ? weapon.flags : [] ) ).each do |flag|
            if ( texts = Constants::ELEMENTAL_EFFECTS[ flag ] )
                @attacking.output texts[0], [self]
                @attacking.broadcast texts[1], target({ not: @attacking, room: @room }), [ @attacking, weapon ]
                elemental_effect( @attacking, flag )
                @attacking.damage( 10, self )
                return if @attacking.nil?
            end
        end
    end

    def elemental_effect( target, element )
        if rand(1..10) <= Constants::ELEMENTAL_CHANCE
            case element
            when "flooding"
                target.apply_affect(AffectFlooding.new(target: target, source: self, level: self.level, game: @game))
            when "shocking"
                target.apply_affect(AffectShocking.new(target: target, source: self, level: self.level, game: @game))
            when "corrosive"
                target.apply_affect(AffectCorrosive.new( target: target, source: self, level: self.level, game: @game))
            when "poison"
                target.apply_affect( AffectPoison.new( target: target, source: self, level: self.level, game: @game ) )
            when "flaming"
                target.apply_affect(AffectFireBlind.new(target: target, source: self, level: self.level, game: @game))
            when "frost"
                target.apply_affect( AffectFrost.new(target: target, source: self, level: self.level, game: @game))
            end
        end
    end

    def magic_hit( target, damage, noun = "spell", element = "spell" )
        if target != self
            target.start_combat( self )
            self.start_combat( target )
        end

        decorators = Constants::MAGIC_DAMAGE_DECORATORS.select{ |key, value| damage >= key }.values.last

        output "Your #{noun} #{decorators[0]} %s#{decorators[1]}#{decorators[2]}", [target] if @room == target.room
        target.output("%s's #{noun} #{decorators[0]} you#{decorators[1]}#{decorators[2]}", [self]) unless target == self
        broadcast "%s's #{noun} #{decorators[0]} %s#{decorators[1]}#{decorators[2]}", target({ not: [self, target], room: @room }), [self, target]

        elemental_effect( target, element )
        elemental_effect( target, element ) if knows "essence"

        target.damage( damage, self )
    end

    def hit( damage, custom_noun = nil, target = nil )
        override = { confirm: false, source: self, target: @attacking }
        @game.fire_event( :event_override_hit, override, self, @attacking, equipment )

        if not override[:confirm]

            hit_noun = custom_noun || noun
            target = target || @attacking
            decorators = Constants::DAMAGE_DECORATORS.select{ |key, value| damage >= key }.values.last

            output "Your #{decorators[2]} #{hit_noun} #{decorators[1]} %s#{decorators[3]} [#{damage}]", [target] if @room == target.room
            target.output "%s's #{decorators[2]} #{hit_noun} #{decorators[1]} you#{decorators[3]}", [self]
            broadcast "%s's #{decorators[2]} #{hit_noun} #{decorators[1]} %s#{decorators[3]} ", target({ not: [ self, target ], room: @room }), [self, target]

            target.damage( damage, self )
            data = { damage: damage, source: self, target: attacking }
            @game.fire_event(:event_on_hit, data, self, @room, @room.area, equipment)

        end
    end

    def anonymous_damage( damage, element = nil, magic = true, source = "Powerful magic" )
        decorators = []
        if magic
            decorators = Constants::MAGIC_DAMAGE_DECORATORS.select{ |key, value| damage >= key }.values.last
            output "#{source} #{decorators[0]} you#{decorators[1]}#{decorators[2]}"
            broadcast "#{source} #{decorators[0]} %s#{decorators[1]}#{decorators[2]}", target({ not: [self], room: @room }), [self]
            elemental_effect( self, element )
        else
            decorators = Constants::DAMAGE_DECORATORS.select{ |key, value| damage >= key }.values.last
            output "#{source} #{decorators[1]} you#{decorators[3]}"
            broadcast "#{source} #{decorators[1]} %s#{decorators[3]}", target({ not: [self], room: @room }), [self]
        end
        damage(damage, nil)
    end

    def damage( damage, attacker )
        @hitpoints -= damage
        die( attacker ) if @hitpoints <= 0
    end

    def deal_damage(target:, damage:, element: Constants::Element::NONE, type: Constants::Damage::PHYSICAL)

    end

    def receive_damage(source:, damage:, element: Constants::Element::NONE, type: Constants::Damage::PHYSICAL)

    end

    def show_equipment(observer)
        objects = []
        lines = []
        string = ""
        @equip_slots.each do |equip_slot|
            line = "<#{equip_slot.list_prefix}>".ljust(22)
            if equip_slot.item
                line << "%s"
                objects << equip_slot.item
            else
                if observer == self
                    line << "<Nothing>"
                else
                    next
                end
            end
            lines << line
        end
        observer.output(lines.join("\n"), objects)
    end

    def level_up
        @experience = (@experience - @experience_to_level)
        @level += 1
        @basehitpoints += 20
        @basemanapoints += 10
        @basemovepoints += 10
        output "You raise a level!!  You gain 20 hit points, 10 mana, 10 move, and 0 practices."
        @game.fire_event(:event_on_level_up, {level: @level}, self, @room, @room.area, equipment)
    end

    def xp( target )
        if !@active
            return
        end
        dlevel = [target.level - @level, -10].max
        base_xp = dlevel <= 5 ? Constants::EXPERIENCE_SCALE[dlevel] : ( 180 + 12 * (dlevel - 5 ))
        base_xp *= 10  / ( @level + 4 ) if @level < 6
        base_xp = rand(base_xp..(5 * base_xp / 4))
        @experience = @experience.to_i + base_xp.to_i
        output "You receive #{base_xp} experience points."
        if @experience > @experience_to_level
            level_up
        end
    end

    def die( killer )
        if !@active
            return
        end
        broadcast "%s is DEAD!!", target({ :not => self, :room => @room }), [self]
        @affects.each do |affect|
            affect.clear(silent: true)
        end
        killer.xp( self ) if killer
        broadcast "%s's head is shattered, and her brains splash all over you.", target({ :not => self, :room => @room }), [self]
        if killer
            self.items.each do |item|
                killer.get_item(item)
            end
            killer.output("You get #{ self.to_worth } from the corpse of %s", [self])
            killer.output("You offer your victory to Gabriel who rewards you with 1 deity points.")
            killer.earn( @wealth )
        end
        stop_combat
        destroy
    end

    def deactivate
        @active = false
    end

    def move( direction )
        if @room.exits[ direction.to_sym ].nil?
            output "There is no exit [#{direction}]."
            return false
        else
            broadcast "%s leaves #{direction}.", target({ :not => self, :room => @room }), [self] unless self.affected? "sneak"
            # @game.fire_event( :event_mobile_exit, { mobile: self }, self, @room )
            move_to_room(@room.exits[direction.to_sym])
            broadcast "%s has arrived.", target({ :not => self, :room => @room }), [self] unless self.affected? "sneak"
            @game.fire_event( :event_mobile_enter, { mobile: self }, self, @room, @room.occupants - [self] )
            return true
        end
    end

    def look_room
        @game.do_command self, "look"
    end

    def who
        "[#{@level.to_s.rjust(2)} #{@game.race_data.dig(@race_id, :display_name).ljust(7)} #{@game.class_data.dig(@class_id, :name).capitalize.rjust(7)}] #{@short_description}"
    end

    def move_to_room( room )
        if @attacking && @attacking.room != room
            stop_combat
        end
        @room&.mobile_depart(self)
        @room = room
        if @room
            @room.mobile_arrive(self)
            @game.do_command self, "look"
        end
    end

    def recall
        output "You pray for transportation!"
        broadcast "%s prays for transportation!", target({ room: @room, not: self }), [self]
        broadcast "%s disappears!", target({ room: @room, not: self }), [self]
        room = @game.recall_room( @room.continent )
        move_to_room( room )
        broadcast "%s arrives in a puff of smoke!", target({ room: room, not: self }), [self]
        return true
    end

    def condition_percent
        (( 100 * @hitpoints ) / maxhitpoints).to_i
    end

    def condition
        percent = condition_percent
        if (percent >= 100)
            return "#{self} is in excellent condition.\n"
        elsif (percent >= 90)
            return "#{self} has a few scratches.\n"
        elsif (percent >= 75)
            return "#{self} has some small wounds and bruises.\n"
        elsif (percent >= 50)
            return "#{self} has quite a few wounds.\n"
        elsif (percent >= 30)
            return "#{self} has some big nasty wounds and scratches.\n"
        elsif (percent >= 15)
            return "#{self} looks pretty hurt.\n"
        elsif (percent >= 0)
            return "#{self} is in awful condition.\n"
        else
            return "#{self} is bleeding to death.\n"
        end
    end

    def attack_rating
        (15 + (@level * 3 / 2))
    end

    def defense_rating( element )
        ( -1 * stat( "armor_#{element}".to_sym ) - 100 ) / 5
    end

    def damage_rating
        weapon = wielded.first
        if weapon
            weapon.damage + stat(:damroll)
        else
            rand(@damage_range[0]...@damage_range[1]).to_i + stat(:damroll)
        end
    end

    def to_s
        @short_description
    end

    def long
        data = { description: @long_description }
        @game.fire_event( :event_calculate_description, data, self )
        data[:description]
    end

    def full
        @full_description
    end

    # returns true if self can see target
    def can_see? target
        return true if target == self
        data = {chance: 100, target: target}
        @game.fire_event(:event_try_can_see, data, self, @room, @room.area, equipment)
        result = dice(1, 100) <= data[:chance]
        return result
    end

    def carry_max
        51
    end

    def weight_max
        251
    end

    def maxhitpoints
        @basehitpoints
    end

    def maxmanapoints
        @basemanapoints
    end

    def maxmovepoints
        @basemovepoints
    end

    # Returns the value of a stat for a given key.
    # Adjusts
    #
    #  some_mobile.stat(:str)
    #  some_mobile.stat(:max_wis)
    #  some_mobile.stat(:damroll)
    def stat(key)
        stat = (@game.race_data[@race_id][key] || 0) + @stats[key].to_i
        class_main_stat = @game.class_data.dig(@class_id, :main_stat).to_s
        if key.to_s == class_main_stat # class main stat bonus
            stat += 3
        end
        if key.to_s == "max_#{class_main_stat}" # class max main stat bonus
            stat += 2
        end
        if [:max_str, :max_int, :max_dex, :max_con, :max_wis].include?(key) # limit max stats to 25
            stat = [25, stat].min                                           # (before gear and affects are applied)
        end
        stat += equipment.map{ |item| item.nil? ? 0 : item.modifier( key ).to_i + item.affects.map{ |aff| aff.modifier( key ).to_i }.reduce(0, :+) }.reduce(0, :+)
        stat += @affects.map{ |aff| aff.modifier( key ).to_i }.reduce(0, :+)
        if [:str, :int, :dex, :con, :wis].include?(key)
            stat = [stat("max_#{key}".to_sym), stat].min # limit stats by their max_stat
        end
        return stat
    end

    # def armor(index)
    #     @armor_class[index].to_i + @equipment.map{ |slot, value| value.nil? ? 0 : value.armor( index ).to_i }.reduce(0, :+)
    # end

    def cast( spell, args )
        @casting = spell
        @casting_args = args
    end

    def score
    race_hash = @game.race_data[@race_id]
%Q(#{@short_description}
Member of clan Kenshi
---------------------------------- Info ---------------------------------
{cLevel:{x     #{@level.to_s.ljust(26)} {cAge:{x       17 - 0(0) hours
{cRace:{x      #{@game.race_data.dig(@race_id, :name).to_s.ljust(26)} {cSex:{x       male
{cClass:{x     #{@game.class_data.dig(@class_id, :name).to_s.ljust(26)} {cDeity:{x     Gabriel
{cAlignment:{x #{@alignment.to_s.ljust(26)} {cDeity Points:{x 0
{cPracs:{x     N/A                        {cTrains:{x    N/A
{cExp:{x       #{"#{@experience} (#{@experience_to_level}/lvl)".ljust(26)} {cNext Level:{x #{@experience_to_level - @experience}
{cQuest Points:{x #{ @quest_points } (#{ @quest_points_to_remort } for remort/reclass)
{cCarrying:{x  #{ "#{@inventory.count} of #{carry_max}".ljust(26) } {cWeight:{x    #{ @inventory.items.map(&:weight).reduce(0, :+).to_i } of #{ weight_max }
{cGold:{x      #{ gold.to_s.ljust(26) } {cSilver:{x    #{ silver.to_s }
{cClaims Remaining:{x N/A
---------------------------------- Stats --------------------------------
{cHp:{x        #{"#{@hitpoints} of #{maxhitpoints} (#{@basehitpoints})".ljust(26)} {cMana:{x      #{@manapoints} of #{maxmanapoints} (#{@basemanapoints})
{cMovement:{x  #{"#{@movepoints} of #{maxmovepoints} (#{@basemovepoints})".ljust(26)} {cWimpy:{x     #{@wimpy}
#{score_stat("str")}#{score_stat("con")}
#{score_stat("int")}#{score_stat("wis")}
#{score_stat("dex")}
{cHitRoll:{x   #{ stat(:hitroll).to_s.ljust(26)} {cDamRoll:{x   #{ stat(:damroll) }
{cDamResist:{x #{ stat(:damresist).to_s.ljust(26) } {cMagicDam:{x  #{ stat(:magicdam) }
{cAttackSpd:{x #{ stat(:attack_speed) }
--------------------------------- Armour --------------------------------
{cPierce:{x    #{ (-1 * stat(:ac_pierce)).to_s.ljust(26) } {cBash:{x      #{ -1 * stat(:ac_bash) }
{cSlash:{x     #{ (-1 * stat(:ac_slash)).to_s.ljust(26) } {cMagic:{x     #{ -1 * stat(:ac_magic) }
------------------------- Condition and Affects -------------------------
You are Ruthless.
You are #{Position::STRINGS[ @position ]}.)
    end

    # Take a stat name as a string and convert it into a score-formatted output string.
    #
    #  score_stat("str")     # => Str:       14(14) of 23
    def score_stat(stat_name)
        stat = stat_name.to_sym
        max_stat = "max_#{stat_name}".to_sym
        base = @stats[stat]+@game.race_data.dig(@race_id, stat).to_i
        base += 3 if @game.class_data.dig(@class_id, :main_stat) == stat_name
        modified = stat(stat)
        max = stat(max_stat)
        return "{c#{stat_name.capitalize}:{x       #{"#{base}(#{modified}) of #{max}".ljust(27)}"
    end

    def skills
        return @skills | @game.race_data.dig(@race_id, :skills).to_a | @game.class_data.dig(@class_id, :skills).to_a
    end

    def spells
        return @spells | @game.race_data.dig(@race_id, :spells).to_a | @game.class_data.dig(@class_id, :spells).to_a
    end

    def set_race_id(new_race_id)
        @race_id = new_race_id

        old_equipment = self.equipment
        old_equipment.each do |item| # move all equipped items to inventory
            item.move(@inventory)
        end
        @equip_slots = []  # Clear old equip_slots
        equip_slots = @game.race_data.dig(@race_id, :equip_slots)
        equip_slots.each do |equip_slot|
            row = @game.equip_slot_data[equip_slot.to_i]
            if row
                @equip_slots << EquipSlot.new(equip_message_self: row[:equip_message_self],
                                           equip_message_others: row[:equip_message_others],
                                           list_prefix: row[:list_prefix],
                                           wear_flag: row[:wear_flag])
            end
        end
        old_equipment.each do |item| # try to wear all items that were equipped before
            wear(item: item, silent: true)
        end

        affect_flags = @game.race_data.dig(@race_id, :affect_flags)
        apply_affect_flags(affect_flags) if affect_flags
    end

    def set_class_id(new_class_id)
        @class_id = new_class_id
        affect_flags = @game.class_data.dig(@class_id, :affect_flags)
        apply_affect_flags(affect_flags) if affect_flags
    end

    def is_player?
        return false
    end

    def casting_level
        class_multiplier = @game.class_data.dig(@race_id, :casting_multiplier)
        casting = @level
        casting *= (class_multiplier.to_i / 100) if class_multiplier
        return [1, casting.to_i].max
    end

    def db_source_type
        return "Mobile"
    end

end
