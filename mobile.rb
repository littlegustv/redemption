class Mobile < GameObject

    attr_accessor :room, :vnum, :attacking, :lag, :position, :inventory, :equipment, :affects, :level

    def initialize( data, game, room )
        @game = game
        @attacking
        @lag = 0
        @room = room
        @attack_speed = 1
        @keywords = data[:keywords]
        @vnum = data[ :vnum ]
        @short_description = data[ :short_description ]
        @long_description = data[ :long_description ]
        @full_description = data[ :full_description ]
        @race = data[ :race ]
        @class = "Zealot"
        @experience = 0
        @experience_to_level = 1000
        @quest_points = 0
        @quest_points_to_remort = 1000
        @alignment = data[ :alignment ].to_i
        @gold = (data[:wealth].to_i / 1000).floor
        @silver = data[:wealth].to_i - (@gold * 1000)
        @wimpy = 0

        @stats = {
            str: 13,
            con: 13,
            int: 13,
            wis: 13,
            dex: 13,
            hitroll: data[:hitroll] || rand(5...7),
            damroll: data[:damage] || 50
        }

        @affects = []

        @level = data[:level] || 1
        @hitpoints = data[:hitpoints] || 500
        @basehitpoints = @hitpoints

        @manapoints = data[:manapoints] || 100
        @basemanapoints = @manapoints

        @movepoints = data[:movepoints] || 100
        @basemovepoints = @movepoints


        @damage_range = data[:damage_range] || [ 2, 12 ]
        @noun = data[:attack] || ["entangle", "grep", "strangle", "pierce", "smother", "flaming bite"].sample
        @armor_class = data[:armor_class] || [0, 0, 0, 0]
        @parts = data[:parts] || Constants::PARTS

        @position = Position::STAND
        @inventory = []
        @equipment = empty_equipment_set
        @game = game
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
        super elapsed
    end

    def do_command( input )
        cmd, args = input.sanitize.split " ", 2
        @game.do_command( self, cmd, args.to_s.split(" ") )
    end

    def start_combat( attacker )
        # if they are already fighting you, i.e. they started it
        @position = Position::FIGHT
        if attacker && attacker.attacking == self
            do_command "yell 'Help I am being attacked by #{attacker}!'"
        end
        if @attacking.nil?
            @attacking = attacker
        end
    end

    def stop_combat
        @attacking = nil
        @position = Position::STAND
        target({ attacking: self, type: ["Mobile", "Player"] }).each do |t|
            t.attacking = nil
            if target({ attacking: t, type: ["Mobile", "Player"] }).empty?
                t.position = Position::STAND
            end
        end
    end

    def combat
        if @attacking
            to_me = []
            to_target = []
            to_room = []
            @attack_speed.times do |attack|
                hit_chance = ( attack_rating - @attacking.defense_rating ).clamp( 5, 95 )
                if rand(0...100) < hit_chance
                    damage = damage_rating
                else
                    damage = 0
                end
                m, t, r = hit damage
                output m, [@attacking]
                @attacking.output t, [self]
                broadcast r, target({ not: [ self, @attacking ], room: @room }), [self, @attacking]
                @attacking.damage( damage, self )
                break if @attacking.nil?
            end
        end
    end

    def noun
        @equipment[:wield] ? @equipment[:wield].noun : @noun
    end

    def hit( damage )
        decorators = Constants::DAMAGE_DECORATORS.select{ |key, value| damage >= key }.values.last
        texts = ["Your #{decorators[2]} #{noun} #{decorators[1]} %s [#{damage}]", "%s's' #{decorators[2]} #{noun} #{decorators[1]} you", "%s's' #{decorators[2]} #{noun} #{decorators[1]} %s"]
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

    def levelup
        if @experience > @experience_to_level
            @experience = (@experience - @experience_to_level)
            @level += 1
            @basehitpoints += 20
            @basemanapoints += 10
            @basemovepoints += 10
            "\n\rYou raise a level!!  You gain 20 hit points, 10 mana, 10 move, and 0 practices."
        else
            ""
        end
    end

    def xp( target )
        dlevel = [target.level - @level, -10].max
        base_xp = dlevel <= 5 ? Constants::EXPERIENCE_SCALE[dlevel] : ( 180 + 12 * (dlevel - 5 ))
        base_xp *= 10  / ( @level + 4 ) if @level < 6
        base_xp = rand(base_xp..(5 * base_xp / 4))
        @experience = @experience.to_i + base_xp.to_i
        message = "You receive #{base_xp} experience points." + levelup
    end

    def die( killer )
        experience_message = killer.xp( self )
        killer.output %Q(
#{self.to_s.capitalize} is DEAD!!
#{experience_message}
#{self.to_s.capitalize}'s head is shattered, and her brains splash all over you.
#{( @inventory + @equipment.values.reject(&:nil?) ).map{ |item| "You get #{item} from the corpse of #{self}."}.join("\n")}
You offer your victory to Gabriel who rewards you with 1 deity points.
)
        killer.inventory += @inventory + @equipment.values.reject(&:nil?)
        @inventory = []
        @equipment
        @game.mobiles.delete( self )
        @game.mobile_count[ @vnum ] = [0, (@game.mobile_count[ vnum ].to_i - 1)].max
        stop_combat
    end

    def move( direction )
        if @room.exits[ direction.to_sym ].nil?
            output "There is no exit [#{direction}]."
        else
            broadcast "%s leaves #{direction}.", target({ :not => self, :room => @room }), [self]
            output "You leave #{direction}."
            @room = @room.exits[ direction.to_sym ]
            broadcast "%s has arrived.", target({ :not => self, :room => @room }), [self]
            @game.do_command self, "look"
            # cmd_look
        end
    end

    def move_to_room( room )
        @room = room
        @game.do_command self, "look"
    end

    def recall
        room = @game.recall_room( @room.continent )
        move_to_room( room )
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

    def defense_rating
        ( -1  * @armor_class[0] - 100 ) / 5
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
        if ( target = @inventory.select { |item| item.fuzzy_match( args[0].to_s ) && can_see?(item) }.first )
            slot_name = target.wear_location
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
                    return
                end
            end
            output "You can't wear something '#{ slot_name }'"
        else
            output "You don't have any '#{args[0]}'"
        end
    end

    def unwear( args )
        if ( slot = @equipment.select { |slot, item| (item.nil? ? false : item.fuzzy_match( args[0].to_s )) && can_see?(item) }.keys.first )
            target = @equipment[ slot ]
            @inventory.push target
            @equipment[ slot ] = nil
            output "You stop wearing #{ target }"
        else
            output "You don't have any '#{args[0]}'"
        end
    end

    def can_see? target
        if @affects.include? "blind"
            false
        else
            true
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

    def stat(key)
        @stats[key].to_i + @equipment.map{ |slot, value| value.nil? ? 0 : value.modifier( key ).to_i }.reduce(0, :+)
    end

    def armor(index)
        @armor_class[index].to_i
    end

    def score
%Q(
#{@short_description}
Member of clan Kenshi
---------------------------------- Info ---------------------------------
Level:     #{@level.to_s.ljust(26)} Age:       17 - 0(0) hours
Race:      #{@race.ljust(26)} Sex:       male
Class:     #{@class.ljust(26)} Deity:     Gabriel
Alignment: #{@alignment.to_s.ljust(26)} Deity Points: 0
Pracs:     N/A                        Trains:    N/A
Exp:       #{"#{@experience} (#{@experience_to_level}/lvl)".ljust(26)} Next Level: #{@experience_to_level - @experience}
Quest Points: #{ @quest_points } (#{ @quest_points_to_remort } for remort/reclass)
Carrying:  #{ "#{@inventory.count} of #{carry_max}".ljust(26) } Weight:    #{ @inventory.map(&:weight).reduce(0, :+).to_i } of #{ weight_max }
Gold:      #{ @gold.to_s.ljust(26) } Silver:    #{ @silver.to_s }
Claims Remaining: N/A
---------------------------------- Stats --------------------------------
Hp:        #{"#{@hitpoints} of #{maxhitpoints} (#{@basehitpoints})".ljust(26)} Mana:      #{@manapoints} of #{maxmanapoints} (#{@basemanapoints})
Movement:  #{"#{@movepoints} of #{maxmovepoints} (#{@basemovepoints})".ljust(26)} Wimpy:     #{@wimpy}
Str:       #{"#{stat(:str)}(#{@stats[:str]}) of 23".ljust(26)} Con:       #{stat(:con)}(#{@stats[:con]}) of 23
Int:       #{"#{stat(:int)}(#{@stats[:int]}) of 23".ljust(26)} Wis:       #{stat(:wis)}(#{@stats[:wis]}) of 23
Dex:       #{ stat(:dex) }(#{ @stats[:dex] }) of 23
HitRoll:   #{ stat(:hitroll).to_s.ljust(26)} DamRoll:   #{ stat(:damroll) }
DamResist: #{ stat(:damresist).to_s.ljust(26) } MagicDam:  #{ stat(:magicdam) }
AttackSpd: #{ stat(:attackspeed) }
--------------------------------- Armour --------------------------------
Pierce:    #{ armor( 0 ).to_s.ljust(26) } Bash:      #{ armor( 1 ) }
Slash:     #{ armor( 2 ).to_s.ljust(26) } Magic:     #{ armor( 3 ) }
------------------------- Condition and Affects -------------------------
You are Ruthless.
You are #{Position::STRINGS[ @position ]}.
)
    end

end
