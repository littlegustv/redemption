class Mobile < GameObject

    attr_accessor :room, :attacking

    @attacking

    def initialize( name, game, room )
        @room = room
        @attack_speed = rand(2...4)
        @hitpoints = 500
        @hitroll = rand(5...7)
        @noun = ["entangle", "grep", "strangle", "pierce", "smother", "flaming bite"].sample
        @position = Position::STAND
        super name, game
    end

    def update( elapsed )
        super elapsed
    end

    def start_combat( attacker )
        # if they are already fighting you, i.e. they started it
        @position = Position::FIGHT
        if attacker && attacker.attacking == self
            # fix me: replace with call to cmd_yell (also needs to be created)
            broadcast "#{@name} yells 'Help I am being attacked by #{ attacker.name }!", target({ not: self })
            output "You yell 'Help I am being attacked by #{ attacker.name }!"
        end
        if @attacking.nil?
            @attacking = attacker
        end
    end

    def stop_combat
        @attacking = nil
        @position = Position::STAND
        # fix me: how to know what position to set everyone who was attacking ME, since they might still be being attacked??
        target({ attacking: self }).each { |t| t.attacking = nil }
    end

    def combat
        if @attacking
            to_me = []
            to_target = []
            to_room = []
            @attack_speed.times do |attack|
                if rand(0...10) < @hitroll
                    damage = rand(1...20)
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
        decorators = Constants::DAMAGE[damage]
        texts = ["Your #{decorators[2]} #{@noun} #{decorators[1]} #{@attacking.name}", "#{@name}'s' #{decorators[2]} #{@noun} #{decorators[1]} you", "#{@name}'s' #{decorators[2]} #{@noun} #{decorators[1]} #{@attacking.name}"]
    end

    def damage( damage )
        @hitpoints -= damage
        die if @hitpoints <= 0
    end

    def die
        output "You have been KILLED!"
        broadcast "#{@name} has been KILLED.", target({ not: [ self ] })
        stop_combat
    end

end
