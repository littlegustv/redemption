
module GameLookups

    def affect_class_with_id(id)
        return @affect_class_hash.dig(id)
    end

    def element_with_symbol(symbol)
        if !@element_lookup
            @element_lookup = @elements.values.map { |e| [e.symbol, e] }.to_h
        end
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

    def gender_with_symbol(symbol)
        if !@gender_lookup
            @gender_lookup = @genders.values.map { |g| [g.symbol, g] }.to_h
        end
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

    def genre_with_symbol(symbol)
        if !@genre_lookup
            @genre_lookup = @genres.values.map { |g| [g.symbol, g] }.to_h
        end
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

    def material_with_symbol(symbol)
        if !@material_lookup
            @material_lookup = @materials.values.map { |m| [m.symbol, m] }.to_h
        end
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

    def noun_with_symbol(symbol)
        if !@noun_lookup
            @noun_lookup = @nouns.values.map { |n| [n.symbol, n] }.to_h
        end
        if !(n = @noun_lookup[symbol])
            log ("No noun with symbol #{symbol} found. Creating one now.")
            copy_noun = @nouns.values.first
            if !copy_noun
                log ("No nouns exist. That's going to be a problem!")
                return nil
            end
            id = (@nouns.keys.min || 0) - 1
            n = Noun.new({
                id: new_id,
                name: symbol.to_s,
                element: copy_noun.element.id,
                magic: copy_noun.magic,
            })
            @noun_lookup[symbol] = n
            @nouns[id] = n
        end
        return n
    end

    def position_with_symbol(symbol)
        if !@position_lookup
            @position_lookup = @positions.values.map { |p| [p.symbol, p] }.to_h
        end
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

    def sector_with_symbol(symbol)
        if !@sector_lookup
            @sector_lookup = @sectors.values.map { |s| [s.symbol, s] }.to_h
        end
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

    def size_with_symbol(symbol)
        if !@size_lookup
            @size_lookup = @sizes.values.map { |s| [s.symbol, s] }.to_h
        end
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

    def stat_with_symbol(symbol)
        if !@stat_lookup
            @stat_lookup = @stats.values.map { |s| [s.symbol, s] }.to_h
        end
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

end
