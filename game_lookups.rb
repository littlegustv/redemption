class Game

    #
    # Returns the Affect Class for a given ID.
    #
    # @param [Integer] id The ID of the affect class.
    #
    # @return [Class, nil] The Afect Class, or `nil` if there isn't one.
    #
    def affect_class_with_id(id)
        return @affect_class_hash.dig(id)
    end

    #
    # Returns the Direction for a given Symbol. Constructs one if necessary.
    #
    # @param [Symbol] symbol The given symbol.
    #
    # @return [Direction] The direction.
    #
    def direction_with_symbol(symbol)
        if !(d = @direction_lookup[symbol])
            log ("No direction with symbol #{symbol} found. Creating one now.")
            id = (@directions.keys.min || 0) - 1
            d = Direction.new({
                id: id,
                name: symbol.to_s,
                symbol: symbol
            })
            @direction_lookup[symbol] = d
            @directions[id] = d
        end
        return d
    end

    #
    # Returns an Element for a given Symbol. Constructs one if necessary.
    #
    # @param [Symbol] symbol The given symbol.
    #
    # @return [Element] The element.
    #
    def element_with_symbol(symbol)
        if !(e = @element_lookup[symbol])
            log ("No element with symbol #{symbol} found. Creating one now.")
            id = (@elements.keys.min || 0) - 1
            e = Element.new({
                id: id,
                name: symbol.to_s,
            })
            @element_lookup[symbol] = e
            @elements[id] = e
        end
        return e
    end

    #
    # Returns the Gender for a given Symbol. Constructs one if necessary.
    #
    # @param [Symbol] symbol The given Symbol.
    #
    # @return [Gender] The Gender.
    #
    def gender_with_symbol(symbol)
        if !(g = @gender_lookup[symbol])
            log ("No gender with symbol #{symbol} found. Creating one now.")
            id = (@genders.keys.min || 0) - 1
            g = Gender.new({
                id: id,
                name: symbol.to_s,
                personal_objective: "it",
                personal_subjective: "it",
                possessive: "its",
                reflexive: "itself",
            })
            @gender_lookup[symbol] = g
            @genders[id] = g
        end
        return g
    end

    #
    # Returns the Genre for a given Symbol. Constructs one if necessary.
    #
    # @param [Symbol] symbol The given symbol.
    #
    # @return [Genre] The genre.
    #
    def genre_with_symbol(symbol)
        if !(g = @genre_lookup[symbol])
            log ("No genre with symbol #{symbol} found. Creating one now.")
            id = (@genres.keys.min || 0) - 1
            g = Genre.new({
                id: id,
                name: symbol.to_s,
            })
            @genre_lookup[symbol] = g
            @genres[id] = g
        end
        return g
    end

    #
    # Returns a Material for a given Symbol. Constructs one if necessary.
    #
    # @param [Symbol] symbol The given symbol.
    #
    # @return [Material] The material.
    #
    def material_with_symbol(symbol)
        if !(m = @material_lookup[symbol])
            log ("No material with symbol #{symbol} found. Creating one now.")
            id = (@materials.keys.min || 0) - 1
            m = Material.new({
                id: id,
                name: symbol.to_s,
            })
            @material_lookup[symbol] = m
            @materials[id] = m
        end
        return m
    end

    #
    # Returns the noun for a given Symbol. Constructs one if necessary.
    #
    # @param [Symbol] symbol The given symbol.
    #
    # @return [Noun] The noun.
    #
    def noun_with_symbol(symbol)
        if !(n = @noun_lookup[symbol])
            log ("No noun with symbol #{symbol} found. Creating one now.")
            copy_noun = @nouns.values.first
            if !copy_noun
                log ("No nouns exist. That's going to be a problem!")
                return nil
            end
            id = (@nouns.keys.min || 0) - 1
            n = Noun.new({
                id: id,
                name: symbol.to_s,
                element: copy_noun.element.id,
                magic: copy_noun.magic,
            })
            @noun_lookup[symbol] = n
            @nouns[id] = n
        end
        return n
    end

    #
    # Returns a position for a given Symbol. Constructs one if necessary.
    #
    # @param [Symbol] symbol The given symbol.
    #
    # @return [Position] The position.
    #
    def position_with_symbol(symbol)
        if !(p = @position_lookup[symbol])
            log ("No position with symbol #{symbol} found. Creating one now.")
            id = (@positions.keys.min || 0) - 1
            p = Position.new({
                id: id,
                name: symbol.to_s,
                value: 0,
            })
            @position_lookup[symbol] = p
            @positions[id] = p
        end
        return p
    end

    #
    # Returns a sector for a given Symbol. Constructs one if necessary.
    #
    # @param [Symbol] symbol The given symbol.
    #
    # @return [Sector] The sector.
    #
    def sector_with_symbol(symbol)
        if !(s = @sector_lookup[symbol])
            log ("No sectors with symbol #{symbol} found. Creating one now.")
            id = (@sectors.keys.min || 0) - 1
            s = Sector.new({
                id: id,
                name: symbol.to_s,
            })
            @sector_lookup[symbol] = s
            @sectors[id] = s
        end
        return s
    end

    #
    # Returns the Size for a given Symbol. Constructs one if necessary.
    #
    # @param [Symbol] symbol The given symbol.
    #
    # @return [Size] The size.
    #
    def size_with_symbol(symbol)
        if !(s = @size_lookup[symbol])
            log ("No sizes with symbol #{symbol} found. Creating one now.")
            id = (@sizes.keys.min || 0) - 1
            s = Size.new({
                id: id,
                name: symbol.to_s,
                value: 0,
            })
            @size_lookup[symbol] = s
            @sizes[id] = s
        end
        return s
    end

    #
    # Returns the stat for a given Symbol. Constructs one if necessary.
    #
    # @param [Symbol] symbol The given symbol.
    #
    # @return [Stat] The stat.
    #
    def stat_with_symbol(symbol)
        if !(s = @stat_lookup[symbol])
            log ("No stats with symbol #{symbol} found. Creating one now.")
            id = (@stats.keys.min || 0) - 1
            s = Stat.new({
                id: id,
                name: symbol.to_s
            })
            @stat_lookup[symbol] = s
            @stats[id] = s
        end
        return s
    end

    #
    # Returns the wear location for a given Symbol. Constructs one if necessary.
    #
    # @param [Symbol] symbol The given symbol.
    #
    # @return [WearLocation] The wear location.
    #
    def wear_location_with_symbol(symbol)
        if !(w = @wear_location_lookup[symbol])
            log ("No wear locations with symbol #{symbol} found. Creating one now.")
            id = (@stats.keys.min || 0) - 1
            w = WearLocation.new({
                id: id,
                name: symbol.to_s
            })
            @wear_location_lookup[symbol] = w
            @wear_locations[id] = w
        end
        return w
    end

end
