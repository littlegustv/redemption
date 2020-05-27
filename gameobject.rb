class GameObject

    # @return [Array<Affect>, nil] The Array of Affects applied to this GameObject, or `nil`.
    attr_accessor :uuid, :active, :short_description, :long_description
    # @return [Reset] the Reset
    attr_accessor :reset
    attr_reader :room
    attr_reader :gender
    attr_accessor :source_affects
    # @return 
    attr_reader :cooldowns

    # Initialize a GameObject.
    # @param name [String, nil] The name of the object. `nil` probably means the name is attached to the model.
    # @param keywords [String, nil] The keywords for the object. `nil` probably means the keywords are attached to the model.
    # @param reset [Reset, nil] The Reset that generated this object, or `nil` if it has none.
    # @param model [Model, nil] The Model to associate with this object, or `nil` if it doesn't have one.
    def initialize( name, keywords, reset = nil, model = nil )
        @name = name
        @model = model
        if !model
            @name = name
        end
        @reset = reset
        @affects = nil
        @source_affects = nil
        @cooldowns = nil
        @keywords = nil
        @keywords = Keywords.keywords_for_array(keywords.to_a)

        @uuid = Game.instance.new_uuid
        @active = true
        @gender = Game.instance.genders.values.first
    end

    # handles its own destruction - override in subclasses but call +super+ !
    def destroy
        self.deactivate
        if @affects
            @affects.dup.each do |affect|
                affect.clear(true)
            end
        end
        if @keywords
            @keywords.decrement_use_count
        end
        if @model && @model.temporary
            @model.destroy
        end
        @affects = nil
        @source_affects = nil
    end

    def deactivate
        @active = false
    end

    def name
        if @model
            return @name || @model.name.to_s
        else
            return @name.to_s
        end
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
        return self.keywords.superset?(query)
    end

    def keywords
        if @model
            return @keywords || @model.keywords
        end
        @keywords || Set.new
    end

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
        if @affects
            @affects.select{ |affect| affect.check(key) }.count > 0
        else
            return false
        end
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

    #
    # Get the currently applied affects for the GameObject.
    #
    # @return [Array<Affect>] The Affects.
    #
    def affects
        return @affects.to_a
    end

    def add_affect(affect)
        if @affects.nil?
            @affects = [affect]
        else
            @affects << affect
        end
    end

    def remove_affect(affect)
        if @affects.nil?
            return
        end
        @affects.delete(affect)
        if @affects.empty?
            @affects = nil
        end
    end

    def add_source_affect(affect)
        if @source_affects.nil?
            @source_affects = [affect]
        else
            @source_affects << affect
        end
    end

    def remove_source_affect(affect)
        if @source_affects.nil?
            return
        end
        @source_affects.delete(affect)
        if @source_affects.empty?
            @source_affects = nil
        end
    end

    # Remove all affects by a given keyword
    # +term+:: The keyword to match
    def remove_affects_with_keywords(keywords)
        keywords
        list = @affects.select{ |a| a.check( term )  }
        list.each do |affect|
            affect.clear(false)
        end
    end

    # Generates a hash to provide affect source fields for the database
    def db_source_fields
        source_data = { source_type_id: self.db_source_type_id,
                        source_uuid: @uuid,
                        source_id: (self.respond_to?(:id)) ? self.id : 0 }
        return source_data
    end

    # Override this in subclasses to generate correct source_type_ids
    def db_source_type_id
        return 1
    end

    # Show the affects on this object to an observer
    def show_affects(observer:, show_hidden: false, full: true)
        prefix = "#{show(self)} is"
        if self == observer
            prefix = "You are"
        end
        affs_to_show = self.affects.to_a
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
        if responds_to_event(:event_calculate_short_auras)
            data = { description: "" }
            Game.instance.fire_event( self, :event_calculate_short_auras, data )
            return data[:description]
        else
            return ""
        end
    end

    def long_auras
        if responds_to_event(:event_calculate_long_auras)
            data = { description: "" }
            Game.instance.fire_event( self, :event_calculate_long_auras, data )
            return data[:description]
        else
            return ""
        end
    end

    def add_cooldown(symbol, timer, message = nil)
        symbol = symbol.to_sym
        timer = timer.to_f
        if !@cooldowns
            @cooldowns = {}
            Game.instance.add_cooldown_object(self)
        end
        if @cooldowns.dig(symbol)
            @cooldowns[symbol][:timer] += timer
        else
            @cooldowns[symbol] = {}
            @cooldowns[symbol][:timer] = Game.instance.frame_time + timer
        end
        @cooldowns[symbol][:message] = message
    end

    def cooldown(symbol)
        symbol = symbol.to_sym
        if !@cooldowns || !@cooldowns.dig(symbol)
            return nil
        end
        return @cooldowns[symbol][:timer] - Game.instance.frame_time
    end

    def update_cooldowns(frame_time)
        # could change to a binary search in a sorted container if speed becomes an issue (very doubtful)
        if @cooldowns
            @cooldowns.each do |symbol, hash|
                if hash[:timer] <= frame_time
                    if hash[:message]
                        output hash[:message]
                    end
                    @cooldowns.delete(symbol)
                end
            end
        end
        if @cooldowns.length == 0
            # Cooldowns array set to nil if all cooldowns have been deleted.
            @cooldowns = nil
            Game.instance.remove_cooldown_object(self)
        end
    end
end
