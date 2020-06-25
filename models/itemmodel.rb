#
# Base Item Model. Gets subclassed for different item types.
# Items are passed in a model when they are created and have access 
# to their model from creation until they are destroyed. 
#
class ItemModel < KeywordedModel

    # @return [Integer] The ID of the item.
    attr_reader :id

    # @return [String] The name of the item.
    attr_reader :name

    # @return [String] The short description of the item.
    attr_reader :short_description

    # @return [Integer] The level of the item.
    attr_reader :level

    # @return [Float] The weight of the item.
    attr_reader :weight

    # @return [Integer] The cost of the item.
    attr_reader :cost

    # @return [Material] The Material of the item.
    attr_reader :material

    # @return [Array<WearLocation>, nil] The wear locations for the item, or nil if there are none.
    attr_reader :wear_locations

    # @return [Booleamn] True if the item cannot be picked up.
    attr_reader :fixed

    # @return [Array<AffectModel>, nil] The affects attached to the Item, or nil if there are none.
    attr_reader :affect_models

    # @return [Hash{Stat => Integer}] The stat modifiers for the item, or nil if there are none.
    attr_reader :modifiers

    def initialize(id, row, temporary = true)
        super(temporary, row[:keywords].split(","))
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

    #
    # The name of the item's type. This is used when loading items from the database to make Models
    # of the correct subclass.
    #
    # @return [String] The type name.
    #
    def self.item_class_name
        "item".freeze
    end

    #
    # The actual class of Item to make when constructing a new item using this model.
    # Overridden in subclasses.
    #
    # @return [Class] The Class of Item that this model generates.
    #
    def self.item_class
        return Item
    end

end
