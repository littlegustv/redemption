class LightModel < ItemModel

    def initialize(id, row)
        super(id, row)
    end

    def self.item_class_name
        "light".freeze
    end

    def self.item_class
        return Light
    end

end
