class ContainerModel < ItemModel

    attr_reader :max_item_weight
    attr_reader :weight_multiplier
    attr_reader :max_total_weight
    attr_reader :key_id

    def initialize(id, row)
        super(id, row)
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
