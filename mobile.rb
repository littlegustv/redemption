require_relative 'mobile_item'

class Mobile < GameObject

    attr_accessor :id
    attr_accessor :attacking
    attr_accessor :lag
    attr_accessor :position
    attr_accessor :inventory
    attr_accessor :active
    attr_accessor :level
    attr_accessor :group
    attr_accessor :in_group
    attr_accessor :experience
    attr_accessor :quest_points
    attr_accessor :alignment
    attr_accessor :wealth

    attr_reader :game
    attr_reader :room
    attr_reader :race_id
    attr_reader :class_id
    attr_reader :stats
    attr_reader :hitpoints
    attr_reader :manapoints
    attr_reader :movepoints

    include MobileItem

    def initialize( data, race_id, class_id, game, room )
        super(data[ :short_description ], data[:keywords].split(" "), game)
        @attacking = nil
        @lag = 0
        @id = data[ :id ]
        @short_description = data[ :short_desc ]
        @long_description = data[ :long_desc ]
        @full_description = data[ :full_desc ]
        @race_equip_slots = []
        @class_equip_slots = []
        @equip_slots = []
        @skills = []
        @spells = [] + ["lightning bolt", "acid blast", "blast of rot", "pyrotechnics", "ice bolt"]

        @experience = 0
        @experience_to_level = 1000
        @quest_points = 0
        @quest_points_to_remort = 1000
        @alignment = data[ :align ].to_i
        @wealth = data[:wealth].to_i
        @wimpy = 0
        @active = true
        @group = []
        @in_group = nil
        @deity = "Gabriel"

        @casting = nil
        @casting_args = nil
        @casting_input = nil

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
            ac_pierce: data[:ac_pierce].to_i,
            ac_bash: data[:ac_bash].to_i,
            ac_slash: data[:ac_slash].to_i,
            ac_magic: data[:ac_magic].to_i,
        }

        @level = data[:level] || 1
        @hitpoints = ( dice( data[:hp_dice_count].to_i, data[:hp_dice_sides].to_i ) + data[:hp_dice_bonus].to_i ) || 500
        @basehitpoints = @hitpoints

        @manapoints = ( dice( data[:mana_dice_count].to_i, data[:mana_dice_sides].to_i ) + data[:mana_dice_bonus].to_i ) || 100
        @basemanapoints = @manapoints

        @movepoints = data[:movepoints] || 100
        @basemovepoints = @movepoints

        # @damage_range = data[:damage_range] || nil
        # @noun = data[:attack] || nil
        @damage_dice_sides = data[:damage_dice_sides]
        @damage_dice_count = data[:damage_dice_count]
        @damage_dice_bonus = data[:damage_dice_bonus]
        @hand_to_hand_noun = data[:hand_to_hand_noun]
        @swing_counter = 0
        @hand_to_hand = nil

        @parts = data[:part_flags] || Constants::PARTS

        @position = Constants::Position::STAND
        @inventory = Inventory.new(owner: self, game: @game)

        @room = room
        @room.mobile_enter(self) if @room
        @race_affects = []                  # list of affects applied by race
        @class_affects = []                  # list of affects applied by race

        set_race_id(data[:race_id])
        set_class_id(data[:class_id])

        apply_affect_flags(data[:affect_flags].to_a)
        apply_affect_flags(data[:act_flags].to_a)
        apply_affect_flags(data[:specials].to_a)
    end

    # alias for @game.destroy_mobile(self)
    def destroy
        @game.destroy_mobile(self)
    end

    def knows( skill_name )
        (skills + spells).include? skill_name
    end

    def proficient( weapon_type )
        weapons.include? weapon_type
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

    # shopkeeper specific, but where is the best place for this to be????

    # calculate the selling price of an item based on the number currently in inventory
    def sell_price( item )
        return ( item.cost * ( 1 + Constants::SHOP_MARKUP * ( Constants::SHOP_FULL_STOCK - @inventory.item_count[ item.id ].to_i ) ) ).to_i
    end

    # buy price is set to the sell price when stock = (n + 1)
    def buy_price( item )
        return ( item.cost * ( 1 + Constants::SHOP_MARKUP * ( Constants::SHOP_FULL_STOCK - ( @inventory.item_count[ item.id ].to_i + 1 ) )) ).to_i
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

    def use_mana( n )
        n <= @manapoints ? (@manapoints -= n) : false
    end

    def use_movement( n )
        n <= @movepoints ? (@movepoints -= n) : false
    end

    def remove_from_group
        self.output "You leave #{self.in_group}'s group."
        self.in_group.output "#{self} leaves your group."

        self.in_group.group.delete self
        log "#{self.in_group.group.length} others in group."
        self.in_group = nil
    end

    def add_to_group( leader )
        self.output "You join #{leader}'s group."
        leader.output "#{self} joins your group."

        self.in_group = leader
        leader.group.push self
        log "#{leader.group.length} others in group."
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
        @game.do_command( self, cmd, args.to_s.scan(/(((\d+|all)\*)?((\d+|all)\.)?([^\s\.\'\*]+|'[\w\s]+'?))/i).map(&:first).map{ |arg| arg.gsub("'", "") }, input )
        # @game.do_command( self, cmd, args.to_s.scan(/(((\d+|all)\*)?((\d+|all)\.)?(\w+|'[\w\s]+'))/i).map(&:first).map{ |arg| arg.gsub("'", "") } )
    end

    # When mobile is attacked, respond automatically unless already in combat targeting someone else
    #
    # When calling 'start_combat', call it first for the 'victim', then for the attacker

    def start_combat( attacker )
        if !@active || !attacker.active || !@room.contains?([self, attacker]) || attacker == self
            return
        end

        # only the one being attacked
        if attacker.attacking != self && @attacking != attacker && is_player?
            attacker.apply_affect( AffectKiller.new( attacker, attacker, 0, @game ) ) if attacker.is_player?
            do_command "yell Help I am being attacked by #{attacker}!"
        end
        old_position = @position
        @position = Constants::Position::STAND
        if old_position == Constants::Position::SLEEP
            look_room
        end
        if @attacking.nil?
            @attacking = attacker
        end

        @game.fire_event( self, :event_on_start_combat, {} )
        @game.add_combat_mobile(self)
        attacker.start_combat( self ) if attacker.attacking.nil?
    end

    # sets mobiles attacking target to 'nil', so 'combat' method will no longer call a round of attacks
    #
    # then iterates through all room occupants that were targeting 'self' in combat and sets them to attack the next
    # mobile that is currently in combat with THEM
    #
    # if no new combatant is found, the new target is set to 'nil' which stops combat as well

    def stop_combat
        @attacking = nil
        @game.remove_combat_mobile(self)
        target({ attacking: self, list: @room.occupants }).each do |t|
            attacking_t = target({ quantity: "all", attacking: t, list: t.room.occupants })
            if attacking_t.size > 0
                t.attacking = attacking_t.first
            else
                @game.remove_combat_mobile(t)
                t.attacking = nil
            end
        end
    end

    # all this does right now is regen some HP
    def tick
        regen 100, 100, 100
    end

    def regen( hp, mp, mv )
        data = { hp: hp, mp: mp, mv: mv }
        @game.fire_event( self, :event_calculate_regeneration, data )
        hp, mp, mv = data.values
        @hitpoints = [@hitpoints + hp, maxhitpoints].min
        @manapoints = [@manapoints + mp, maxmanapoints].min
        @movepoints = [@movepoints + mv, maxmovepoints].min
    end

    def combat
        if @attacking && @active && @attacking.active
            do_round_of_attacks(target: @attacking)
        end
    end

    def weapon_flags(weapon)
        ( flags = ( weapon ? weapon.flags : [] ) ).each do |flag|
            if ( texts = Constants::ELEMENTAL_EFFECTS[ flag ] )
                @attacking.output texts[0], [self]
                @attacking.broadcast texts[1], target({ not: @attacking, list: @room.occupants }), [ @attacking, weapon ]
            end
            elemental_effect( @attacking, flag )
            # @attacking.damage( 10, self )
            return if @attacking.nil?
        end
    end

    def elemental_effect( target, element )
        if rand(1..10) <= Constants::ELEMENTAL_CHANCE
            case element
            when "flooding"
                target.apply_affect(AffectFlooding.new(self, target, self.level, @game))
            when "shocking"
                target.apply_affect(AffectShocking.new(self, target, self.level, @game))
            when "corrosive"
                target.apply_affect(AffectCorrosive.new(self, target, self.level, @game))
            when "poison"
                target.apply_affect( AffectPoison.new(self, target, self.level, @game) )
            when "flaming"
                target.apply_affect(AffectFireBlind.new(self, target, self.level, @game))
            when "frost"
                target.apply_affect( AffectFrost.new(self, target, self.level, @game))
            when "demonic"
                target.output "%s has assailed you with the demons of Hell!", self
                broadcast "%s calls forth the demons of Hell upon %s!", @room.occupants - [self, target], [self, target]
                output "You conjure forth the demons of hell!"
                target.apply_affect( AffectCurse.new(self, target, self.level, @game))
            end
        end
    end

    # Gets a single weapon in wielded slot, cycling on each hit, or hand to hand
    def weapon_for_next_hit
        weapons = wielded
        case weapons.length
        when 0 # hand to hand
            return hand_to_hand_weapon
        when 1 # single weapon
            return weapons.first
        else # multi-wield
            @swing_counter.clamp(0, weapons.length - 1)
            @swing_counter = (@swing_counter + 1) % weapons.length
            return weapons[@swing_counter]
        end
        log "Error in mobile weapon_for_next_hit: #{name}" # should never happen
        return nil
    end

    # generate hand to hand weapon.
    def hand_to_hand_weapon
        weapon_data = {
            short_description: "Hand to hand",
            id: 0,
            keywords: "",
            level: @level,
            weight: 0,
            cost: 0,
            long_description: "",
            type: "weapon",
            genre: "hand to hand",
            wear_location: nil,
            material: "flesh",
            extra_flags: [],
            wear_flags: [],
            modifiers: {},
            ac: {},
            noun: @hand_to_hand_noun || @game.race_data.dig(@race_id, :h2h_noun),
            flags: @game.race_data.dig(@race_id, :h2h_flags),
            element: @game.race_data.dig(@race_id, :h2h_element),
            dice_count: @damage_dice_count || 6,
            dice_sides: @damage_dice_sides || 7,
            dice_bonus: @damage_dice_bonus || 0
        }
        weapon = Weapon.new(weapon_data, @game, nil)
        return weapon
    end

    # do a round of attacks against a target
    def do_round_of_attacks(target: nil)
        if !target
            target = @attacking
        end
        stat( :attack_speed ).times do |attack|
            weapon_hit(target: target) if target.attacking
        end
    end

    # Hit a target using weapon for damage
    def weapon_hit(target:, damage_bonus: 0, hit_bonus: 0, custom_noun: nil, weapon: nil)
        weapon = weapon || weapon_for_next_hit
        noun = custom_noun || weapon.noun
        hit = false
        override = { confirm: false, source: self, target: target, weapon: weapon }
        @game.fire_event( self, :event_override_hit, override )
        if override[:confirm]
            return
        end
        hit_chance = (hit_bonus + attack_rating( weapon ) - target.defense_rating( weapon ? weapon.element : "bash" ) ).clamp( 5, 95 )
        if rand(0...100) < hit_chance
            damage = damage_rating(weapon: weapon) + damage_bonus
            hit = true
        else
            damage = 0
        end
        data = { damage: damage, source: self, target: target, weapon: weapon }
        @game.fire_event( self, :event_calculate_weapon_hit_damage, data )
        deal_damage(target: target, damage: data[:damage], noun: noun, element: weapon.element, type: Constants::Damage::PHYSICAL)
        if hit
            override = { confirm: false, source: self, target: target, weapon: weapon }
            @game.fire_event( target, :event_override_receive_hit, override )
            if override[:confirm]
                return
            end
            data = { damage: damage, source: self, target: attacking }
            @game.fire_event(self, :event_on_hit, data)
        end
        if @attacking
            weapon_flags(weapon) if data[:damage] > 0
        end
    end

    # Deal some damage to a mobile.
    # +target+:: the mobile who will be receiving the damage
    # +damage+:: the amount of damage being dealt
    # +element+:: the element of the damage (fire, cold, etc)
    # +type+:: the type of the damage: physical of magical
    # +silent+:: true if damage decorators should not be broadcast
    # +anonymous+:: true if output messages should omit the +source+
    #  mob1.deal_damage(target: mob2, noun: "stab", element: Constants::Element::PIERCE, type: Constants::Damage::PHYSICAL)
    #  mob1.deal_damage(target: mob2, noun: "ice bolt", element: Constants::Element::COLD, type: Constants::Damage::MAGICAL)
    def deal_damage(target:, damage:, noun: "damage", element: Constants::Element::NONE, type: Constants::Damage::PHYSICAL, silent: false, anonymous: false)
        if !target || !target.active # if this is inactive, it can still deal damage
            return
        end
        if !is_player?
            damage = (damage * 0.1).to_i
        end
        calculation_data = { damage: damage, source: self, target: target, element: element, type: type }
        @game.fire_event(self, :event_calculate_damage, calculation_data)
        damage = calculation_data[:damage]
        target.receive_damage(source: self, damage: damage, noun: noun, element: element, type: type, silent: silent, anonymous: anonymous)
    end

    # Receive some damage!
    # +source+:: the mobile dealing the damage (can be nil)
    # +damage+:: the amount of damage being dealt
    # +element+:: the element of the damage (fire, cold, etc)
    # +type+:: the type of the damage: physical of magical
    # +silent+:: true if damage decorators should not be broadcast
    # +anonymous+:: true if output messages should omit the +source+
    def receive_damage(source:, damage:, noun: "damage", element: Constants::Element::NONE, type: Constants::Damage::PHYSICAL, silent: false, anonymous: false)
        if !@active # inactive mobiles can't take damage.
            return
        end
        if source && source != self
            self.start_combat( source )
        end
        override = { confirm: false, source: source, target: self, damage: damage, noun: noun, element: element, type: type }
        @game.fire_event(self, :event_override_receive_damage, override)
        if override[:confirm]
            return
        end
        calculation_data = { damage: damage, source: source, target: self, element: element, type: type }
        @game.fire_event(self, :event_calculate_receive_damage, calculation_data)
        damage = calculation_data[:damage]
        immune = calculation_data[:immune]
        if immune
            damage = 0
        end
        if type == Constants::Damage::PHYSICAL # physical damage
            if !silent
                decorators = Constants::DAMAGE_DECORATORS.select{ |key, value| damage >= key }.values.last
                if source && !anonymous
                    source.output("Your #{decorators[2]} #{noun} #{decorators[1]} #{(source==self) ? "yourself" : "%s"}#{decorators[3]} [#{damage}]", [self])
                    output("%s's #{decorators[2]} #{noun} #{decorators[1]} you#{decorators[3]}", [source]) if source != self
                    broadcast("%s's #{decorators[2]} #{noun} #{decorators[1]} %s#{decorators[3]} ", target({ not: [ self, source ], list: (self.room.occupants | source.room.occupants) }), [source, self])
                else # anonymous damage
                    output("#{noun} #{decorators[1]} you#{decorators[3]}", [self])
                    broadcast("#{noun} #{decorators[1]} %s#{decorators[3]} ", target({ not: [ self ], list: self.room.occupants }), [self])
                end
            end
        else # magic damage
            if !silent
                decorators = Constants::MAGIC_DAMAGE_DECORATORS.select{ |key, value| damage >= key }.values.last
                if source && !anonymous
                    source.output("Your #{noun} #{decorators[0]} #{(source==self) ? "yourself" : "%s"}#{decorators[1]}#{decorators[2]}", [self])
                    output("%s's #{noun} #{decorators[0]} you#{decorators[1]}#{decorators[2]}", [source]) if source != self
                    broadcast "%s's #{noun} #{decorators[0]} %s#{decorators[1]}#{decorators[2]}", target({ not: [self, source], list: (self.room.occupants | source.room.occupants) }), [source, self]
                else # anonymous damage
                    output("#{noun} #{decorators[0]} you#{decorators[1]}#{decorators[2]}", [self])
                    broadcast "#{noun} #{decorators[0]} %s#{decorators[1]}#{decorators[2]}", target({ not: [ self ], list: self.room.occupants }), [self]
                end
            end
        end
        @hitpoints -= damage
        die( source ) if @hitpoints <= 0
    end

    def level_up
        @experience = (@experience - @experience_to_level)
        @level += 1
        @basehitpoints += 20
        @basemanapoints += 10
        @basemovepoints += 10
        output "You raise a level!!  You gain 20 hit points, 10 mana, 10 move, and 0 practices."
        @game.fire_event(self, :event_on_level_up, {level: @level})
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
        broadcast "%s is DEAD!!", target({ not: self, list: @room.occupants }), [self]
        @game.fire_event( self, :event_on_die, {} )

        @affects.each do |affect|
            affect.clear(silent: true)
        end
        killer.xp( self ) if killer
        broadcast "%s's head is shattered, and her brains splash all over you.", target({ not: self, list: @room.occupants }), [self]
        if killer
            self.items.each do |item|
                killer.get_item(item)
            end
            killer.output("You get #{ self.to_worth } from the corpse of %s", [self])
            killer.output("You offer your victory to #{@deity} who rewards you with 1 deity points.")
            killer.earn( @wealth )
        end
        stop_combat
        destroy
    end

    def deactivate
        @active = false
    end

    # this COULD be handled with events, but they are so varied that I thought I'd try it this way first...
    def can_move?( direction )
        if (@room.sector == "air" || @room.exits[ direction.to_sym ].destination.sector == "air") && !self.affected?("flying")
            output "You can't fly!"
            return false
        else
            return true
        end

        # - flooded rooms & boat/swimming/fly
        # - doors and passdoor
        # - blocked exits
        # - others?

    end

    def move( direction )
        if @room.exits[ direction.to_sym ].nil?
            output "Alas, you cannot go that way."
            return false
        elsif not can_move? direction
            # nothing
        else
            broadcast "%s leaves #{direction}.", target({ :not => self, :list => @room.occupants }), [self] unless self.affected? "sneak"
            @game.fire_event(self, :event_mobile_exit, { mobile: self, direction: direction })
            old_room = @room
            if @room.exits[direction.to_sym].move( self )
                broadcast "%s has arrived.", target({ :not => self, :list => @room.occupants }), [self] unless self.affected? "sneak"
                (old_room.occupants - [self]).select { |t| t.position == Constants::Position::STAND }.each do |t|
                    @game.fire_event( t, :event_observe_mobile_exit, {mobile: self, direction: direction } )
                end
                @game.fire_event( self, :event_mobile_enter, { mobile: self } )
                (@room.occupants - [self]).each do |t|
                    @game.fire_event( t, :event_observe_mobile_enter, {mobile: self} )
                end
                return true
            else
                return false
            end
        end
    end

    def look_room
        @game.do_command self, "look"
    end

    def who
        "[#{@level.to_s.rpad(2)} #{@game.race_data.dig(@race_id, :display_name).lpad(8)} #{@game.class_data.dig(@class_id, :name).capitalize.rpad(8)}] #{@short_description}"
    end

    def weapons
        @game.class_data.dig(@class_id, :weapons).to_s + @game.race_data.dig(@race_id, :weapons).to_s
    end

    def move_to_room( room )
        if @attacking && @attacking.room != room
            stop_combat
        end
        @room&.mobile_exit(self)
        @room = room
        if @room
            @room.mobile_enter(self)
            if @position == Constants::Position::SLEEP
                output "Your dreams grow restless."
            else
                @game.do_command self, "look"
            end
        end
    end

    def recall
        output "You pray for transportation!"
        broadcast "%s prays for transportation!", target({ list: @room.occupants, not: self }), [self]
        data = { mobile: self, success: true }
        @game.fire_event(self, :event_try_recall, data)

        if data[:success]
            broadcast "%s disappears!", target({ list: @room.occupants, not: self }), [self]
            room = @game.recall_room( @room.continent )
            move_to_room( room )
            broadcast "%s arrives in a puff of smoke!", target({ list: room.occupants, not: self }), [self]
            return true
        else
            output "#{@deity} has forsaken you."
            return false
        end
    end

    def condition_percent
        (( 100 * @hitpoints ) / maxhitpoints).to_i
    end

    def condition
        percent = condition_percent
        
        data = { percent: percent }
        @game.fire_event( self, :event_show_condition, data )
        percent = data[:percent]

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

    def attack_rating( weapon )
        if proficient( weapon.genre )
            return (15 + (@level * 3 / 2))
        else
            return (15 + (@level * 3 / 2)) / 2
        end
    end

    def defense_rating( element )
        ( -1 * stat( "armor_#{element}".to_sym ) - 100 ) / 5
    end

    def damage_rating(weapon:)
        if proficient( weapon.genre )
            return weapon.damage + stat(:damroll)
        else
            return ( weapon.damage + stat(:damroll) ) / 2
        end
    end

    def to_s
        @short_description
    end

    def long
        data = { description: @long_description }
        @game.fire_event(self, :event_calculate_description, data )
        return data[:description]
    end

    def show_long_description(observer:)
        data = {description: ""}
        @game.fire_event(self, :event_calculate_aura_description, data)
        if self.attacking
            if self.attacking == observer
                return data[:description] + @short_description + " is here, fighting YOU!"
            else
                return data[:description] + @short_description + " is here, fighting #{observer.can_see?(self.attacking) ? self.attacking.name : "someone"}."
            end
        else
            case @position
            when Constants::Position::SLEEP
                return data[:description] + @short_description + " is sleeping here."
            when Constants::Position::REST
                return data[:description] + @short_description + " is resting here."
            else
                return data[:description] + @long_description
            end
        end
    end

    def full
        @full_description
    end

    # returns true if self can see target
    def can_see?(target)
        return true if target == self
        data = {chance: 100, target: target, observer: self}
        @game.fire_event(self, :event_try_can_see, data)
        @game.fire_event(self.room, :event_try_can_see_room, data)        
        @game.fire_event(target, :event_try_can_be_seen, data) if target
        chance = data[:chance]
        if chance >= 100
            return true
        elsif chance <= 0
            return false
        else
            return chance >= dice(1, 100)
        end
    end

    def can_where?(target)
        data = { chance: 100 }
        @game.fire_event(target.room, :event_try_where_room, data)
        @game.fire_event(target, :event_try_where, data)
        chance = data[:chance]
        if chance >= 100
            return true
        elsif chance <= 0
            return false
        else
            return chance >= dice(1, 100)
        end
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
    # Adjusts for
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

    def cast( spell, args, input )
        @casting = spell
        @casting_args = args
        @casting_input = input
    end

    def score
        element_data = {string: ""}
        @game.fire_event( self, :event_display_vulns, element_data)
        @game.fire_event( self, :event_display_resists, element_data)
        @game.fire_event( self, :event_display_immunes, element_data)
        if element_data[:string] == ""
            element_data[:string] = "\nNone."
        end
%Q(#{@short_description}
Member of clan Kenshi
---------------------------------- Info ---------------------------------
{cLevel:{x     #{@level.to_s.lpad(26)} {cAge:{x       17 - 0(0) hours
{cRace:{x      #{@game.race_data.dig(@race_id, :name).to_s.lpad(26)} {cSex:{x       male
{cClass:{x     #{@game.class_data.dig(@class_id, :name).to_s.lpad(26)} {cDeity:{x     #{@deity}
{cAlignment:{x #{@alignment.to_s.lpad(26)} {cDeity Points:{x 0
{cPracs:{x     N/A                        {cTrains:{x    N/A
{cExp:{x       #{"#{@experience} (#{@experience_to_level}/lvl)".lpad(26)} {cNext Level:{x #{@experience_to_level - @experience}
{cQuest Points:{x #{ @quest_points } (#{ @quest_points_to_remort } for remort/reclass)
{cCarrying:{x  #{ "#{@inventory.count} of #{carry_max}".lpad(26) } {cWeight:{x    #{ @inventory.items.map(&:weight).reduce(0, :+).to_i } of #{ weight_max }
{cGold:{x      #{ gold.to_s.lpad(26) } {cSilver:{x    #{ silver.to_s }
---------------------------------- Stats --------------------------------
{cHp:{x        #{"#{@hitpoints} of #{maxhitpoints} (#{@basehitpoints})".lpad(26)} {cMana:{x      #{@manapoints} of #{maxmanapoints} (#{@basemanapoints})
{cMovement:{x  #{"#{@movepoints} of #{maxmovepoints} (#{@basemovepoints})".lpad(26)} {cWimpy:{x     #{@wimpy}
#{score_stat("str")}#{score_stat("con")}
#{score_stat("int")}#{score_stat("wis")}
#{score_stat("dex")}
{cHitRoll:{x   #{ stat(:hitroll).to_s.lpad(26)} {cDamRoll:{x   #{ stat(:damroll) }
{cDamResist:{x #{ stat(:damresist).to_s.lpad(26) } {cMagicDam:{x  #{ stat(:magicdam) }
{cAttackSpd:{x #{ stat(:attack_speed) }
-------------------------------- Elements -------------------------------#{element_data[:string]}
--------------------------------- Armour --------------------------------
{cPierce:{x    #{ (-1 * stat(:ac_pierce)).to_s.lpad(26) } {cBash:{x      #{ -1 * stat(:ac_bash) }
{cSlash:{x     #{ (-1 * stat(:ac_slash)).to_s.lpad(26) } {cMagic:{x     #{ -1 * stat(:ac_magic) }
------------------------- Condition and Affects -------------------------
You are Ruthless.
You are #{Constants::Position::STRINGS[ @position ]}.)
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
        return "{c#{stat_name.capitalize}:{x       #{"#{base}(#{modified}) of #{max}".lpad(27)}"
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
        @race_equip_slots = []  # Clear old equip_slots
        @equip_slots = []
        slots = @game.race_data.dig(@race_id, :equip_slots).to_a
        slots.each do |slot|
            row = @game.equip_slot_data[slot.to_i]
            if row
                @race_equip_slots << EquipSlot.new( slot.to_i, self, @game )
                    # equip_message_self: row[:equip_message_self],
                    #                        equip_message_others: row[:equip_message_others],
                    #                        list_prefix: row[:list_prefix],
                    #                        wear_flag: row[:wear_flag],
                    #                        owner: self,
                    #                        game: @game)
            end
        end
        old_equipment.each do |item| # try to wear all items that were equipped before
            wear(item: item, silent: true)
        end
        @equip_slots = @race_equip_slots + @class_equip_slots
        @race_affects.each do |affect|
            affect.clear(silent: true)
        end
        @race_affects = []
        affect_flags = @game.race_data.dig(@race_id, :affect_flags)
        apply_affect_flags(affect_flags, silent: true, array: @race_affects) if affect_flags
        apply_element_flags(@game.race_data.dig(@race_id, :vuln_flags), AffectVuln, @race_affects)
        apply_element_flags(@game.race_data.dig(@race_id, :resist_flags), AffectResist, @race_affects)
        apply_element_flags(@game.race_data.dig(@race_id, :immune_flags), AffectImmune, @race_affects)
    end

    def set_class_id(new_class_id)
        @class_id = new_class_id
        old_equipment = self.equipment
        old_equipment.each do |item| # move all equipped items to inventory
            item.move(@inventory)
        end
        @class_equip_slots = []  # Clear old equip_slots
        @equip_slots = []
        slots = @game.class_data.dig(@class_id, :equip_slots).to_a
        slots.each do |slot|
            row = @game.equip_slot_data[slot.to_i]
            if row
                @class_equip_slots << EquipSlot.new(equip_message_self: row[:equip_message_self],
                                            equip_message_others: row[:equip_message_others],
                                            list_prefix: row[:list_prefix],
                                            wear_flag: row[:wear_flag],
                                            owner: self,
                                            game: @game)
            end
        end
        old_equipment.each do |item| # try to wear all items that were equipped before
            wear(item: item, silent: true)
        end
        @equip_slots = @race_equip_slots + @class_equip_slots
        @class_affects.each do |affect|
            affect.clear(silent: true)
        end
        @class_affects = []
        affect_flags = @game.class_data.dig(@class_id, :affect_flags)
        apply_affect_flags(affect_flags, silent: true, array: @race_affects) if affect_flags
        apply_element_flags(@game.class_data.dig(@class_id, :vuln_flags), AffectVuln, @class_affects)
        apply_element_flags(@game.class_data.dig(@class_id, :resist_flags), AffectResist, @class_affects)
        apply_element_flags(@game.class_data.dig(@class_id, :immune_flags), AffectImmune, @class_affects)
    end

    def apply_element_flags(element_flags, affect_class, array)
        element_flags.to_a.each do |flag|
            element = Constants::Element::STRINGS.select { |k, v| v == flag }.first
            next if !element
            affect = affect_class.new(nil, self, 0, @game)
            affect.savable = false
            affect.overwrite_data({element: element[0]})
            apply_affect(affect, silent: true)
            array << affect
        end
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

    def do_visible
        remove_affect("invisibility")
        output "You are now visible."
    end

    def carried_by_string
        return "carried by"
    end

end
