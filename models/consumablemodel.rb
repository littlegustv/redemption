#
# Model for Consumables (Pills, Potions)
#
class ConsumableModel < ItemModel

    # @return [Array<Array<Command, Integer>>] An array of Command and integer
    #   pairs representing Abilities and their levels.  
    #   eg. `[[(SpellHaste instance), 51], [(SpellBlur instance), 25]]`
    attr_reader :ability_instances

    def initialize(id, row, temporary = true)
        super(id, row, temporary)
        @ability_instances = row[:ability_instances]
    end

    def self.item_class_name
        "consumable".freeze
    end

    def self.item_class
        return Consumable
    end

end
