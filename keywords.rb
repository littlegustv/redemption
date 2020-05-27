#
# The Keywords class.
#
# More or less just a wrapper for a Set<Symbol> represeting all possible
# substrings in a set of keywords.
#
# A new Keywords object is created by calling the class method
# `Keywords#keywords_for_array`.
#
class Keywords

    # @type [Hash{Integer => Keywords}] class instance variable to map Set hashes to Keywords objects.
    @keyword_hash_map = {}

    #
    # Initialize a new keyword object from a space-delimited string.
    #
    # _This should only ever be called in `Keywords.keywords_for_array`._
    # 
    # @param [Array<String>] array The string to become a set of keywords. Space delimited. 
    #
    def initialize(array)
        # @type [Set<Symbol>] The keywords and possible substrings of keywords as Symbols
        @keyword_set = Set.new
        array.to_a.dup.each do |keyword|
            while keyword.length > 0
                @keyword_set.add(keyword.to_sym)
                keyword.chop!
            end
        end
        # @type [Integer] The number of references to this keyword.
        @use_count = 0
    end

    #
    # This method <em>must</em> be called to tell the Keywords that a reference to it is no longer in use.
    #
    # If the `use_count` of the Keywords object reaches 0, the Keywords will be 
    # removed from the class keyword_hash_map.
    #
    # @return [void]
    #
    def decrement_use_count
        @use_count -= 1
        if @use_count <= 0
            self.class.remove_keywords(self)
        end
        return
    end

    #
    # Returns true if the Keywords contains the keywords in a query or string.
    #
    #   keywords.fuzzy_match("cuervo".to_query)
    #   keywords.fuzzy_match("red dragon")
    #
    # @param [String, Hash{Symbol => Integer, String, Set<Symbol>}] query A query hash.
    #
    # @return [Boolean] True if the Keywords' keyword_set contains all words in `string`.
    #
    def fuzzy_match(query)
        if query.is_a?(String)
            query = query.to_query
        end
        return self.superset?(query[:keyword])
    end

    #
    # Returns true if the Keywords set contains a given symbol.
    #
    # @param [Symbol] symbol The symbol to check for.
    #
    # @return [Boolean] True if the Keywords contain the symbol, otherwise false.
    #
    def include?(symbol)
        return @keyword_set.include?(symbol)
    end

    #
    # Return the intersection of the Keywords keyword_set and another set.
    #
    # @param [Set<Symbol>] set The set to create an intersection with.
    #
    # @return [Set<Symbol>] The resultant set.
    #
    def intersection(set)
        @keyword_set.intersection(set)
    end

    #
    # Returns true if a given set has at least one common element with the keyword_set.
    #
    # @param [Set<Symbol>] set A Set to check for intersection with.
    #
    # @return [Boolean] True if there is at least one common element, otherwise false.
    #
    def intersect?(set)
        return @keyword_set.intersect?(set)
    end

    #
    # Returns true if the Keyword's keyword_set is a superset of another set.
    #
    # @param [Set<Symbol>] set Another set.
    #
    # @return [Boolean] True if the Keyword's keyword_set is a superset of `set`.
    #
    def superset?(set)
        return @keyword_set.superset?(set)
    end

    #
    # Generate a keyword string from this set of keywords, ignoring substrings. If the set is empty,
    # return a static string instead.
    #
    # @return [String] The keyword string.
    #
    def to_s
        if @keyword_set.empty?
            return "(none)"
        else
            key_strings = @keyword_set.map(&:to_s)
            return key_strings.reject{ |x| key_strings.any?{ |y| x != y && y.start_with?(x) } }.join(" ")
        end
    end

    #
    # Returns `#hash` for the Keyword's keyword_set.
    #
    # @return [Integer] The hash of the keyword_set.
    #
    def keyword_set_hash
        return @keyword_set.hash
    end

    #
    # Increment the use count (the number of objects using the Keywords) of the Keywords.
    #
    # @return [void]
    #
    def increment_use_count
        @use_count += 1
        return
    end

    #
    # Get the symbols from the set as an array.
    #
    # @return [Array<Symbol>] The array of symbols.
    #
    def symbols
        return @keyword_set.to_a
    end

    #   
    # Returns an existing Keywords object for a given string or generates one if necessary.
    # 
    # @param [Array<String>] keyword_string The string to use to create the Keywords from.
    #   Should be a space-delimited string.
    #
    # @return [Keywords] The Keywords object for the given string.
    #
    def self.keywords_for_array(array)        
        # create a Keywords object with this string
        keywords = Keywords.new(array)
        # get the hash of the new object
        hash = keywords.keyword_set_hash
        
        # look up the hash in @keyword_hash_map
        if @keyword_hash_map.dig(hash) 
            # it exists, so swap the new Keywords object for the existing one
            keywords = @keyword_hash_map[hash]
        else
            # it doesn't exist, so place the new one in the hash.
            @keyword_hash_map[hash] = keywords
        end
        # increment the use count of the Keywords
        keywords.increment_use_count
        return keywords
    end

    #
    # Removes a keyword from the keyword_hash_map. Gets called automatically in #destroy.
    #
    # @param [Keywords] keywords The Keywords object to remove.
    #
    # @return [void]
    #
    def self.remove_keywords(keywords)
        if !@keyword_hash_map.empty?
            @keyword_hash_map.delete(keywords.keyword_set_hash)
        end
        return
    end

    #
    # Clears the existing Keyword objects from the keyword_hash_map. Call this when
    # you need to clear ALL keywords from memory, like in a server reload.
    #
    # @return [void]
    #
    def self.clear
        @keyword_hash_map.clear
        return
    end

end