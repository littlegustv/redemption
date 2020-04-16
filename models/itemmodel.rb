class ItemModel

    attr_reader :id
    attr_reader :name
    attr_reader :keywords
    attr_reader :short_description
    attr_reader :item_type
    attr_reader :level
    attr_reader :weight
    attr_reader :cost
    attr_reader :material
    attr_reader :fixed

    attr_reader :affect_models
    attr_reader :modifiers

    def initialize(id, row)
        @id = id
        @name = row[:name].to_s
        @keywords = row[:keywords].to_s.split(" ")
        @short_description = row[:short_description].to_s
        @level = row[:level] || 0
        @weight = row[:weight] || 0
        @cost = row[:cost] || 0
        if row.dig(:material_id)
            @material = Game.instance.materials[row[:material_id]]
        elsif row.dig(:material)
            @material = row[:material]
        else
            @material = Game.instance.materials.values.first
        end
        @fixed = row[:fixed] || 0

        @affect_models = []
        @modifiers = Hash.new

    end

    def self.name
        "item".freeze
    end

    def self.item_class
        return Item
    end

end
