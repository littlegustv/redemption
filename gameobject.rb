class GameObject

    attr_accessor :name, :keywords, :affects, :uuid, :active, :short_description, :long_description
    attr_accessor :reset
    attr_reader :room, :gender
    attr_reader :source_affects

    def initialize( name, keywords, reset = nil )
        @name = name
        if keywords
            @keyword_string = keywords.to_a.join(" ".freeze).downcase
            @keywords = Set.new
            keywords.to_a.each do |keyword|
                keyword_string = keyword.downcase
                while keyword_string.length > 0
                    @keywords.add(keyword_string.to_sym)
                    keyword_string.chop!
                end
            end
        else
            @keyword_string = "".freeze
            @keywords = nil
        end
        @reset = reset
        @affects = []
        @source_affects = []

        @uuid = Game.instance.new_uuid
        @active = true
        @gender = Game.instance.genders.values.first
    end

    # handles its own destruction - override in subclasses but call +super+ !
    def destroy
        self.deactivate
        @affects.dup.each do |affect|
            affect.clear(true)
        end
    end

    def deactivate
        @active = false
    end

    def update( elapsed )
        # @affects.each { |aff| aff.update( elapsed ) }
    end

    def output( message, objects = [] )
    end

    def target( query )
        Game.instance.target query
    end

    def responds_to_event(event)
        Game.instance.responds_to_event(self, event)
    end

    def to_a
        [ self ]
    end

    def to_s
        self.name.to_s
    end

    def to_someone
        "someone"
    end

    def show( looker )
        if looker.can_see? self
            return self.long_auras + self.name.to_s
        else
            return to_someone
        end
    end

    def fuzzy_match( query )
        if query == [""]
            query = Set.new
        end
        return @keywords.superset?(query)
    end

    # def fuzzy_match( query )
    #     query.to_a.all?{ |q|
    #         @keywords.any?{ |keyword|
    #             keyword.fuzzy_match( q )
    #         }
    #     }
    # end

    def can_see?(target)
        true
    end

    def filter_visible_targets(targets, limit = nil)
        vis_targets = []
        if limit
            count = 0
            targets.each do |t|
                if can_see?(t)
                    vis_targets.push(t)
                    count += 1
                end
                if count == limit
                    return vis_targets
                end
            end
        else
            vis_targets = targets.select{ |t| can_see?(t) }
        end
        return vis_targets
    end

    # Returns true if the GameObject is affected by an Affect with a matching keyword.
    # Exact match only!
    def affected?( key )
        @affects.select{ |affect| affect.check(key) }.count > 0
    end

    # Applies an affect using a matching id.
    # +id+:: id of an affect.
    # +silent+:: true if the affects should not output messages
    # +array+:: array to add affects onto
    #  some_mobile.apply_affect_with_id(AffectBlind.id)
    #
    def apply_affect_with_id(id, silent = false, array = nil, data = nil)
        affect_class = Game.instance.affect_class_with_id(id)
        if affect_class
            affect = affect_class.new(self, self, 0)
            affect.savable = false
            affect.permanent = true
            if data
                affect.overwrite_data(data)
            end
            result = affect.apply(silent)
            array << affect if array && result
        end
    end

    def apply_affect_model(affect_model, silent = true, array = nil)
        if affect_model.affect_class
            affect = affect_model.affect_class.new(self, self, 0)
            affect.savable = false
            affect.permanent = true
            if affect_model.data
                affect.overwrite_data(affect_model.data)
            end
            result = affect.apply(silent)
            array << affect if array && result
        end
    end

    # Remove all affects by a given keyword
    # +term+:: The keyword to match
    def remove_affect(term)
        list = @affects.select{ |a| a.check( term )  }
        list.each do |affect|
            affect.clear(false)
        end
    end

    # Generates a hash to provide affect source fields for the database
    def db_source_fields
        source_data = { source_type: self.db_source_type,
                        source_uuid: @uuid,
                        source_id: (self.respond_to?(:id)) ? self.id : 0 }
        return source_data
    end

    # Override this in subclasses to generate correct source_type strings
    def db_source_type
        return "GameObject"
    end

    # Show the affects on this object to an observer
    def show_affects(observer:, show_hidden: false, full: true)
        prefix = "#{show(self)} is"
        if self == observer
            prefix = "You are"
        end
        affs_to_show = self.affects
        if !show_hidden
            affs_to_show = affs_to_show.reject(&:hidden?)
        end
        text = ( full ? "#{prefix} affected by the following spells:\n" : "" )
        if affs_to_show.empty?
            return ( full ? "#{prefix} not affected by any spells." : "")
        else
            return "#{text}#{ affs_to_show.map(&:summary).join("\n") }"
        end
    end

    # string used for locate object, etc
    # <some item> is _in_ <some item>
    def carried_by_string
        return "in"
    end

    # Pronouns

    # %O -> personal_objective_pronoun (him, her, it)
    def personal_objective_pronoun
        return @gender.personal_objective
    end

    # %U -> personal_subjective_pronoun (he, she, it)
    def personal_subjective_pronoun
        return @gender.personal_subjective
    end

    # %P -> possessive_pronoun (his, her, its)
    def possessive_pronoun
        return @gender.possessive
    end

    # %O -> reflexive_pronoun (himself, herself, itself)
    def reflexive_pronoun
        return @gender.reflexive
    end

    # Indefinite name/description/pronouns
    # these are to be used if the gameobject cannot be seen - override in subclasses

    def indefinite_name
        return "something"
    end

    def indefinite_short_description
        return "something"
    end

    def indefinite_long_description
        return "something"
    end

    # %O -> personal_objective_pronoun (him, her, it)
    def indefinite_personal_objective_pronoun
        return "it"
    end

    # %U -> personal_subjective_pronoun (he, she, it)
    def indefinite_personal_subjective_pronoun
        return "it"
    end

    # %P -> possessive_pronoun (his, her, its)
    def indefinite_possessive_pronoun
        return "its"
    end

    # %R -> reflexive_pronoun (himself, herself, itself)
    def indefinite_reflexive_pronoun
        return "itself"
    end

    # Resolving of name/descriptions/pronouns of another object

    def resolve_name(target)
        if target == self
            return "you".freeze
        end
        if can_see?(target)
            return target.name
        else
            return target.indefinite_name
        end
    end

    def resolve_short_description(target)
        if can_see?(target)
            return target.short_description
        else
            return target.indefinite_short_description
        end
    end

    def resolve_long_description(target)
        if can_see?(target)
            return target.long_description
        else
            return target.indefinite_long_description
        end
    end

    # personal_objective_pronoun (him, her, it, you)
    def resolve_personal_objective_pronoun(target)
        if target == self
            return "you".freeze
        end
        if can_see?(target)
            return target.personal_objective_pronoun
        else
            return target.indefinite_personal_objective_pronoun
        end
    end

    # personal_subjective_pronoun (he, she, it, you)
    def resolve_personal_subjective_pronoun(target)
        if target == self
            return "you".freeze
        end
        if can_see?(target)
            return target.personal_subjective_pronoun
        else
            return target.indefinite_personal_subjective_pronoun
        end
    end

    # possessive_pronoun (his, her, its, your)
    def resolve_possessive_pronoun(target)
        if target == self
            return "your".freeze
        end
        if can_see?(target)
            return target.possessive_pronoun
        else
            return target.indefinite_possessive_pronoun
        end
    end

    # reflexive_pronoun (himself, herself, itself, yourself)
    def resolve_reflexive_pronoun(target)
        if target == self
            return "yourself".freeze
        end
        if can_see?(target)
            return target.reflexive_pronoun
        else
            return target.indefinite_reflexive_pronoun
        end
    end

    # aura string generation
    def short_auras
        data = { description: "" }
        Game.instance.fire_event( self, :event_calculate_short_auras, data )
        return data[:description]
    end

    def long_auras
        data = { description: "" }
        Game.instance.fire_event( self, :event_calculate_long_auras, data )
        return data[:description]
    end
end
