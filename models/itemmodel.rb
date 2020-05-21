class ItemModel < KeywordedModel

    attr_reader :id
    attr_reader :name
    attr_reader :short_description
    attr_reader :item_type
    attr_reader :level
    attr_reader :weight
    attr_reader :cost
    attr_reader :material
    attr_reader :wear_locations
    attr_reader :fixed

    attr_reader :affect_models
    attr_reader :modifiers

    def initialize(id, row, temporary = true)
        super(temporary, row[:keywords])
        @temporary = temporary
        @id = id
        @name = row[:name].to_s
        @short_description = row[:short_description].to_s
        @level = row[:level] || 0
        @weight = row[:weight] || 0
        @cost = row[:cost] || 0
        @fixed = row[:fixed] || false

        # material
        if row.dig(:material_id)
            @material = Game.instance.materials[row[:material_id]]
        elsif row.dig(:material)
            @material = row[:material]
        else
            @material = Game.instance.materials.values.first
        end

        # wear locations
        if row.dig(:wear_locations)
            @wear_locations = row[:wear_locations]
        else
            @wear_locations = nil
        end

        # modifiers
        if row.dig(:modifiers)
            @modifiers = row[:modifiers]
        else
            @modifiers = nil
        end

        # affect models

        if row.dig(:affect_models)
            @affect_models = row[:affect_models]
        else
            @affect_models = nil
        end
    end

    def self.item_class_name
        "item".freeze
    end

    def self.item_class
        return Item
    end

end
