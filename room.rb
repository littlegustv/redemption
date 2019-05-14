class Room < GameObject

    attr_accessor :exits, :area

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
        super name, game
    end

    def show( looker )
# <#{ @area.name }>
# <#{ @sector }>
# <#{ @flags.join(", ") }>
# <#{ @hp_regen } hp, #{ @mana_regen } mana >
        %Q(
#{ @name }
#{ @description }

[Exits: #{ @exits.select { |direction, room| not room.nil? }.keys.join(", ") }]
#{ @game.target({ :room => self, :not => looker, type: ["Player", "Mobile", "Item", "Weapon"] }).map{ |t| "#{t.long}" }.join("\n") }
        )
    end

end
