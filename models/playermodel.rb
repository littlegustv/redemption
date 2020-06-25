#
# The Model for Players.
#
class PlayerModel < MobileModel

    # @return [Integer] The player's creation points.
    attr_reader :creation_points

    # @return [Integer] The player's account's id.
    attr_reader :account_id

    def initialize(id, row)
        super(id, row, true)
        @creation_points = row[:creation_points] || 0
        @account_id = row[:account_id] || 0

        @short_description = @name
        @long_description = "#{@name} the Master Rune Maker is here."
    end

end
