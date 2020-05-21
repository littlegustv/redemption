class KeywordedModel < Model

    attr_reader :keywords

    def initialize(temporary, keyword_string)
        super(temporary)
        @keywords = Game.instance.global_keyword_set_for_keyword_string(keyword_string.to_s)
    end

    def destroy
        super
        Game.instance.decrement_keyword_set(@keywords)
    end

    def keywords
        @keywords || Set.new
    end

end
