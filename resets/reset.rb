# Base reset class to contain basic variables and logic.
# This class contains essentially everything except actual
# repop logic and variables, eg: mobile id, room id, etc.
#
# Resets are added to Game when they activate, 
#
#
class Reset

    # @return [Float] The time when this reset is going to pop.
    attr_reader :pop_time

    def initialize(timer)
        @timer = timer.to_f
        @pop_time = 0
        @active = false
    end

    #
    # Called when the time for reset has come to determine if the reset was successful.
    # If unsuccesful, the reset is not requeued for a new pop by game and instead is discarded.
    # 
    # @return [Boolean] True if the reset is ready to pop, otherwise false.
    #
    def success?
        # if something # possibility of event interception?
        #     self.activate
        # end
        if !@active
            return false
        end
        @active = false
        return true
    end

    # handle actual repop logic. overridden by subclasses for actual gameobjects

    #
    # Perform the reset. Override in subclasses - Reset#pop shouldn't ever be called.
    # Interfaces with Game.instance to generate its objects or maintain its parent state (for doors).
    #
    # @return [nil]
    #
    def pop
        # Reset.pop never called: only overrides!
        log("{rBase reset #pop called - should only ever call overrides!{x")
        return 
    end
    
    #
    # Set the reset as active and queue it for a pop in Game.
    #
    # @param [Boolean] instant Set to true if the reset should pop immediately.
    #
    # @return [nil]
    #
    def activate(instant = false)
        if @active # already active, just return
            return
        end
        @active = true
        if instant
            @pop_time = 0
        else
            @pop_time = Game.instance.frame_time + @timer
        end
        Game.instance.activate_reset(self)
        return
    end

    #
    # Sets the reset to be inactive.
    #
    # @return [nil]
    #
    def deactivate
        @active = false
        return
    end

end
