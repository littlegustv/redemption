class Room < GameObject

    attr_accessor :exits, :area, :continent, :mobiles, :players, :mobile_count

    def initialize( name, description, sector, area, flags, hp_regen, mana_regen, game, exits = {} )
        @exits = { north: nil, south: nil, east: nil, west: nil, up: nil, down: nil }
        @exits.each do | direction, room |
            if not exits[ direction ].nil?
                @exits[ direction ] = exits[ direction ]
            end
        end
        @description = description
        @sector = sector
        @area = area
        @flags = flags
        @hp_regen = hp_regen
        @mana_regen = mana_regen
        @continent = area.continent
        @mobiles = []
        @players = []
        @mobile_count = {}
        super name, game
    end

    def show( looker )
        if looker.can_see? self
            "#{ @name }\n" +
            "#{ @description }\n" +
            "\n" +
            "[Exits: #{ @exits.select { |direction, room| not room.nil? }.keys.join(", ") }]" +
            @game.target({ :room => self, :not => looker, type: ["Item", "Weapon"], visible_to: looker, quantity: 'all' }).map{ |t| "\n      #{t.long}" }.join +
            @game.target({ :room => self, :not => looker, type: ["Player", "Mobile"], visible_to: looker, quantity: 'all' }).map{ |t| "\n#{t.long}" }.join
        else
            "You can't see a thing!"
        end
    end

    def mobile_arrive(mobile)
        if mobile.is_player?
            @players.push(mobile)
        else
            @mobiles.push(mobile)
            @mobile_count[mobile.id] = @mobile_count[mobile.id].to_i + 1
            @mobile_count.delete[mobile_id] if @mobile_count[mobile.id] == 0
        end
    end

    def mobile_depart(mobile)
        if mobile.is_player?
            @players.delete(mobile)
        else
            @mobiles.delete(mobile)
            @mobile_count[mobile.id] = @mobile_count[mobile.id] - 1
            @mobile_count.delete[mobile_id] if @mobile_count[mobile.id] == 0
        end
    end

end
