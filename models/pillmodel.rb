class PillModel < ConsumableModel

    def initialize(id, row)
        super(id, row)
    end

    def self.item_class_name
        "pill".freeze
    end

    def self.item_class
        return Pill
    end

end
