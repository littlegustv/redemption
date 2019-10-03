class Room < GameObject

    attr_accessor :area
    attr_accessor :continent
    attr_accessor :exits

    attr_reader :id
    attr_reader :inventory
    attr_reader :mobiles
    attr_reader :mobile_count
    attr_reader :players

    def initialize( id, name, description, sector, area, flags, hp_regen, mana_regen, game, exits = {} )
        super(name, game)
        @exits = { north: nil, south: nil, east: nil, west: nil, up: nil, down: nil }
        @exits.each do | direction, room |
            if not exits[ direction ].nil?
                @exits[ direction ] = exits[ direction ]
            end
        end
        @id = id
        @description = description
        @sector = sector
        @area = area
        @flags = flags
        @hp_regen = hp_regen
        @mana_regen = mana_regen
        @continent = area.continent
        @mobiles = []
        @mobile_count = {}
        @players = []
        @inventory = Inventory.new(owner: self, game: @game)
    end

    def show( looker )
        if looker.can_see? self

            out = "#{ @name }\n" +
            "#{ @description }\n" +
            "[Exits: #{ @exits.select { |direction, room| not room.nil? }.keys.join(", ") }]"
            item_list = @inventory.show(observer: looker, long: true)
            out += "\n#{item_list}" if item_list.length > 0
            occupant_list = @game.target({ list: self.occupants, :not => looker, visible_to: looker, quantity: 'all' }).map{ |t| "#{t.long}" }.join("\n")
            out += "\n#{occupant_list}" if occupant_list.length > 0
            return out
        else
            return "You can't see a thing!"
        end
    end

    def mobile_arrive(mobile)
        if mobile.is_player?
            @players.delete(mobile)
            @players.push(mobile)
        else
            @mobiles.push(mobile)
            @mobile_count[mobile.id] = @mobile_count[mobile.id].to_i + 1
            @mobile_count.delete(mobile.id) if @mobile_count[mobile.id] <= 0
        end
    end

    def mobile_depart(mobile)
        if mobile.is_player?
            @players.delete(mobile)
        else
            @mobiles.delete(mobile)
            @mobile_count[mobile.id] = @mobile_count[mobile.id] - 1
            @mobile_count.delete(mobile.id) if @mobile_count[mobile.id] <= 0
        end
    end

    # Returns true if the room contains ALL mobiles (an array of players and/or mobiles)
    def contains?(mobiles)
        return (mobiles.to_a - occupants).empty?
    end

    def occupants
        return @mobiles | @players
    end

    def items
        return @inventory.items
    end

    def db_source_type
        return "Room"
    end

    # sort of a hack to add a room method to items
    def room
        return self
    end

end
