#
# A Sublcass of model that owns a Keywords object.
#
class KeywordedModel < Model

    # @return [Keywords] The Keywords owned by this Model.
    attr_reader :keywords

    #
    # KeywordedModel initializer
    #
    # @param [Boolean] temporary Whether or not this model is temporary.
    # @param [Array<String>] keyword_array An Array of strings to turn into a Keywords object.
    #
    def initialize(temporary, keyword_array)
        super(temporary)
        @keywords = Keywords.keywords_for_array(keyword_array)
    end

    #
    # Make the Model clean up its Keywords object.
    #
    # @return [nil]
    #
    def destroy
        if @keywords
            @keywords.decrement_use_count
            @keywords = nil
        end
        super
        return
    end

end
 