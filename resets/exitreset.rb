#
# Exit Reset is what resets door states after they've been interacted with in the game.
#
class ExitReset < Reset

    # @return [Exit] The exit that this reset manages.
    attr_accessor :exit

    #
    # Initialize the reset.
    #
    # @param [Exit] exit The exit for the reset to manage.
    # @param [Boolean] closed True if the door is closed by default.
    # @param [Boolean] locked True if the door is locked by default.
    # @param [Integer] timer How long it takes for the door to reset its state.
    #
    def initialize( exit, closed, locked, timer )
        super(timer)
        @exit = exit
        @closed = closed
        @locked = locked
    end
    
    #
    # Perform the reset.
    # Set the exit states.
    #
    # @return [nil]
    #
    def pop
        @exit.closed = @closed
        @exit.locked = @locked
        return
    end


end
