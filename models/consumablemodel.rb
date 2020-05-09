class ConsumableModel < ItemModel

    attr_reader :ability_instances

    def initialize(id, row)
        super(id, row)
        @ability_instances = row[:ability_instances]
    end

    def self.item_class_name
        "consumable".freeze
    end

    def self.item_class
        return Consumable
    end

end
