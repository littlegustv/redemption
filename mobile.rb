class Mobile < GameObject

    attr_accessor :id, :attacking, :lag, :position, :inventory, :equipment, :affects, :level, :group, :in_group, :race_id

    attr_reader :game, :room

    def initialize( data, game, room )
        super(data[ :short_description ], game)
        @attacking
        @lag = 0
        @room = room
        @room.mobiles.push(self)
        @keywords = data[:keywords]
        @id = data[ :id ]
        @short_description = data[ :short_description ]
        @long_description = data[ :long_description ]
        @full_description = data[ :full_description ]
        @race_id = data[ :race_id ]
        @class = data[ :class ]
        @skills = []
        @spells = [] + ["lightning bolt", "acid blast", "blast of rot", "pyrotechnics", "ice bolt"]
        @class_id = data[ :class_id ]
        @experience = 0
        @experience_to_level = 1000
        @quest_points = 0
        @quest_points_to_remort = 1000
        @alignment = data[ :alignment ].to_i
        @gold = (data[:wealth].to_i / 1000).floor
        @silver = data[:wealth].to_i - (@gold * 1000)
        @wimpy = 0

        @group = []
        @in_group = nil

        @stats = {
            success: 100,
            str: 0,
            con: 0,
            int: 0,
            wis: 0,
            dex: 0,
            max_str: 0,
            max_con: 0,
            max_int: 0,
            max_wis: 0,
            max_dex: 0,
            hitroll: data[:hitroll] || rand(5...7),
            damroll: data[:damage] || 50,
            attack_speed: 1,
            ac_pierce: data[:ac].to_a[0].to_i,
            ac_bash: data[:ac].to_a[1].to_i,
            ac_slash: data[:ac].to_a[2].to_i,
            ac_magic: data[:ac].to_a[3].to_i,
        }
        if @class

        end

        affect_flags = data[:affect_flags] || @game.race_data[@race_id][:affect_flags]

        affect_flags.each do |flag|
            if flag == "hatchling"
                apply_affect(AffectHatchling.new(source: self, target: self, level: 0, race_data: @game.race_data))
            end
        end

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
        @inventory = []
        @equipment = empty_equipment_set
    end

    def knows( skill_name )
        (skills + spells).include? skill_name
    end

    def empty_equipment_set
        {
            light: nil,
            finger_1: nil,
            finger_2: nil,
            neck_1: nil,
            neck_2: nil,
            torso: nil,
            head: nil,
            legs: nil,
            feet: nil,
            hands: nil,
            arms: nil,
            shield: nil,
            body: nil,
            waist: nil,
            wrist_1: nil,
            wrist_2: nil,
            hold: nil,
            float: nil,
            orbit: nil,
            wield: nil,
        }
    end

    def update( elapsed )
        @affects.each { |aff| aff.update( elapsed ) }
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
        @game.do_command( self, cmd, args.to_s.scan(/(((\d+|all)\*)?((\d+|all)\.)?(\w+|'[\w\s]+'))/i).map(&:first) )
    end

    # When mobile is attacked, respond automatically unless already in combat targeting someone else
    #
    # When calling 'start_combat', call it first for the 'victim', then for the attacker

    def start_combat( attacker )
        if attacker.room != @room
            return
        end
        # only the one being attacked
        if attacker.attacking != self && @attacking != attacker
            do_command "yell 'Help I am being attacked by #{attacker}!'"
        end
        @position = Position::FIGHT
        if @attacking.nil?
            @attacking = attacker
        end
    end

    def stop_combat
        @attacking = nil
        @position = Position::STAND
        target({ quantity: "all", attacking: self, type: ["Mobile", "Player"] }).each do |t|
            t.attacking = nil
            if target({ quantity: "all", attacking: t, type: ["Mobile", "Player"] }).empty?
                t.position = Position::STAND
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
        if @attacking
            to_me = []
            to_target = []
            to_room = []
            stat( :attack_speed ).times do |attack|
                hit_chance = ( attack_rating - @attacking.defense_rating( @equipment[:wield] ? @equipment[:wield].element : "bash" ) ).clamp( 5, 95 )
                if rand(0...100) < hit_chance
                    damage = damage_rating
                else
                    damage = 0
                end
                hit damage
                return if @attacking.nil?
                weapon_flags if damage > 0
                return if @attacking.nil?
            end
        end
    end

    def noun
        @equipment[:wield] ? @equipment[:wield].noun : @noun
    end

    def weapon_flags
        ( flags = ( @equipment[:wield] ? @equipment[:wield].flags : [] ) ).each do |flag|
            if ( texts = Constants::ELEMENTAL_EFFECTS[ flag ] )
                @attacking.output texts[0], [self]
                @attacking.broadcast texts[1], target({ not: @attacking, room: @room }), [ @attacking, @equipment[:wield] ]
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
                target.broadcast "{b%s coughes and chokes on the water.{x", target({ not: target, room: @room }), [target]
                target.output "{bYou cough and choke on the water.{x"
                target.apply_affect(Affect.new( name: "flooding", keywords: ["flooding", "slow"], source: self, target: target, level: self.level, duration: 30, modifiers: { attack_speed: -1, dex: -1 }))
            when "shocking"
                target.broadcast "{y%s jerks and twitches from the shock!{x", target({ not: target, room: @room }), [target]
                target.output "{yYour muscles stop responding.{x"
                target.apply_affect( Affect.new( name: "shocking", target: target, source: self, keywords: ["shocking", "stun"], duration: 30, modifiers: { success: -10 }, level: self.level ) )
            when "corrosive"
                target.broadcast "{g%s flesh burns away, revealing vital areas!{x", target({ not: target, room: @room }), [target]
                target.output "{gChunks of your flesh melt away, exposing vital areas!{x"
                target.apply_affect( Affect.new( name: "corrosive", source: self, target: target, keywords: ["corrosive"], duration: 30, modifiers: { ac_pierce: -10, ac_slash: -10, ac_bash: -10 }, level: self.level ) )
            when "poison"
                target.broadcast "{m%s looks very ill.{x", target({ not: target, room: @room }), [target]
                target.output "{mYou feel poison coursing through your veins.{x"
                target.apply_affect( AffectPoison.new( target: target, source: self, level: self.level ) )
            when "flaming"
                # fire blind doesn't stack
                if not target.affected? "blind"
                    target.broadcast "{r%s is blinded by smoke!{x", target({ not: target, room: @room }), [target]
                    target.output "{rYour eyes tear up from smoke...you can't see a thing!{x"
                    target.apply_affect( AffectBlind.new( target: target, source: self, level: self.level ) )
                end
            when "frost"
                target.broadcast "{C%s turns blue and shivers.{x", target({ not: target, room: @room }), [target]
                target.output "{CA chill sinks deep into your bones.{x"
                target.apply_affect( Affect.new( name: "frost", target: target, source: self, keywords: ["frost"], duration: 30, modifiers: { str: -2 }, level: self.level ) )
            end
        end
    end

    def magic_hit( target, damage, noun = "spell", element = "spell" )
        if target != self
            target.start_combat( self )
            self.start_combat( target )
        end

        decorators = Constants::MAGIC_DAMAGE_DECORATORS.select{ |key, value| damage >= key }.values.last

        output "Your #{noun} #{decorators[0]} %s#{decorators[1]}#{decorators[2]}", [target]
        target.output("%s's #{noun} #{decorators[0]} you#{decorators[1]}#{decorators[2]}", [self]) unless target == self
        broadcast "%s's #{noun} #{decorators[0]} %s#{decorators[1]}#{decorators[2]}", target({ not: [self, target], room: @room }), [self, target]

        elemental_effect( target, element )
        elemental_effect( target, element ) if knows "essence"

        target.damage( damage, self )
    end

    def hit( damage, custom_noun = nil, target = nil )
        hit_noun = custom_noun || noun
        target = target || @attacking
        decorators = Constants::DAMAGE_DECORATORS.select{ |key, value| damage >= key }.values.last

        output "Your #{decorators[2]} #{hit_noun} #{decorators[1]} %s#{decorators[3]} [#{damage}]", [target]
        target.output "%s's #{decorators[2]} #{hit_noun} #{decorators[1]} you#{decorators[3]}", [self]
        broadcast "%s's #{decorators[2]} #{hit_noun} #{decorators[1]} %s#{decorators[3]} ", target({ not: [ self, target ], room: @room }), [self, target]

        target.damage( damage, self )
        @game.fire_event(:event_on_hit, {}, self, @room, @room.area, equipment.values)
    end

    def damage( damage, attacker )
        @hitpoints -= damage
        die( attacker ) if @hitpoints <= 0
    end

    def show_equipment
%Q(
<used as light>       #{equipment[:light] || "<Nothing>"}
<worn on finger>      #{equipment[:finger_1] || "<Nothing>"}
<worn on finger>      #{equipment[:finger_2] || "<Nothing>"}
<worn around neck>    #{equipment[:neck_1] || "<Nothing>"}
<worn around neck>    #{equipment[:neck_2] || "<Nothing>"}
<worn on torso>       #{equipment[:torso] || "<Nothing>"}
<worn on head>        #{equipment[:head] || "<Nothing>"}
<worn on legs>        #{equipment[:legs] || "<Nothing>"}
<worn on feet>        #{equipment[:feet] || "<Nothing>"}
<worn on hands>       #{equipment[:hands] || "<Nothing>"}
<worn on arms>        #{equipment[:arms] || "<Nothing>"}
<worn about body>     #{equipment[:body] || "<Nothing>"}
<worn about waist>    #{equipment[:waist] || "<Nothing>"}
<worn around wrist>   #{equipment[:wrist_1] || "<Nothing>"}
<worn around wrist>   #{equipment[:wrist_2] || "<Nothing>"}
<wielded>             #{equipment[:wield] || "<Nothing>"}
<held>                #{equipment[:hold] || "<Nothing>"}
<floating nearby>     #{equipment[:float] || "<Nothing>"}
<orbiting nearby>     #{equipment[:orbit] || "<Nothing>"}
)
    end

    def level_up
        @experience = (@experience - @experience_to_level)
        @level += 1
        @basehitpoints += 20
        @basemanapoints += 10
        @basemovepoints += 10
        output "You raise a level!!  You gain 20 hit points, 10 mana, 10 move, and 0 practices."
        @game.fire_event(:event_on_level_up, {level: @level}, self, @room, @room.area, equipment.values)
    end

    def xp( target )
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
        broadcast "%s is DEAD!!", target({ :not => self, :room => @room }), [self]
        killer.xp( self )
        broadcast "%s's head is shattered, and her brains splash all over you.", target({ :not => self, :room => @room }), [self]
        killer.output "#{( @inventory + @equipment.values.reject(&:nil?) ).map{ |item| "You get #{item} from the corpse of #{self}."}.push("You offer your victory to Gabriel who rewards you with 1 deity points.").join("\n")}"
        killer.inventory += @inventory + @equipment.values.reject(&:nil?)
        @inventory = []
        @equipment
        @game.mobiles.delete( self )
        @game.mobile_count[ @id ] = [0, (@game.mobile_count[ id ].to_i - 1)].max
        stop_combat
    end

    def move( direction )
        if @room.exits[ direction.to_sym ].nil?
            output "There is no exit [#{direction}]."
        else
            broadcast "%s leaves #{direction}.", target({ :not => self, :room => @room }), [self] unless self.affected? "sneak"
            move_to_room(@room.exits[direction.to_sym])
            broadcast "%s has arrived.", target({ :not => self, :room => @room }), [self] unless self.affected? "sneak"
        end
    end

    def look_room
        @game.do_command self, "look"
    end

    def who
        "[#{@level.to_s.rjust(2)} #{@game.race_data.dig(@race_id, :display_name).ljust(7)} #{@game.class_data.dig(@class_id, :name).capitalize.rjust(7)}] #{@short_description}"
    end

    def move_to_room( room )
        @room&.mobiles&.delete(self)
        @room = room
        @room.mobiles.push(self)
        @game.do_command self, "look"
    end

    def recall
        output "You pray for transportation!"
        broadcast "%s prays for transportation!", target({ room: @room, not: self, quantity: "all" }), [self]
        broadcast "%s disappears!", target({ room: @room, not: self, quantity: "all" }), [self]
        room = @game.recall_room( @room.continent )
        move_to_room( room )
        broadcast "%s arrives in a puff of smoke!", target({ room: room, not: self, quantity: "all" }), [self]
    end

    def condition
        percent = ( 100 * @hitpoints ) / maxhitpoints
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
        if @equipment[:wield]
            @equipment[:wield].damage + stat(:damroll)
        else
            rand(@damage_range[0]...@damage_range[1]).to_i + stat(:damroll)
        end
    end

    def to_s
        @short_description
    end

    def long
        @long_description
    end

    def full
        @full_description
    end

    def wear( args )
        if ( targets = target({ list: inventory, visible_to: self }.merge( args.first.to_s.to_query )) )
            targets.each do |target|
                slot_name = target.wear_location
                worn = false
                ["", "_1", "_2"].each do | modifier |
                    slot = "#{slot_name}#{modifier}".to_sym
                    if @equipment.keys.include? slot
                        if ( old = @equipment[ slot ] )
                            @inventory.push old
                            output "You stop wearing #{old}"
                        end
                        @equipment[ slot ] = target
                        @inventory.delete target
                        output "You wear #{target} '#{ slot_name }'"
                        worn = true
                        break
                    end
                end
                output "You can't wear something '#{ slot_name }'" if not worn
            end
        else
            output "You don't have any '#{args[0]}'"
        end
    end

    def unwear( args )
        if ( targets = target({ list: equipment.values, visible_to: self }.merge( args.first.to_s.to_query ) ) )
            targets.each do |target|
                @inventory.push target
                @equipment[ @equipment.key(target) ] = nil
                output "You stop wearing #{ target }"
            end
        else
            output "You aren't wearing any '#{args[0]}'"
        end
    end

    def can_see? target
        return true if target == self
        data = {chance: 100, target: target}
        @game.fire_event(:event_try_can_see, data, self, @room, @room.area, equipment.values)
        return dice(1, 100) <= data[:chance]
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

    def stat(key)
        (@game.race_data[@race_id][key] || 0) + @stats[key].to_i + @equipment.map{ |slot, value| value.nil? ? 0 : value.modifier( key ).to_i }.reduce(0, :+) + @affects.map{ |aff| aff.modifier( key ).to_i }.reduce(0, :+)
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
{cCarrying:{x  #{ "#{@inventory.count} of #{carry_max}".ljust(26) } {cWeight:{x    #{ @inventory.map(&:weight).reduce(0, :+).to_i } of #{ weight_max }
{cGold:{x      #{ @gold.to_s.ljust(26) } {cSilver:{x    #{ @silver.to_s }
{cClaims Remaining:{x N/A
---------------------------------- Stats --------------------------------
{cHp:{x        #{"#{@hitpoints} of #{maxhitpoints} (#{@basehitpoints})".ljust(26)} {cMana:{x      #{@manapoints} of #{maxmanapoints} (#{@basemanapoints})
{cMovement:{x  #{"#{@movepoints} of #{maxmovepoints} (#{@basemovepoints})".ljust(26)} {cWimpy:{x     #{@wimpy}
{cStr:{x       #{"#{@stats[:str]+race_hash[:str]}(#{stat(:str)}) of #{@stats[:max_str]+race_hash[:max_str]}".ljust(26)} {cCon:{x       #{@stats[:con]+race_hash[:con]}(#{stat(:con)}) of #{@stats[:max_con]+race_hash[:max_con]}
{cInt:{x       #{"#{@stats[:int]+race_hash[:int]}(#{stat(:int)}) of #{@stats[:max_int]+race_hash[:max_int]}".ljust(26)} {cWis:{x       #{@stats[:wis]+race_hash[:wis]}(#{stat(:wis)}) of #{@stats[:max_wis]+race_hash[:max_wis]}
{cDex:{x       #{ @stats[:dex]+race_hash[:dex]}(#{stat(:dex)}) of #{@stats[:max_dex]+race_hash[:max_dex]}
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

    def skills
        return @skills + @game.race_data.dig(@race_id, :skills).to_a + @game.class_data.dig(@class_id, :skills).to_a
    end

    def spells
        return @spells + @game.race_data.dig(@race_id, :spells).to_a + @game.class_data.dig(@class_id, :spells).to_a
    end

end
