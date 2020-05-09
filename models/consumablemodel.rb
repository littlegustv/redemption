class ConsumableModel < ItemModel


    def initialize(id, row)
        super(id, row)
    end

    def self.item_class_name
        "consumable".freeze
    end

    def self.item_class
        # return Consumable
    end

end
