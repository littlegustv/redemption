class KeywordedModel < Model

    attr_reader :keywords

    def initialize(temporary, keywords)
        super(temporary)
        @keywords = Keywords.keywords_for_array(keywords)
    end

    def destroy
        super
        if @keywords
            @keywords.decrement_use_count
            @keywords = nil
        end
    end

    def keywords
        @keywords
    end

end
 