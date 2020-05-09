class PotionModel < ConsumableModel

    def initialize(id, row)
        super(id, row)
    end

    def self.item_class_name
        "potion".freeze
    end

    def self.item_class
        return Potion
    end

end
