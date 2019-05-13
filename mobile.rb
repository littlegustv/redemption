class Mobile < GameObject

    attr_accessor :room, :attacking, :lag, :position, :inventory

    @attacking

    def initialize( data, game, room )
        @room = room
        @attack_speed = 1
        @keywords = data[:keywords]
        @short_description = data[ :short_description ]
        
        @level = data[:level] || 1
        @hitpoints = data[:hitpoints] || 500
        @maxhitpoints = @hitpoints
        @hitroll = data[:hitroll] || rand(5...7)
        @damroll = data[:damage] || 20
        @damage_range = data[:damage_range] || [ 2, 12 ]
        @noun = data[:attack] || ["entangle", "grep", "strangle", "pierce", "smother", "flaming bite"].sample
        @armor_class = data[:armor_class] || [0, 0, 0, 0]
        @parts = data[:parts] || Constants::PARTS

        @position = Position::STAND
        @inventory = []
        @game = game
    end

    def update( elapsed )
        super elapsed
    end

    def start_combat( attacker )
        # if they are already fighting you, i.e. they started it
        @position = Position::FIGHT
        if attacker && attacker.attacking == self
            # fix me: replace with call to cmd_yell (also needs to be created)
            broadcast "#{self} yells 'Help I am being attacked by #{ attacker }!", target({ not: self })
            output "You yell 'Help I am being attacked by #{ attacker }!"
        end
        if @attacking.nil?
            @attacking = attacker
        end
    end

    def stop_combat
        @attacking = nil
        @position = Position::STAND
        # fix me: how to know what position to set everyone who was attacking ME, since they might still be being attacked??
        target({ attacking: self, type: ["Mobile", "Player"] }).each { |t| t.attacking = nil }
    end

    def combat
        if @attacking
            to_me = []
            to_target = []
            to_room = []
            @attack_speed.times do |attack|
                hit_chance = ( attack_rating - @attacking.defense_rating ).clamp( 5, 95 )
                if rand(0...100) < hit_chance
                    damage = rand(@damage_range[0]...@damage_range[1]) + @damroll
                else
                    damage = 0
                end
                m, t, r = hit damage
                output m
                @attacking.output t
                broadcast r, target({ not: [ self, @attacking ], room: @room })
                @attacking.damage( damage )
                break if @attacking.nil?
            end
        end
    end

    def hit( damage )
        decorators = Constants::DAMAGE_DECORATORS.select{ |key, value| damage >= key }.values.last
        texts = ["Your #{decorators[2]} #{@noun} #{decorators[1]} #{@attacking } [#{damage}]", "#{self}'s' #{decorators[2]} #{@noun} #{decorators[1]} you", "#{self}'s' #{decorators[2]} #{@noun} #{decorators[1]} #{ @attacking }"]
    end

    def damage( damage )
        @hitpoints -= damage
        die if @hitpoints <= 0
    end

    def die
        output "You have been KILLED!"
        broadcast "#{self} has been KILLED.", target({ not: [ self ] })
        stop_combat
    end

    def move( direction )
        if @room.exits[ direction.to_sym ].nil?
            output "There is no exit [#{direction}]."
        else
            broadcast "#{self} leaves #{direction}.", target({ :not => self, :room => @room })
            output "You leave #{direction}."
            @room = @room.exits[ direction.to_sym ]
            broadcast "#{self} has arrived.", target({ :not => self, :room => @room })
            @game.do_command self, "look"
            # cmd_look
        end
    end

    def condition
        percent = ( 100 * @hitpoints ) / @maxhitpoints
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

    def to_s
        @short_description
    end

    def long
        @long_description
    end

end