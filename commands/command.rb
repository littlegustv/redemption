#
# Command base class. All Commands, Skills, and Spells inherit from this class.
#
class Command

    # @return [Integer, nil] The ID of the command.
    attr_reader :id
    # @return [Integer] The priority of the command. Higher priority commands will be selected over lower ones.
    attr_reader :priority
    # @return [String] The name of the command.
    attr_reader :name
    # @return [Integer] The creation point cost of the command.
    attr_reader :creation_points
    # @return [Float] The amount of lag applied to the actor when the command is used.
    attr_reader :lag
    # @return [Keywords] The Keywords for the Command.
    attr_reader :keywords

    # Set what you need to here, but most of it is overwritten by values in the database,
    # if they can be found.
    def initialize(
        name: "defaultcommand",
        priority: 100,
        keywords: ["defaultcommand"],
        lag: 0,
        usable_in_combat: true,
        position: :sleeping,
        hp_cost: 0,
        mana_cost: 0,
        movement_cost: 0
    )
        @id = nil
        @priority = priority
        @keywords = Keywords.keywords_for_array(keywords.to_a)
        @lag = lag
        @name = name
        @usable_in_combat = usable_in_combat
        @position = position.to_position
        @hp_cost = hp_cost
        @mana_cost = mana_cost
        @movement_cost = movement_cost
        @creation_points = 0
        @data = {}
    end

    def to_s
        @name
    end

    def execute( actor, cmd, args, input )
        if actor.position.value < @position.value # Check position
            if actor.position == :sleeping
                actor.output "In your dreams, or what?"
            elsif actor.position == :resting
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
        success = attempt( actor, cmd, args, input )
        return success
    end

    def attempt( actor, cmd, args, input )
        actor.output "Default command"
    end

    # overwrite attributes using values from the database
    def overwrite_attributes(new_attr_hash)
        @id = new_attr_hash[:id].to_i
        @priority = new_attr_hash[:priority].to_i
        @keywords.decrement_use_count
        @keywords = Keywords.keywords_for_array(new_attr_hash[:keywords])
        @lag = new_attr_hash[:lag].to_f
        @name = new_attr_hash[:name].to_s
        @usable_in_combat = new_attr_hash[:usable_in_combat]
        @creation_points = new_attr_hash[:creation_points]
        @position = Game.instance.positions[(new_attr_hash[:position_id] || 1)]
        @hp_cost = new_attr_hash[:hp_cost].to_i
        @mana_cost = new_attr_hash[:mana_cost].to_i
        @movement_cost = new_attr_hash[:movement_cost].to_i
        data_string = new_attr_hash[:data]
        if data_string && data_string.length > 0
            @data = JSON.parse(data_string, symbolize_names: true)
        end
    end

    def to_helpfile

    end

end
