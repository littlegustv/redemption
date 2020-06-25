#
# The Model for Light Items.
#
class LightModel < ItemModel

    def initialize(id, row, temporary = true)
        super(id, row, temporary)
    end

    def self.item_class_name
        "light".freeze
    end

    def self.item_class
        return Light
    end

end
