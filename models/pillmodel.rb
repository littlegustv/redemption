class PillModel < ConsumableModel

    def initialize(id, row, temporary = true)
        super(id, row, temporary)
    end

    def self.item_class_name
        "pill".freeze
    end

    def self.item_class
        return Pill
    end

end
