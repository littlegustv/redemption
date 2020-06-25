#
# The Model for Potion items.
#
class PotionModel < ConsumableModel

    def initialize(id, row, temporary = true)
        super(id, row, temporary)
    end

    def self.item_class_name
        "potion".freeze
    end

    def self.item_class
        return Potion
    end

end
