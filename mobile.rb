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
    attr_reader :race
    attr_reader :size
    attr_reader :mobile_class
    attr_reader :stats
    attr_reader :hitpoints
    attr_reader :manapoints
    attr_reader :movepoints
    attr_reader :basehitpoints
    attr_reader :basemanapoints
    attr_reader :basemovepoints
    attr_reader :creation_points
    attr_reader :learned_skills
    attr_reader :learned_spells

    include MobileItem

    def initialize( model, room, reset = nil )
        @model = model
        super(nil, @model.keywords, reset)
        @short_description = nil
        @long_description = nil
        @attacking = nil
        @lag = 0
        @id = model.id
        @h2h_equip_slot = EquipSlot.new(self, Game.instance.equip_slot_infos.values.first)

        @learned_skills = []
        @learned_spells = []
        @experience = 0

        @creation_points = 5
        @experience_to_level = 1000
        @quest_points = 0
        @quest_points_to_remort = 1000
        @alignment = model.alignment
        @wealth = model.wealth
        @wimpy = 0
        @active = true
        @group = []
        @in_group = nil
        @deity = "Gabriel".freeze # deity table?

        @gender = model.genders.sample || "neutral".to_gender

        @casting = nil
        @casting_args = nil
        @casting_input = nil

        @stats = {
            success: 100,
            str: model.stats.dig(:str) || 0,
            con: model.stats.dig(:con) || 0,
            int: model.stats.dig(:int) || 0,
            wis: model.stats.dig(:wis) || 0,
            dex: model.stats.dig(:dex) || 0,
            max_str: model.stats.dig(:max_str) || 0,
            max_con: model.stats.dig(:max_con) || 0,
            max_int: model.stats.dig(:max_int) || 0,
            max_wis: model.stats.dig(:max_wis) || 0,
            max_dex: model.stats.dig(:max_dex) || 0,
            hitroll: model.stats.dig(:hitroll) || 6,
            damroll: model.stats.dig(:damroll) || 0,
            attack_speed: 1,
            ac_pierce: model.ac_pierce,
            ac_bash: model.ac_bash,
            ac_slash: model.ac_slash,
            ac_magic: model.ac_magic,
        }

        @level = model.level
        @basehitpoints = model.hp
        @basemanapoints = model.mana
        @basemovepoints = model.movement

        # @damage_range = data[:damage_range] || nil
        # @noun = data[:attack] || nil
        @swing_counter = 0

        @position = model.position

        @inventory = Inventory.new(self)

        @room = room
        @room.mobile_enter(self) if @room
        @race = nil
        @race_equip_slots = []
        @race_affects = []                  # list of affects applied by race
        @mobile_class = nil
        @mobile_class_equip_slots = []
        @mobile_class_affects = []                  # list of affects applied by race

        set_race(model.race)
        set_mobile_class(model.mobile_class)
        @model.affect_models.each do |affect_model|
            apply_affect_model(affect_model, true)
        end

        # wander "temporarily" disabled :)
        @wander_range = 0 # data[:act_flags].to_a.include?("sentinel") ? 0 : 1

        @hitpoints = model.current_hp || maxhitpoints
        @manapoints = model.current_mana || maxmanapoints
        @movepoints = model.current_movement || maxmovepoints

        if model.size
            @size = model.size
        end

    end

    def destroy
        super
        @room.mobile_exit(self) if @room
        @race_affects.clear
        @mobile_class_affects.clear
        self.items.each do |item|
            item.destroy
        end
        if hand_to_hand_weapon
            hand_to_hand_weapon.destroy
        end
        Game.instance.destroy_mobile(self)
    end

    def learn( skill_name )
        skill_name = skill_name.to_s
        unlearned = (spells + skills) - (@learned_skills + @learned_spells)
        unlearned_skills = self.skills - @learned_skills
        unlearned_spells = self.spells - @learned_spells
        if skill_name.nil? || skill_name.to_s.length <= 0 # no argument - list learnable skills
            output "\n" + ("{GCOST : SKILL{x\n" * 3).to_columns( 30, 3 )
            output unlearned_skills.map{ |skill| "#{ skill.creation_points.to_s.rpad(4) } : #{skill.name}" }.join("\n").to_columns( 30, 3 )
            output "\n" + ("{CCOST : SPELL{x\n" * 3).to_columns( 30, 3 )
            output unlearned_spells.map{ |spell| "#{ spell.creation_points.to_s.rpad(4) } : #{spell.name}" }.join("\n").to_columns( 30, 3 )
            output "\nYou have #{ (@creation_points > 0) ? "{g" : "{D" }#{ @creation_points }{x creation points available to spend."
            return
        end
        # try to learn
        to_learn = unlearned.find { |skill| skill.name.fuzzy_match(skill_name) }
        if to_learn
            if to_learn.creation_points <= @creation_points
                if to_learn.is_a? Skill
                    @learned_skills << to_learn
                else
                    @learned_spells << to_learn
                end
                @creation_points -= to_learn.creation_points
                output "You have learned #{ to_learn.name }!"
            else
                output "You don't have enough creation points to learn that skill.  You have #{ @creation_points } and need at least #{ to_learn.creation_points }."
            end
        else
            output "You cannot learn that skill!"
        end
    end

    def knows( ability )
        (@learned_skills | @learned_spells).include? ability
    end

    def proficient( genre )
        result = @race.genres.include?(genre) || @mobile_class.genres.include?(genre)
        return result
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

    def update( elapsed )
        # super elapsed

        # wander
        if attacking.nil? && @position == :standing && rand(1..1200) == 1 && @wander_range > 0
            if ( direction = @room.exits.reject{ |k, v| v.nil? }.keys.sample )
                if ( destination = @room.exits[direction].destination ) && destination.area == @room.area
                    move( direction )
                end
            end
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
        Game.instance.do_command( self, cmd, args.to_s.scan(/(((\d+|all)\*)?((\d+|all)\.)?([^\s\.\'\*]+|'[\w\s]+'?))/i).map(&:first).map{ |arg| arg.gsub("'", "") }, input )
        # Game.instance.do_command( self, cmd, args.to_s.scan(/(((\d+|all)\*)?((\d+|all)\.)?(\w+|'[\w\s]+'))/i).map(&:first).map{ |arg| arg.gsub("'", "") } )
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
            AffectKiller.new(nil, self, 0).apply if attacker.is_player?
            do_command "yell Help I am being attacked by #{attacker}!"
        end
        old_position = @position
        @position = :standing.to_position
        if old_position == :sleeping
            look_room
        end
        if @attacking.nil?
            @attacking = attacker
        end

        Game.instance.fire_event( self, :event_on_start_combat, {} )
        Game.instance.add_combat_mobile(self)
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
        Game.instance.remove_combat_mobile(self)
        target({ attacking: self, list: @room.occupants }).each do |t|
            attacking_t = target({ quantity: "all", attacking: t, list: t.room.occupants })
            if attacking_t.size > 0
                t.attacking = attacking_t.first
            else
                Game.instance.remove_combat_mobile(t)
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
        Game.instance.fire_event( self, :event_calculate_regeneration, data )
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

    # Gets a single weapon in wielded slot, cycling on each hit, or hand to hand
    def weapon_for_next_hit
        weapons = wielded
        case weapons.length
        when 0 # hand to hand
            return self.hand_to_hand_weapon
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

    # Generate hand to hand weapon.
    def generate_hand_to_hand_weapon
        if @h2h_equip_slot.item
            @h2h_equip_slot.item.destroy
        end
        weapon_row = {
            id: 0,
            name: "hand to hand",
            short_description: "hand to hand",
            keywords: "",
            level: @level,
            weight: 0,
            cost: 0,
            material: "flesh",
            fixed: 0,

            noun: @race.hand_to_hand_noun,
            genre: "hand to hand".to_genre,
            dice_count: @model.hand_to_hand_dice_count || 6,
            dice_sides: @model.hand_to_hand_dice_sides || 7
        }
        h2h_model = WeaponModel.new(0, weapon_row)
        @race.hand_to_hand_affect_models.each do |affect_model|
            h2h_model.affect_models << affect_model
        end

        weapon = Weapon.new(h2h_model, @h2h_equip_slot)
        return weapon
    end

    #
    def hand_to_hand_weapon
        if !@h2h_equip_slot.item
            self.generate_hand_to_hand_weapon
        end
        return @h2h_equip_slot.item
    end

    # do a round of attacks against a target
    def do_round_of_attacks(target: nil)
        if !target
            target = @attacking
        end
        stat( :attack_speed ).times do |attack|
            weapon_hit(target) if target.attacking
        end
    end

    # Hit a target using weapon for damage
    def weapon_hit(target, damage_bonus = 0, hit_bonus = 0, custom_noun = nil, weapon = nil, noun_name_override = nil)

        # get data from weapon item or hand-to-hand

        weapon = weapon || weapon_for_next_hit
        noun = custom_noun || weapon.noun
        noun = noun.to_noun
        hit = false

        # check for override event - i.e. burst rune

        override = { confirm: false, source: self, target: target, weapon: weapon }
        Game.instance.fire_event( self, :event_override_hit, override )
        if override[:confirm]
            return
        end
        # calculate hit chance ... I guess burst rune auto-hits?
        hit_chance = (hit_bonus + attack_rating( weapon ) - target.defense_rating( weapon.noun.element ) ).clamp( 5, 95 )
        if rand(0...100) < hit_chance
            damage = damage_rating(weapon: weapon) + damage_bonus + (self.stat(:damroll) * Constants::Damage::DAMROLL_MODIFIER).to_i
            hit = true
        else
            damage = 0
        end

        # modify hit damage
        data = { damage: damage, source: self, target: target, weapon: weapon }
        Game.instance.fire_event( self, :event_calculate_weapon_hit_damage, data )
        damage = data[:damage].to_i

        deal_damage(target, damage, noun, false, false, noun_name_override)

        if hit
            override = { confirm: false, source: self, target: target, weapon: weapon }
            Game.instance.fire_event( target, :event_override_receive_hit, override )
            if override[:confirm]
                return
            end
            data = { damage: damage, source: self, target: target, weapon: weapon }
            Game.instance.fire_event(self, :event_on_hit, data)
        end

    end

    # Deal some damage to a mobile.
    # +target+:: the mobile who will be receiving the damage
    # +damage+:: the amount of damage being dealt
    # +noun+:: the noun of the damage (flamestirke, fire, magic)
    # +silent+:: true if damage decorators should not be broadcast
    # +anonymous+:: true if output messages should omit the +source+
    # +noun_name_override+ override the given noun's name with this string, "backstab" for example
    #  mob1.deal_damage(mob2, 60, "stab")
    #  mob1.deal_damage(mob2, 10, "bleeding", true, true)
    def deal_damage(target, damage, noun = "hit", silent = false, anonymous = false, noun_name_override = nil)
        if !target || !target.active # if this is inactive, it can still deal damage
            return
        end
        noun = noun.to_noun
        calculation_data = { source: self, target: target, damage: damage, noun: noun }
        Game.instance.fire_event(self, :event_calculate_damage, calculation_data)
        damage = calculation_data[:damage]
        target.receive_damage(self, damage, noun, silent, anonymous, noun_name_override)
    end

    # Receive some damage!
    # +source+:: the mobile dealing the damage (can be nil)
    # +damage+:: the amount of damage being dealt
    # +noun+:: the element of the damage (flamestirke, fire, magic)
    # +silent+:: true if damage decorators should not be broadcast
    # +anonymous+:: true if output messages should omit the +source+
    # +noun_name_override+ override the given noun's name with this string, "backstab" for example
    def receive_damage(source, damage, noun = "hit", silent = false, anonymous = false, noun_name_override = nil)
        if !@active # inactive mobiles can't take damage.
            return
        end
        noun = noun.to_noun
        if source && source != self
            self.start_combat( source )
        end
        override = { confirm: false, source: source, target: self, damage: damage, noun: noun }
        Game.instance.fire_event(self, :event_override_receive_damage, override)
        if override[:confirm]
            return
        end
        calculation_data = { source: source, target: self, damage: damage, noun: noun }
        Game.instance.fire_event(self, :event_calculate_receive_damage, calculation_data)
        damage = calculation_data[:damage]
        resistance = self.resistances[noun.element]
        noun_name = noun_name_override || noun.name
        if resistance >= 1.0 # immune!
            if !silent
                if source && !anonymous
                    (self.room.occupants | [source]).each_output "0<N>'s #{noun_name} doesn't even bruise #{(source==self) ?"1<r>":"1<n>"}!", [source, self]
                else # anonymous damage
                    self.room.occupants.each_output("#{noun_name} doesn't even bruise 0<n>!", [self])
                end
            end
            return # immunity means we stop here!
        end
        damage = (damage * (1.0 - resistance)).to_i
        if !silent
            decorators = Constants::DAMAGE_DECORATORS
            if noun.magic
                decorators = Constants::MAGIC_DAMAGE_DECORATORS
            end
            decorators = decorators.select{ |key, value| damage <= key}.values.first
            if source && !anonymous
                (self.room.occupants | [source]).each_output "0<N>'s#{decorators[2]} #{noun_name} #{decorators[1]} #{(source==self) ?"1<r>":"1<n>"}#{decorators[3]}", [source, self]
            else # anonymous damage
                self.room.occupants.each_output("#{noun_name} #{decorators[1]} 0<n>#{decorators[3]} ", [self])
            end
        end
        @hitpoints -= damage
        die( source ) if @hitpoints <= 0
    end

    def level_up
        self.generate_hand_to_hand_weapon
        @experience = (@experience - @experience_to_level)
        @level += 1
        @basehitpoints += 20
        @basemanapoints += 10
        @basemovepoints += 10
        @creation_points += 1
        output "You raise a level!!  You gain 20 hit points, 10 mana, 10 move, and 0 practices."
        output "You have gained 1 creation points.  Maybe you can get a new skill??"
        Game.instance.fire_event(self, :event_on_level_up, {level: @level})
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

    def qp( target )
        if !@active
            return
        end
        dlevel = [target.level - @level, -10].max
        base_qp = dlevel <= 5 ? Constants::EXPERIENCE_SCALE[dlevel] : ( 180 + 12 * (dlevel - 5 ))
        base_qp *= 10  / ( @level + 4 ) if @level < 6
        base_qp = rand(base_qp..(5 * base_qp / 4))
        @quest_points = @quest_points.to_i + base_qp.to_i
        output "You receive #{base_qp} experience points."
    end

    def die( killer )
        if !@active
            return
        end
        (@room.occupants - [self]).each_output "0<N> is DEAD!!", [self]
        Game.instance.fire_event( self, :event_on_die, { died: self, killer: killer } )

        @affects.each do |affect|
            affect.clear(true)
        end
        killer.xp( self ) if killer
        (@room.occupants - [self]).each_output "0<N>'s head is shattered, and 0<p> brains splash all over you.", [self]
        if killer
            self.items.each do |item|
                killer.get_item(item)
            end
            killer.output("You get #{ self.wealth.to_worth } from the corpse of 0<n>.", [self])
            killer.output("You offer your victory to #{@deity} who rewards you with 1 deity points.")
            killer.earn( @wealth )
        end
        stop_combat
        if @reset
            @reset.activate
            @reset = nil
        end
        destroy
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
            (@room.occupants - [self]).each_output "0<N> leaves #{direction}.", [self] unless self.affected? "sneak"
            Game.instance.fire_event(self, :event_mobile_exit, { mobile: self, direction: direction })
            old_room = @room
            if @room.exits[direction.to_sym].move( self )
                (@room.occupants - [self]).each_output "0<N> has arrived.", [self] unless self.affected? "sneak"
                (old_room.occupants - [self]).select { |t| t.position == :sleeping }.each do |t|
                    Game.instance.fire_event( t, :event_observe_mobile_exit, {mobile: self, direction: direction } )
                end
                Game.instance.fire_event( self, :event_mobile_enter, { mobile: self } )
                (@room.occupants - [self]).each do |t|
                    Game.instance.fire_event( t, :event_observe_mobile_enter, {mobile: self} )
                end
                return true
            else
                return false
            end
        end
    end

    def look_room
        Game.instance.do_command self, "look"
    end

    def who
        auras = self.short_auras
        "[#{@level.to_s.lpad(2)} #{@race.display_name.rpad(8)} #{@mobile_class.name.capitalize.lpad(8)}] #{auras}#{self.name}"
    end

    def genres
        @mobile_class.genres | @race.genres
    end

    def move_to_room( room )
        if @attacking && @attacking.room != room
            stop_combat
        end
        @room&.mobile_exit(self)
        @room = room
        if @room
            @room.mobile_enter(self)
            if @position == :sleeping
                output "Your dreams grow restless."
            else
                Game.instance.do_command self, "look"
            end
        end
    end

    def recall
        @room.occupants.each_output "0<N> pray0<,s> for transportation!", [self]
        data = { mobile: self, success: true }
        Game.instance.fire_event(self, :event_try_recall, data)

        if data[:success]
            (@room.occupants - [self]).each_output "0<N> disappears!", [self]
            room = Game.instance.rooms[@room.continent.recall_room_id]
            move_to_room( room )
            (@room.occupants - [self]).each_output "0<N> arrives in a puff of smoke!", [self]
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
        Game.instance.fire_event( self, :event_show_condition, data )
        percent = data[:percent]

        if (percent >= 100)
            return "#{self.name.capitalize_first} is in excellent condition.\n"
        elsif (percent >= 90)
            return "#{self.name.capitalize_first} has a few scratches.\n"
        elsif (percent >= 75)
            return "#{self.name.capitalize_first} has some small wounds and bruises.\n"
        elsif (percent >= 50)
            return "#{self.name.capitalize_first} has quite a few wounds.\n"
        elsif (percent >= 30)
            return "#{self.name.capitalize_first} has some big nasty wounds and scratches.\n"
        elsif (percent >= 15)
            return "#{self.name.capitalize_first} looks pretty hurt.\n"
        elsif (percent >= 0)
            return "#{self.name.capitalize_first} is in awful condition.\n"
        else
            return "#{self.name.capitalize_first} is bleeding to death.\n"
        end
    end

    def attack_rating( weapon )
        if proficient( weapon.genre )
            return stat(:hitroll) + (15 + (@level * 3 / 2))
        else
            return stat(:hitroll) + (15 + (@level * 3 / 2)) * 0.7  # attacking with unfamiliar weapon has a 30% hit chance penalty
        end
    end

    def defense_rating( element )
        ( -1 * stat( "armor_#{element}".to_sym ) - 100 ) / 5
    end

    def damage_rating(weapon:)
        if proficient( weapon.genre )
            return weapon.damage + stat(:damroll) + strength_to_damage
        else
            return ( weapon.damage + stat(:damroll) + strength_to_damage ) / 2
        end
    end

    def strength_to_damage
        ( 0.5 * stat(:str) - 6 ).to_i
    end

    def to_s
        self.name.to_s
    end

    def short_description
        data = { description: self.short_description }
        Game.instance.fire_event(self, :event_calculate_description, data )
        return data[:description]
    end

    def show_short_description(observer:)
        data = {description: ""}
        auras = self.long_auras
        if self.attacking
            if self.attacking == observer
                return auras + self.name + " is here, fighting YOU!"
            else
                return auras + self.name + " is here, fighting #{observer.can_see?(self.attacking) ? self.attacking.name : "someone"}."
            end
        else
            case @position.name
            when :sleeping
                return auras + self.name + " is sleeping here."
            when :resting
                return auras + self.name + " is resting here."
            else
                return auras + self.short_description
            end
        end
    end

    def name
        (@name || @model.name)
    end

    def short_description
        (@short_description || @model.short_description)
    end

    def long_description
        (@long_description || @model.long_description)
    end

    # returns true if self can see target
    def can_see?(target)
        return true if target == self
        data = {chance: 100, target: target, observer: self}
        Game.instance.fire_event(self, :event_try_can_see, data)
        Game.instance.fire_event(self.room, :event_try_can_see_room, data)
        Game.instance.fire_event(target, :event_try_can_be_seen, data) if target
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
        Game.instance.fire_event(target.room, :event_try_where_room, data)
        Game.instance.fire_event(target, :event_try_where, data)
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
        @basehitpoints + @level * ( 10 + ( stat(:wis) / 5 ).to_i + ( stat(:con) / 2 ).to_i )
    end

    def maxmanapoints
        @basemanapoints + @level * ( 10 + ( stat(:wis) / 5 ).to_i + ( stat(:int) / 3 ).to_i )
    end

    def maxmovepoints
        @basemovepoints + @level * ( 10 + ( stat(:wis) / 5 ).to_i + ( stat(:dex) / 3 ).to_i )
    end

    # Returns the value of a stat for a given key.
    # Adjusts for
    #
    #  some_mobile.stat(:str)
    #  some_mobile.stat(:max_wis)
    #  some_mobile.stat(:damroll)
    def stat(key)
        stat = @race.stats.dig(key).to_i + @stats[key].to_i

        if key == @mobile_class.main_stat # class main stat bonus
            stat += 3
        end
        if key.to_s == "max_#{@mobile_class.main_stat}" # class max main stat bonus
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
        resist_string = "None."
        resist_strings = []
        resists = self.resistances.select { |element, value| value != 0 }.sort_by{ |element, value| value }
        resists.each do |element, value|
            case
            when value == 1
                resist_strings << "You are immune to #{element.name} damage."
            when value > 0
                resist_strings << "You are resistant to #{element.name} damage."
            when value < 0
                resist_strings << "You are vulnerable to #{element.name} damage."
            end
        end
        if resist_strings.size > 0
            resist_string = resist_strings.join("\n")
        end

%Q(#{self.name}
Member of clan Kenshi
---------------------------------- Info ---------------------------------
{cLevel:{x     #{@level.to_s.rpad(26)} {cAge:{x       17 - 0(0) hours
{cRace:{x      #{@race.name.to_s.rpad(26)} {cGender:{x    #{@gender.name}
{cClass:{x     #{@mobile_class.name.to_s.rpad(26)} {cDeity:{x     #{@deity}
{cAlignment:{x #{@alignment.to_s.rpad(26)} {cDeity Points:{x 0
{cPracs:{x     N/A                        {cTrains:{x    N/A
{cExp:{x       #{"#{@experience} (#{@experience_to_level}/lvl)".rpad(26)} {cNext Level:{x #{@experience_to_level - @experience}
{cQuest Points:{x #{ @quest_points } (#{ @quest_points_to_remort } for remort/reclass)
{cCarrying:{x  #{ "#{@inventory.count} of #{carry_max}".rpad(26) } {cWeight:{x    #{ @inventory.items.map(&:weight).reduce(0, :+).to_i } of #{ weight_max }
{cGold:{x      #{ @wealth.gold.to_s.rpad(26) } {cSilver:{x    #{ @wealth.silver.to_s }
---------------------------------- Stats --------------------------------
{cHp:{x        #{"#{@hitpoints} of #{maxhitpoints} (#{@basehitpoints})".rpad(26)} {cMana:{x      #{@manapoints} of #{maxmanapoints} (#{@basemanapoints})
{cMovement:{x  #{"#{@movepoints} of #{maxmovepoints} (#{@basemovepoints})".rpad(26)} {cWimpy:{x     #{@wimpy}
#{score_stat("str")}#{score_stat("con")}
#{score_stat("int")}#{score_stat("wis")}
#{score_stat("dex")}
{cHitRoll:{x   #{ stat(:hitroll).to_s.rpad(26)} {cDamRoll:{x   #{ stat(:damroll) }
{cDamResist:{x #{ stat(:damresist).to_s.rpad(26) } {cMagicDam:{x  #{ stat(:magicdam) }
{cAttackSpd:{x #{ stat(:attack_speed) }
-------------------------------- Elements -------------------------------
#{resist_string}
--------------------------------- Armour --------------------------------
{cPierce:{x    #{ (-1 * stat(:ac_pierce)).to_s.rpad(26) } {cBash:{x      #{ -1 * stat(:ac_bash) }
{cSlash:{x     #{ (-1 * stat(:ac_slash)).to_s.rpad(26) } {cMagic:{x     #{ -1 * stat(:ac_magic) }
------------------------- Condition and Affects -------------------------
You are Ruthless.
You are #{@position.name}.)
    end

    # Take a stat name as a string and convert it into a score-formatted output string.
    #
    #  score_stat("str")     # => Str:       14(14) of 23
    def score_stat(stat_sym)
        stat_sym = stat_sym.to_sym
        max_stat = "max_#{stat_sym}".to_sym
        base = @stats[stat_sym] + @race.stats[stat_sym].to_i
        base += 3 if @mobile_class.main_stat == stat_sym
        modified = stat(stat_sym)
        max = stat(stat_sym)
        return "{c#{stat_sym.to_s.capitalize}:{x       #{"#{base}(#{modified}) of #{max}".rpad(27)}"
    end

    def skills
        return (@race.skills | @mobile_class.skills)
    end

    def spells
        return (@race.spells | @mobile_class.spells)
    end

    def resistances
        element_data = Game.instance.elements.values.map { |e| [e, 0] }.to_h
        Game.instance.fire_event(self, :event_get_resists, element_data)
        return element_data
    end

    def set_race(race)
        @race = race
        @size = race.size
        old_equipment = self.equipment
        old_equipment.each do |item| # move all equipped items to inventory
            get_item(item, silent: true)
        end
        @race_equip_slots = []  # Clear old equip_slots

        @race.equip_slot_infos.each do |slot|
            @race_equip_slots << EquipSlot.new(self, slot)
        end
        old_equipment.each do |item| # try to wear all items that were equipped before
            wear(item: item, silent: true)
        end
        @race_affects.each do |affect|
            affect.clear(true)
        end
        @race_affects = []
        @race.affect_models.each do |affect_model|
            apply_affect_model(affect_model, true, @race_affects)
        end
    end

    def set_mobile_class(mobile_class)
        @mobile_class = mobile_class
        old_equipment = self.equipment
        old_equipment.each do |item| # move all equipped items to inventory
            get_item(item, silent: true)
        end
        @mobile_class_equip_slots = []  # Clear old equip_slots
        @mobile_class.equip_slot_infos.each do |slot|
            @race_equip_slots << EquipSlot.new(self, slot)
        end
        old_equipment.each do |item| # try to wear all items that were equipped before
            wear(item: item, silent: true)
        end
        @mobile_class_affects.each do |affect|
            affect.clear(true)
        end
        @mobile_class_affects = []
        @mobile_class.affect_models.each do |affect_model|
            apply_affect_model(affect_model, true, @mobile_class_affects)
        end
    end

    def is_player?
        return false
    end

    def casting_level
        class_multiplier = @mobile_class.casting_multiplier
        casting = @level
        casting = (casting * class_multiplier).to_i if class_multiplier
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

    def indefinite_name
        return "someone"
    end

    def indefinite_short_description
        return "someone"
    end

    def indefinite_long_description
        return "someone"
    end

    # %O -> personal_objective_pronoun (him, her, it)
    def indefinite_personal_objective_pronoun
        return "them"
    end

    # %U -> personal_subjective_pronoun (he, she, it)
    def indefinite_personal_subjective_pronoun
        return "they"
    end

    # %P -> possessive_pronoun (his, her, its)
    def indefinite_possessive_pronoun
        return "their"
    end

    # %R -> reflexive_pronoun (himself, herself, itself)
    def indefinite_reflexive_pronoun
        return "themself"
    end

end
