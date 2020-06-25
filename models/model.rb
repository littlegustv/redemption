#
# A Model is the container class for information for a live object in the game.
# They are used to instantiate new objects. (items, mobiles, affects)
#
class Model

    # @return [Boolean] Whether or not the Model is temporary, i.e. is destroyed when its final instanced object is destroyed.
    attr_reader :temporary

    def initialize(temporary)
        # @type [Boolean]
        @temporary = temporary
        # @type [Integer]
        @instance_count = 0
    end

    #
    # Increment the count of instance objects using this model.
    #
    # @return [nil]
    #
    def increment_use_count
        if @temporary 
            @instance_count += 1
        end
        return
    end

    #
    # Decrement the count of instance objects using this model.
    #
    # @return [nil]
    #
    def decrement_use_count
        if @temporary
            @instance_count -= 1
            if @instance_count == 0
                destroy
            end
        end
        return
    end

    #
    # Called if this model is temporary and is no longer used by anthing.
    #
    # @return [nil]
    #
    def destroy

    end

end
