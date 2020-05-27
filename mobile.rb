require_relative 'mobile_item'

class Mobile < GameObject

    attr_accessor :id
    attr_accessor :attacking
    attr_accessor :lag
    attr_accessor :position
    attr_accessor :inventory
    attr_accessor :active
    attr_accessor :level
    attr_accessor :in_group
    attr_accessor :experience
    attr_accessor :quest_points
    attr_accessor :alignment
    attr_accessor :wealth
    attr_accessor :health
    attr_accessor :mana
    attr_accessor :movement

    attr_reader :race
    attr_reader :size
    attr_reader :mobile_class
    attr_reader :stats
    attr_reader :creation_points
    attr_reader :learned_skills
    attr_reader :learned_spells
    attr_reader :experience_to_level

    include MobileItem

    def initialize( model, room, reset = nil )
        @model = model
        super(nil, nil, reset, @model)
        @short_description = nil
        @long_description = nil
        @attacking = nil
        @lag = 0
        @id = model.id
        @h2h_equip_slot = EquipSlot.new(self, Game.instance.equip_slot_infos.values.first)

        @learned_skills = model.learned_skills
        @learned_spells = model.learned_spells
        @experience = 0

        @base_health = model.base_health
        @base_mana = model.base_mana
        @base_movement = model.base_movement
        @base_armor_class = model.base_armor_class

        @creation_points = 5
        @experience_to_level = 1000
        @quest_points = 0
        @quest_points_to_remort = 1000
        @alignment = model.alignment
        @wealth = model.wealth
        @wimpy = 0
        @active = true
        @group = nil
        @in_group = nil
        @deity = "Gabriel".freeze # deity table?

        @gender = model.genders.to_a.sample || :neutral.to_gender

        @casting = nil
        @casting_args = nil
        @casting_input = nil

        @stats = nil
        @stats = model.stats if model.stats

        @level = model.level

        # @damage_range = data[:damage_range] || nil
        # @noun = data[:attack] || nil
        @swing_counter = 0

        @position = model.position

        @inventory = Inventory.new(self)

        @room = room
        @room.mobile_enter(self) if @room
        @race = nil
        @race_equip_slots = nil
        @race_affects = nil                  # list of affects applied by race
        @mobile_class = nil
        @mobile_class_equip_slots = nil
        @mobile_class_affects = nil                  # list of affects applied by race

        @health = 0
        @mana = 0
        @mana = 0
        set_race(model.race)
        set_mobile_class(model.mobile_class)
        @model.affect_models.to_a.each do |affect_model|
            apply_affect_model(affect_model, true)
        end

        # wander "temporarily" disabled :)
        @wander_range = 0 # data[:act_flags].to_a.include?("sentinel") ? 0 : 1

        @health = (@max_health = max_health)
        @mana = (@max_mana = max_mana)
        @movement = (@max_movement = max_movement)

        @health_regen_rollover = 0.0
        @mana_regen_rollover = 0.0
        @movement_regen_rollover = 0.0

        @attack_speed_rollovers = nil

        if model.size
            @size = model.size
        end
    end

    def destroy
        Game.instance.remove_regen_mobile(self)
        Game.instance.remove_combat_mobile(self)
        Game.instance.destroy_mobile(self)
        if @reset
            @reset.activate
            @reset = nil
        end
        @room.mobile_exit(self) if @room
        @race_affects = nil
        @mobile_class_affects = nil
        self.items.dup.each do |item|
            item.destroy
        end
        if @h2h_equip_slot.item
            @h2h_equip_slot.item.destroy
        end
        @inventory = nil
        super
    end

    def room
        return @room || Room.inactive_room
    end

    def learn( skill_name )
        skill_name = skill_name.to_s
        unlearned = (spells + skills) - (@learned_skills.to_a + @learned_spells.to_a)
        unlearned_skills = self.skills - @learned_skills.to_a
        unlearned_spells = self.spells - @learned_spells.to_a
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
                if to_learn.is_a?(Spell)
                    if @learned_spells
                        @learned_spells.to_a << to_learn
                    else
                        @learned_spells = [to_learn]
                    end
                else
                    if @learned_skills
                        @learned_skills.to_a << to_learn
                    else
                        @learned_skills = [to_learn]
                    end
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

    def group
        @group || ( @group = Group.new( self ))
    end

    def leave_group
        @group.joined.each_output "{C0<N>{x 0<have,has> left the group.", [self]
        @group.joined.delete self
        @group = nil
    end

    def join_group( group )
        group.invited.delete( self )
        group.joined << self
        @group = group
        @group.joined.each_output "{C0<N>{x 0<have,has> joined the group!", [self]
    end

    def knows( ability )
        (@learned_skills.to_a | @learned_spells.to_a).include? ability
    end

    def proficient( genre )
        result = @race.genres.include?(genre) || @mobile_class.genres.include?(genre)
        return result
    end

    def proficiencies
        ( @race.genres + @mobile_class.genres ).uniq
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
            if ( exit = @room.exits.sample)
                destination = exit.destination
                direction = exit.direction
                if direction && destination && destination.area == @room.area
                    move( direction )
                end
            end
        end
    end

    def use_hp( n )
        success = (n <= @health) ? (@health -= n) : false
        try_add_to_regen_mobs
        return success
    end

    def use_mana( n )
        success = (n <= @mana) ? (@mana -= n) : false
        try_add_to_regen_mobs
        return success
    end

    def use_movement( n )
        success = (n <= @movement) ? (@movement -= n) : false
        try_add_to_regen_mobs
        return success
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
            group_string += "Your group:\n\n"
            group_string += self.group_desc + "\n"
            self.group.each do |target|
                group_string += target.group_desc + "\n"
            end
        elsif !self.in_group.nil?
            group_string += "#{self.in_group}'s group:\n\n"
            group_string += self.in_group.group_desc + "\n"
            self.in_group.group.each do |target|
                group_string += target.group_desc + "\n"
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
        matches = Game.instance.find_commands( self, cmd )

        if matches.any?
            command = matches.last
            success = command.execute( self, cmd, args.to_s.to_args, input )
            if success
                if @lag
                    @lag += command.lag
                else
                    @lag = Game.instance.frame_time + command.lag
                end
            end
            return
        end
        output "Huh?"
    end

    # When mobile is attacked, respond automatically unless already in combat targeting someone else
    #
    # When calling 'start_combat', call it first for the 'victim', then for the attacker

    def start_combat( attacker )
        if !@active || !attacker.active || !@room.contains?(attacker) || attacker == self
            return
        end

        # only the one being attacked
        if attacker.attacking != self && @attacking != attacker && is_player?
            AffectKiller.new(self).apply if attacker.is_player?
            do_command "yell Help I am being attacked by #{attacker}!" if self.is_player?
        end

        old_position = @position
        @position = :standing.to_position
        if old_position == :sleeping
            look_room
        end
        if @attacking.nil?
            @attacking = attacker
        end

        Game.instance.fire_event( self, :event_on_start_combat, nil )
        Game.instance.add_combat_mobile(self)
        attacker.start_combat( self ) if attacker.attacking.nil?

        # bring in group members
        if !@group.nil?
            @group.joined.each do |member|
                attacker.start_combat( member ) if member.attacking.nil? && member.room == attacker.room
            end
        end
    end

    # sets mobiles attacking target to 'nil', so 'combat' method will no longer call a round of attacks
    #
    # then iterates through all room occupants that were targeting 'self' in combat and sets them to attack the next
    # mobile that is currently in combat with THEM
    #
    # if no new combatant is found, the new target is set to 'nil' which stops combat as well

    def stop_combat
        @attacking = nil
        @attack_speed_rollovers = nil
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

    def restore
        Game.instance.remove_regen_mobile(self)
        @health = (@max_heath = max_health)
        @mana = (@max_mana = max_mana)
        @movement = (@max_movement = max_movement)
    end

    def regen( hp, mp, mv )
        # max_health = nil
        # max_mana = nil
        # max_movement = nil
        if responds_to_event(:event_calculate_regeneration)
            data = { hp: hp, mp: mp, mv: mv, mobile: self }
            Game.instance.fire_event( self, :event_calculate_regeneration, data )
            Game.instance.fire_event( self.room, :event_calculate_regeneration, data )
            hp, mp, mv = data.values
        end

        if hp > 0 && @health < @max_health
            # max_health = self.max_health
            @health += hp
            if @health > @max_health
                @health = @max_health
            end
        end
        if mp > 0 && @mana < @max_mana
            @mana += mp
            if @mana > @max_mana
                @mana = @max_mana
            end
        end
        if mv > 0 && @movement < @max_movement
            @movement += mv
            if @movement > @max_movement
                @movement = @max_movement
            end
        end

        if @health == @max_health && @mana == @max_mana && @movement == @max_movement
            Game.instance.remove_regen_mobile(self)
        end
    end

    def update_snapshot
        @max_health = self.max_health
        @max_mana = self.max_mana
        @max_movement = self.max_movement
    end

    def try_add_to_regen_mobs
        self.update_snapshot
        if @health != @max_health || @mana != @max_mana || @movement != @max_movement
            Game.instance.add_regen_mobile(self)
        else
            Game.instance.remove_regen_mobile(self)
        end
    end

    def combat
        if @attacking && @active && @attacking.active
            do_round_of_attacks(@attacking)
        end
    end

    def combat_regen
        health_to_regen = 0
        mana_to_regen = 0
        moves_to_regen = 0

        if @health < @max_health

            health_to_regen = [0.25, 0.0025 * @max_health].max
            healing_rate = [0.05, stat(:constitution) / 40.0 + @level / 80.0].max
            bonus_multiplier = room.hp_regen
            if responds_to_event(:event_calculate_bonus_health_regen)
                data = {bonus: bonus_multiplier}
                Game.instance.fire_event(self, :event_calculate_bonus_health_regen, data)
                bonus_multiplier = data[:bonus]
            end
            health_to_regen += (healing_rate * bonus_multiplier)
            health_to_regen *= @position.regen_multiplier
            @health_regen_rollover += health_to_regen
        elsif @health > @max_health
            @health -= 1
        end

        if @mana < @max_mana
            mana_to_regen = [0.50, 0.0025 * @max_mana].max
            healing_rate = [0.10, stat(:intelligence) / 40.0 + stat(:wisdom) / 40.0 + @level / 200.0].max
            bonus_multiplier = room.mana_regen
            if responds_to_event(:event_calculate_bonus_mana_regen)
                data = {bonus: bonus_multiplier}
                Game.instance.fire_event(self, :event_calculate_bonus_mana_regen, data)
                bonus_multiplier = data[:bonus]
            end
            mana_to_regen += (healing_rate * bonus_multiplier)
            mana_to_regen *= @position.regen_multiplier
            @mana_regen_rollover += mana_to_regen
        elsif @mana > @max_mana
            @mana -= 1
        end

        if @movement < @max_movement
            movement_to_regen = [1, 0.004 * @max_movement].max
            healing_rate = [0.25, stat(:strength) / 40.0 + @level / 60.0].max
            bonus_multiplier = room.hp_regen
            if responds_to_event(:event_calculate_bonus_movement_regen)
                data = {bonus: bonus_multiplier}
                Game.instance.fire_event(self, :event_calculate_bonus_movement_regen, data)
                bonus_multiplier = data[:bonus]
            end
            movement_to_regen += (healing_rate * bonus_multiplier)
            movement_to_regen *= @position.regen_multiplier
            @movement_regen_rollover += movement_to_regen
        elsif @movement > @max_movement
            @movement -= 1
        end

        # regen floor value
        regen(@health_regen_rollover.to_i, @mana_regen_rollover.to_i, @movement_regen_rollover.to_i)

        # save remainder for next time
        @health_regen_rollover -= @health_regen_rollover.to_i
        @mana_regen_rollover -= @mana_regen_rollover.to_i
        @movement_regen_rollover -= @movement_regen_rollover.to_i
    end

    # Gets a single weapon in wielded slot, cycling on each hit, or hand to hand
    def weapon_for_next_hit
        weapons = equipped(Weapon)
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
            material: :flesh.to_material,
            fixed: 0,

            noun: @race.hand_to_hand_noun,
            genre: :hand_to_hand.to_genre,
            # 9d3(22.5) at 51
            dice_count: @model.hand_to_hand_dice_count || (@level * 9 / 51).to_i,
            dice_sides: @model.hand_to_hand_dice_sides || 4,
            affect_models: @race.hand_to_hand_affect_models
        }
        h2h_model = WeaponModel.new(0, weapon_row)
        # @race.hand_to_hand_affect_models.each do |affect_model|
        #     h2h_model.affect_models << affect_model
        # end
        weapon = Weapon.new(h2h_model, @h2h_equip_slot)
        return weapon
    end

    def weapons
        items = equipped(Weapon)
        if items.empty?
            items = [self.hand_to_hand_weapon]
        end
        return items
    end

    def attack_speeds
        weapons = self.weapons
        multiplier = (1.0 + stat(:attack_speed).to_f / 100.0)
        speeds = weapons.map{ |weapon| [weapon, multiplier * weapon.attack_speed / weapons.size] }.to_h
        return speeds
    end

    #
    def hand_to_hand_weapon
        if !@h2h_equip_slot.item
            self.generate_hand_to_hand_weapon
        end
        return @h2h_equip_slot.item
    end

    # do a round of attacks against a target
    def do_round_of_attacks(target = nil)
        if !target
            target = @attacking
        end
        attack_speeds = self.attack_speeds
        weapons = equipped(Weapon)
        if !@attack_speed_rollovers || @attack_speed_rollovers.keys != attack_speeds.keys
            @attack_speed_rollovers = {}
            attack_speeds.each_with_index do |pair, index|
                staggered_multiplier = (attack_speeds.size - index).to_f / attack_speeds.size.to_f
                speed = pair[1] * staggered_multiplier
                if index == 0
                    speed = [speed, 1].max
                end
                @attack_speed_rollovers[pair[0]] = speed
            end
        else
            attack_speeds.each do |weapon, speed|
                @attack_speed_rollovers[weapon] += speed
            end
        end
        @attack_speed_rollovers.each do |weapon, speed|
            speed.to_i.times do
                weapon_hit(target, 0, 0, nil, weapon)
            end
            @attack_speed_rollovers[weapon] -= speed.to_i
        end
    end

    # Hit a target using weapon for damage
    def weapon_hit(target, damage_bonus = 0, hit_bonus = 0, custom_noun = nil, weapon = nil, noun_name_override = nil)
        # get data from weapon item or hand-to-hand
        weapon = weapon || self.weapons.first
        noun = custom_noun || weapon.noun
        noun = noun.to_noun
        hit = false

        # check for override event - i.e. burst rune


        if responds_to_event(:event_override_hit)
            override = { confirm: false, source: self, target: target, weapon: weapon }
            Game.instance.fire_event( self, :event_override_hit, override )
            if override[:confirm]
                return
            end
        end
        if weapon.responds_to_event(:event_override_hit)
            override = { confirm: false, source: self, target: target, weapon: weapon }
            Game.instance.fire_event( weapon, :event_override_hit, override )
            if override[:confirm]
                return
            end
        end
        # calculate hit chance ... I guess burst rune auto-hits?
        hit_chance = (hit_bonus + attack_rating( weapon ) - target.defense_rating ).clamp( 5, 95 )
        if rand(0...100) < hit_chance
            damage = damage_rating(weapon) + damage_bonus + (self.damage_roll * Constants::Damage::DAMROLL_MODIFIER).to_i
            hit = true
        else
            damage = 0
        end

        # modify hit damage

        if responds_to_event(:event_calculate_weapon_hit_damage)
            data = { damage: damage, source: self, target: target, weapon: weapon }
            Game.instance.fire_event( self, :event_calculate_weapon_hit_damage, data )
            damage = data[:damage].to_i
        end

        target.receive_damage(self, damage, noun, false, false, noun_name_override)

        if hit
            if responds_to_event(:event_override_receive_hit)
                override = { confirm: false, source: self, target: target, weapon: weapon }
                Game.instance.fire_event( target, :event_override_receive_hit, override )
                if override[:confirm]
                    return
                end
            end
            if responds_to_event(:event_on_hit)
                data = { damage: damage, source: self, target: target, weapon: weapon }
                Game.instance.fire_event(self, :event_on_hit, data)
            end
            if weapon.responds_to_event(:event_on_hit)
                data = { damage: damage, source: self, target: target, weapon: weapon }
                Game.instance.fire_event(weapon, :event_on_hit, data)
            end
        end

    end

    def receive_heal(source, heal, noun = :heal, silent = false, anonymous = false, noun_name_override = nil)
        if !@active # inactive mobiles can't be healed.
            return
        end
        noun = noun.to_noun
        if heal > 0 && source && source.responds_to_event(:event_calculate_heal)
            calculation_data = { source: source, target: self, heal: heal, noun: noun }
            Game.instance.fire_event(source, :event_calculate_heal, calculation_data)
            damage = calculation_data[:damage]
        end

        if responds_to_event(:event_override_receive_heal)
            override = { confirm: false, source: source, target: self, heal: heal, noun: noun }
            Game.instance.fire_event(self, :event_override_receive_heal, override)
            if override[:confirm]
                return
            end
        end
        receive_damage(source, -heal, noun, silent, anonymous, noun_name_override)
    end

    # Receive some damage!
    # +source+:: the object dealing the damage (can be nil)
    # +damage+:: the amount of damage being dealt
    # +noun+:: the element of the damage (flamestirke, fire, magic)
    # +silent+:: true if damage decorators should not be broadcast
    # +anonymous+:: true if output messages should omit the +source+
    # +noun_name_override+ override the given noun's name with this string, "backstab" for example
    def receive_damage(source, damage, noun = :hit, silent = false, anonymous = false, noun_name_override = nil)
        if !@active # inactive mobiles can't take damage.
            return
        end
        noun = noun.to_noun
        # source event stuff (used to be in +deal_damage+)
        if source
            if source.responds_to_event(:event_calculate_damage) && damage > 0
                calculation_data = { source: source, target: self, damage: damage, noun: noun }
                Game.instance.fire_event(source, :event_calculate_damage, calculation_data)
                damage = calculation_data[:damage]
            end
        end

        if damage >= 0 && source && source.is_a?(Mobile) && source != self
            self.start_combat( source )
        end

        if responds_to_event(:event_override_receive_damage) && damage > 0
            override = { confirm: false, source: source, target: self, damage: damage, noun: noun }
            Game.instance.fire_event(self, :event_override_receive_damage, override)
            if override[:confirm]
                return
            end
        end
        if responds_to_event(:event_calculate_receive_damage) && damage > 0
            calculation_data = { source: source, target: self, damage: damage, noun: noun }
            Game.instance.fire_event(self, :event_calculate_receive_damage, calculation_data)
            damage = calculation_data[:damage]
        end
        if damage > 10
            damage -= stat(:damage_reduction)
            if damage < 10
                damage = 10
            end
        end
        resistance = self.resistance(noun.element)
        # resistance = 0
        noun_name = noun_name_override || noun.name
        if resistance >= 100.0 # immune!
            if !silent
                if source && !anonymous
                    (self.room.occupants | [source]).each_output "0<N>'s #{noun_name} has no effect on #{(source==self) ?"1<r>":"1<n>"}!", [source, self]
                else # anonymous damage
                    self.room.occupants.each_output("#{noun_name} has no effect on 0<n>!", [self])
                end
            end
            return # immunity means we stop here!
        end
        if damage < 0 # healing reverses resistance math
            resistance *= -1
        end
        if resistance != 0
            damage = (damage * (100.0 - resistance) / 100.0)
        end
        if !silent && ((source && source.is_a?(Player)) || self.room.players.length > 0)
            decorators = nil
            if damage < 0
                decorators = Constants::HEAL_DECORATORS
                decorators = decorators.select{ |key, value| -damage <= key}.values.first || decorators.values.last
            else
                if noun.magic
                    decorators = Constants::MAGIC_DAMAGE_DECORATORS
                else
                    decorators = Constants::DAMAGE_DECORATORS
                end
                decorators = decorators.select{ |key, value| damage <= key}.values.first || decorators.values.last
            end

            if source && !anonymous
                (self.room.occupants | [source]).each_output "0<N>'s#{decorators[2]} #{noun_name} #{decorators[1]} #{(source==self) ?"1<r>":"1<n>"}#{decorators[3]}", [source, self]
            else # anonymous damage
                self.room.occupants.each_output("#{noun_name} #{decorators[1]} 0<n>#{decorators[3]} ", [self])
            end
        end
        if damage >= 0
            @health -= damage
        else
            regen(-damage, 0, 0)
        end
        if source && damage > 0
            if source.responds_to_event(:event_on_deal_damage)
                data = {source: source, target: self, damage: damage, noun: noun}
                Game.instance.fire_event(source, :event_on_deal_damage, data)
            end
            if noun.magic
                if source.responds_to_event(:event_on_deal_magic_damage)
                    data = {source: source, target: self, damage: damage, noun: noun}
                    Game.instance.fire_event(source, :event_on_deal_magic_damage, data)
                end
            else
                if source.responds_to_event(:event_on_deal_physical_damage)
                    data = {source: source, target: self, damage: damage, noun: noun}
                    Game.instance.fire_event(source, :event_on_deal_physical_damage, data)
                end
            end
        end
        die( source ) if @health <= 0
    end

    def level_up
        @experience = (@experience - @experience_to_level)
        @level += 1
        @creation_points += 1
        output "You raise a level!!"
        output "You have gained 1 creation points.  Maybe you can get a new skill??"
        Game.instance.fire_event(self, :event_on_level_up, {level: @level})
        self.generate_hand_to_hand_weapon
        try_add_to_regen_mobs
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
        if killer == self || !killer.is_a?(Mobile)
            killer = nil
        end
        (@room.occupants - [self]).each_output "0<N> is DEAD!!", [self]
        if responds_to_event(:event_on_die)
            Game.instance.fire_event( self, :event_on_die, { died: self, killer: killer } )
        end

        (@room.occupants - [self]).each_output "0<N>'s head is shattered, and 0<p> brains splash all over you.", [self]

        if killer
            if killer.group
                killer.group.joined.each{ |k|
                    wealth = (@wealth / killer.group.joined.count).to_i
                    k.xp( self )
                    k.earn( wealth )
                    k.output("You get #{ wealth.to_worth } from the corpse of 0<n>.", [self])
                }
            else
                killer.xp( self )
                killer.earn( @wealth )
                killer.output("You get #{ self.wealth.to_worth } from the corpse of 0<n>.", [self])
            end

            self.items.each do |item|
                item.unlink_reset
                killer.get_item(item)
            end
            killer.output("You offer your victory to #{@deity} who rewards you with 1 deity points.")
        end

        stop_combat
        destroy
    end

    # this COULD be handled with events, but they are so varied that I thought I'd try it this way first...
    def can_move?( direction )
        direction = direction.to_direction
        destination = @room.exits.find{ |exit| exit.direction == direction }.destination
        if !direction || !destination
            output "Alas, you cannot go that way."
            return false
        end
        if (@room.sector.requires_flight || destination.sector.requires_flight) && !self.affected?("flying")
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
        direction = direction.to_direction
        exit = @room.exits.find { |exit| exit.direction == direction }
        if exit.nil?
            output "Alas, you cannot go that way."
            return false
        elsif not can_move? direction
            return false
        else
            return exit.move( self )
        end
    end

    def look_room
        do_command "look"
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
        if self.responds_to_event(:event_mobile_exit)
            Game.instance.fire_event(self, :event_mobile_exit, nil)
        end
        @room&.mobile_exit(self)
        @room = room
        if @room
            @room.mobile_enter(self)
            if @position == :sleeping
                output "Your dreams grow restless."
            else
                do_command "look"
            end
        end
        if responds_to_event(:event_mobile_enter)
            Game.instance.fire_event( self, :event_mobile_enter, { mobile: self } )
        end
        (@room.occupants - [self]).reject{|t| !t.responds_to_event(:event_observe_mobile_enter) }.each do |t|
            Game.instance.fire_event( t, :event_observe_mobile_enter, {mobile: self} )
        end
    end

    def recall
        @room.occupants.each_output "0<N> pray0<,s> for transportation!", [self]
        if responds_to_event(:event_try_recall)
            data = { mobile: self, success: true }
            Game.instance.fire_event(self, :event_try_recall, data)
            if !data[:success]
                output "#{@deity} has forsaken you."
                return false
            end
        end
        (@room.occupants - [self]).each_output "0<N> disappears!", [self]
        room = @room.continent.recall_room
        move_to_room( room )
        (@room.occupants - [self]).each_output "0<N> arrives in a puff of smoke!", [self]
        return true
    end

    def condition_percent
        (( 100 * @health ) / @max_health).to_i
    end

    def condition
        percent = condition_percent

        if responds_to_event(:event_show_condition)
            data = { percent: percent }
            Game.instance.fire_event( self, :event_show_condition, data )
            percent = data[:percent]
        end

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
            return self.hit_roll + (15 + (@level * 3 / 2))
        else
            return self.hit_roll + (15 + (@level * 3 / 2)) * 0.7  # attacking with unfamiliar weapon has a 30% hit chance penalty
        end
    end

    def defense_rating
        ( -1 * self.armor_class - 100 ) / 5
    end

    def armor_class
        value = stat(:armor_class)
        if @base_armor_class
            value += @base_armor_class
        end
        return value
    end

    def hit_roll
        stat(:hit_roll)
    end

    def damage_roll
        stat(:damage_roll) + [strength_to_damage, 0].max
    end

    def damage_rating(weapon)
        if proficient( weapon.genre )
            return weapon.damage
        else
            return ( weapon.damage ) / 2
        end
    end

    def strength_to_damage
        ( 0.5 * stat(:strength) - 6 ).to_i
    end

    def to_s
        self.name.to_s
    end

    def show_short_description(observer)
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
        if !self.responds_to_event(:event_try_can_see) &&
            !self.room.responds_to_event(:event_try_can_see_room) &&
            !target.responds_to_event(:event_try_can_be_seen)
            return true
        end
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

    def base_health

        if @base_health
            return @base_health
        end
        return 20 + (@level - 1) * ( 10 + ( stat(:wisdom) / 5 ).to_i + ( stat(:constitution) / 2 ).to_i )
    end

    def max_health
        return base_health + stat(:health)
    end

    def base_mana
        if @base_mana
            return @base_mana
        end
        return 100 + (@level - 1) * ( 10 + ( stat(:wisdom) / 5 ).to_i + ( stat(:intelligence) / 3 ).to_i )
    end

    def max_mana
        return base_mana + stat(:mana)
    end

    def base_movement
        if @base_movement
            return @base_movement
        end
        return 100 + (@level - 1) * ( 10 + ( stat(:wisdom) / 5 ).to_i + ( stat(:dexterity) / 3 ).to_i )
    end

    def max_movement
        return base_movement + stat(:movement)
    end

    # Returns the value of a stat for a given key.
    # Adjusts for
    #
    #  some_mobile.stat(:strength)
    #  some_mobile.stat(:max_wisdom)
    def stat(s)
        s = s.to_stat
        if !s
            return 0
        end
        value = @race.stat(s)
        if @stats
            value += @stats.dig(s).to_i
        end

        if @mobile_class
            value += @mobile_class.stat(s)
        end
        # enforce stat.base_cap
        if (cap = s.base_cap) && value > cap
            value = cap
        end

        # add item modifiers and item affect modifiers
        # value += equipment.map{ |item| item.modifier(s) + (item.affects) ? item.affects.map{ |aff| aff.modifier(s) }.reduce(0, :+) : 0 }.reduce(0, :+)

        equipment.each do |item|
            value += item.modifier(s)
            if item.affects
                value += item.affects.map{ |aff| aff.modifier(s) }.reduce(:+)
            end
        end

        # add affect modifiers
        if @affects
            value += @affects.map{ |aff| aff.modifier(s) }.reduce(0, :+)
        end

        # enforce max_stat cap
        if s.max_stat
            max = self.stat(s.max_stat)
            if value > max
                value = max
            end
        end
        # enforce hard cap (stats can only to 30)
        if (cap = s.hard_cap) && value > cap
            value = cap
        end
        return value
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
{cLevel:{x        #{@level.to_s.rpad(23)} {cAge:{x          17 - 0(0) hours
{cRace:{x         #{@race.name.to_s.rpad(23)} {cGender:{x       #{@gender.name}
{cClass:{x        #{@mobile_class.name.to_s.rpad(23)} {cDeity:{x        #{@deity}
{cAlignment:{x    #{@alignment.to_s.rpad(23)} {cDeity Points:{x 0
{cPracs:{x        N/A                     {cCreation Points:{x #{@creation_points}
{cExp:{x          #{"#{@experience} (#{@experience_to_level}/lvl)".rpad(23)} {cNext Level:{x   #{@experience_to_level - @experience}
{cQuest Points:{x #{ @quest_points }
{cCarrying:{x     #{ "#{@inventory.count} of #{carry_max}".rpad(23) } {cWeight:{x       #{ @inventory.items.map(&:weight).reduce(0, :+).to_i } of #{ weight_max }
{cGold:{x         #{ @wealth.gold.to_s.rpad(23) } {cSilver:{x       #{ @wealth.silver.to_s }
---------------------------------- Stats --------------------------------
{cHealth:{x       #{"#{@health} of #{max_health} (#{max_health})".rpad(23)} {cMana:{x         #{@mana} of #{max_mana} (#{max_mana})
{cMovement:{x     #{"#{@movement} of #{max_movement} (#{max_movement})".rpad(23)} {cWimpy:{x        #{@wimpy}
#{score_stat(:strength)}#{score_stat(:constitution)}
#{score_stat(:intelligence)}#{score_stat(:wisdom)}
#{score_stat(:dexterity)}
{cHit Roll:{x     #{ self.hit_roll.to_s.rpad(23)} {cDamage Roll:{x  #{ self.damage_roll }
{cDamResist:{x    #{ stat(:damage_reduction).to_s.rpad(23) } {cSpell Damage:{x #{ stat(:spell_damage) }
{cAttack Speed:{x #{ self.attack_speeds.values.join(" / ") }
-------------------------------- Elements -------------------------------
#{resist_string}
--------------------------------- Armour --------------------------------
{cArmor Class:{x   #{ (-1 * self.armor_class).to_s.rpad(23) } {c{x
------------------------- Condition and Affects -------------------------
You are #{@position.name}.)
    end

    # Take a stat name as a string and convert it into a score-formatted output string.
    #
    #  score_stat("str")     # => Str:       14(14) of 23
    def score_stat(s)
        s = s.to_stat
        base = @stats[s].to_i + @race.stat(s)
        if @stats
            base += @stats[s]
        end
        if @mobile_class
            base += @mobile_class.stat(s)
        end
        modified = stat(s)
        max = stat(s.max_stat)
        return "{c#{"#{s.name.capitalize}:".rpad(14)}{x#{"#{base}(#{modified}) of #{max}".rpad(24)}"
    end

    def skills
        return (@race.skills | @mobile_class.skills)
    end

    def spells
        return (@race.spells | @mobile_class.spells)
    end

    def resistance(element)
        element = element.to_element
        if !element.resist_stat
            return 0
        end
        return self.stat(element.resist_stat)
    end

    def resistances
        element_data = Game.instance.elements.values.map { |e| [e, self.resistance(e)] }.to_h
        return element_data
    end

    def set_race(race)
        @race = race
        @size = race.size

        old_equipment = nil
        if @race_equip_slots
            old_equipment = @race_equip_slots.map { |slot| slot.item }.reject!(&:nil?)
            old_equipment.each do |item|
                get_item(item, true)
            end
        end

        if @race.equip_slot_infos.size > 0
            @race_equip_slots = []
            @race.equip_slot_infos.each do |slot|
                @race_equip_slots << EquipSlot.new(self, slot)
            end
        else
            @race_equip_slots = nil
        end

        if old_equipment
            old_equipment.each do |item| # try to wear all items that were equipped before
                wear(item, true)
            end
        end
        if @race_affects
            @race_affects.each do |affect|
                affect.clear(true)
            end
        end
        if @race.affect_models.size > 0
            @race_affects = []
            @race.affect_models.each do |affect_model|
                apply_affect_model(affect_model, true, @race_affects)
            end
        else
            @race_affects = nil
        end
    end

    def set_mobile_class(mobile_class)
        @mobile_class = mobile_class

        old_equipment = nil
        if @mobile_class_equip_slots
            old_equipment = @mobile_class_equip_slots.map { |slot| slot.item }.reject!(&:nil?)
            old_equipment.each do |item|
                get_item(item, true)
            end
        end
        if @mobile_class.equip_slot_infos.size > 0
            @mobile_class_equip_slots = []
            @mobile_class.equip_slot_infos.each do |slot|
                @mobile_class_equip_slots << EquipSlot.new(self, slot)
            end
        else
            @mobile_class_equip_slots = nil
        end
        if old_equipment
            old_equipment.each do |item| # try to wear all items that were equipped before
                wear(item, true)
            end
        end

        if @mobile_class_affects
            @mobile_class_affects.each do |affect|
                affect.clear(true)
            end
        end
        if @mobile_class.affect_models.size > 0
            @mobile_class_affects = []
            @mobile_class.affect_models.each do |affect_model|
                apply_affect_model(affect_model, true, @mobile_class_affects)
            end
        else
            @mobile_class_affects = nil
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

    def do_visible
        remove_affects_with_keywords("invisibility")
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

    def db_source_type_id
        return 2
    end

end
