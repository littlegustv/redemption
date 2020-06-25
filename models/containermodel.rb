#
# The Model for Container items.
#
class ContainerModel < ItemModel

    # @return [Float] The Maximum allowed weight of a single item in the container.
    attr_reader :max_item_weight

    # @return [Integer] The multiplier for the weight of items inside this container.
    attr_reader :weight_multiplier

    # @return [Integer] The maximum cumulative weight of items in the container.
    attr_reader :max_total_weight

    # @return [Integer, nil] The ID of the key for this container.
    attr_reader :key_id

    def initialize(id, row, temporary = true)
        super(id, row, temporary)
        @max_item_weight = row[:max_item_weight]
        @weight_multiplier = row[:weight_multiplier]
        @max_total_weight = row[:max_total_weight]
        @key_id = row[:key_id]

    end

    def self.item_class_name
        "container".freeze
    end

    def self.item_class
        return Container
    end

end
