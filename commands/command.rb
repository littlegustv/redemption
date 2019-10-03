class Command

    attr_reader :priority, :name

    # Set what you need to here, but most of it is overwritten by values in the database,
    # if they can be found.
    def initialize(
        game: nil,
        name: "defaultcommand",
        priority: 100,
        keywords: ["defaultcommand"],
        lag: 0,
        usable_in_combat: true,
        position: Position::SLEEP,
        hp_cost: 0,
        mana_cost: 0,
        movement_cost: 0
    )
        @game = game
        @priority = priority
        @keywords = keywords
        @lag = lag
        @name = name
        @usable_in_combat = usable_in_combat
        @position = position
        @hp_cost = hp_cost
        @mana_cost = mana_cost
        @movement_cost = movement_cost
        @data = {}
    end

    def check( cmd )
        @keywords.select{ |keyword| keyword.fuzzy_match( cmd ) }.any?
    end

    def to_s
        @name
    end

    def execute( actor, cmd, args )
        if actor.position < @position # Check position
            case actor.position
            when Position::SLEEP
                actor.output "In your dreams, or what?"
            when Position::REST
                actor.output "Nah... You feel too relaxed..."
            else
                actor.output "You can't quite get comfortable enough."
            end
            return false
        end
        if actor.attacking && !@usable_in_combat
            actor.output "No way! You're still fighting!"
            return false
        end

        success = attempt( actor, cmd, args )
        actor.lag += @lag if success
        return success
    end

    def attempt( actor, cmd, args )
        actor.output "Default command"
    end

    # overwrite attributes using values from the database
    def overwrite_attributes(new_attr_hash)
        @priority = new_attr_hash[:priority].to_i
        @keywords = new_attr_hash[:keywords].to_s.split(",")
        @keywords = [""] if @keywords.empty?
        @lag = new_attr_hash[:lag].to_i
        @name = new_attr_hash[:name].to_s
        @usable_in_combat = !(new_attr_hash[:usable_in_combat].to_i.zero?)
        new_position = Position::STRINGS.select{ |k, v| v == new_attr_hash[:position].to_s }.first
        if new_position
            @position = new_position[0]
        end
        @hp_cost = new_attr_hash[:hp_cost].to_i
        @mana_cost = new_attr_hash[:mana_cost].to_i
        @movement_cost = new_attr_hash[:movement_cost].to_i
        data_string = new_attr_hash[:data]
        if data_string && data_string.length > 0
            data = JSON.parse(data_string, symbolize_names: true)
        end
    end

end
