#
# All other "game objects" (Mobiles, Rooms, Exits, Areas, Items) inherit from this class.
# 
# GameObjects can have a model and a reset that generated them. If they have a model, then
# name, short_description, long_description 
#
#
class GameObject

    @next_uuid = 1

    def GameObject.next_uuid
        uuid = @next_uuid
        @next_uuid += 1
        return uuid
    end

    
    # @return [Integer] A unique ID for every GameObject.
    attr_reader :uuid

    # @return [Boolean] True when the object is `active`. Gets set to false when the object
    #  calls `destroy`, meaning it cannot have affects, cannot receive damage (for mobiles),
    #  etc.
    attr_reader :active

    # @return [Reset, nil] The Reset attached to this GameObject, or `nil` if it doesn't have one.
    attr_accessor :reset
    
    # @return [Gender] The Gender for this GameObject. Defaults to first available gender.
    attr_reader :gender

    #
    # Initialize a GameObject.
    #
    # @param name [String, nil] The name of the object. `nil` probably means the name is attached to the model.
    # @param keywords [String, nil] The keywords for the object. `nil` probably means the keywords are attached to the model.
    # @param reset [Reset, nil] The Reset that generated this object, or `nil` if it has none.
    # @param model [Model, nil] The Model to associate with this object, or `nil` if it doesn't have one.
    #
    def initialize( name, keywords, reset = nil, model = nil )
        self.active
        # @type [String, nil]
        # The name of the object, or `nil` if it doesn't have one or uses a model for its name.
        @name = name

        # @type [Model, nil]
        # The model for this object, or `nil` if it doesn't have one.
        @model = model
        
        # @type [Reset, nil]
        # The reset attached to this object, or `nil` if it doesn't have one.
        @reset = reset

        # @type [Array<Affect>, nil]
        # An array of affects attached to this object, or `nil` if it doesn't have any.
        @affects = nil

        # @type [Array<Affect>, nil]
        # An array of affects whose source are this object, or `nil` if it doesn't have any.
        @source_affects = nil

        # @type [Hash{ Symbol => Hash{ Symbol => Float, String }, nil]
        # A Hash of cooldowns, or `nil` if this object has no cooldowns.
        #   @cooldowns[:lay_hands]
        #   # => {:timer => 1592414780.305089, :message => "Your healing power is restored."}
        @cooldowns = nil

        # @type [Keywords, nil]
        # The keywords for this object, or `nil` if it has none or uses a model for keywords.
        @keywords = nil

        # @type [String, nil]
        # The short description for this object, or `nil` if it doesn't have one or uses a model for its short description.
        @short_description = nil

        # @type [String, nil]
        # The long description for this object, or `nil` if it doesn't have one or uses a model for its long description.
        @long_description = nil
        
        # @type [Integer]
        # A unique ID given to all GameObjects.
        @uuid = GameObject.next_uuid

        # @type [Boolean]
        # Whether or not this object is active (able to receive affects, etc).
        @active = true

        # @type [Gender]
        # The gender of this object.
        @gender = Game.instance.genders.values.first

        if keywords 
            @keywords = Keywords.keywords_for_array(keywords.to_a)
        end
        if @model && @model.temporary
            @model.increment_use_count
        end
        Game.instance.add_gameobject(self)
        
    end   

    #
    # Destroys this GameObject. Mark as inactive, clear all affects, manage source affects,
    # decrement keyword and model `use_count`s as necessary, and then call Game#remove_gameobject
    # for removal of the GameObject from global lists.
    #
    # @return [nil]
    #
    def destroy
        self.deactivate
        if @affects
            @affects.dup.each do |affect|
                affect.clear(true)
            end
        end
        # clear affects that have this object as a source and require a source
        if @source_affects
            @source_affects.each do |source_affect|

            end
        end
        if @keywords
            @keywords.decrement_use_count
        end
        if @model && @model.temporary
            @model.decrement_use_count
        end
        @affects = nil
        @source_affects = nil
        Game.instance.remove_gameobject(self)
        return
    end

    #
    # Mark this GameObject as inactive.
    #
    # @return [Boolean] True if the object was active but now isn't.
    #
    def deactivate
        last_state = @active
        @active = false
        return @active
    end

    #
    # Return the name of the GameObject. Will attempt to use a model's name if no @name
    # has been set.
    #
    # @return [String] The name of the object, or the name of the model, or an empty string if neither has been set.
    #
    def name
        if @model
            return @name || @model.name.to_s
        else
            return @name.to_s
        end
    end

    #
    # Output a message to this GameObject using a format and list of objects.
    # 
    #   output("0<N> drops 0<p> 1<n>.", [mobile, item]) # "A bag boy drops his sword."
    #   # 0 and 1 are the index of the object in the objects array
    #
    #   # Pronoun format
    #   "N" => Name                 "A bag boy"
    #   "S" => Short Description    "A boy is waiting here to pack your bags for you. "
    #   "L" => Long Description     "With a bored look on his face, you know that this youngster..."
    #   "O" => Personal Objective   "Him"
    #   "U" => Personal Subjective  "He"
    #   "P" => Possessive           "His"
    #   "R" => Reflexive            "Himself"
    #
    #   # Capitalization of pronouns in the format will be reflected in the output.
    #   "0<N>" => "A bag boy"
    #   "0<n>" => "a bag boy"
    #
    # @param [String] message The format.
    # @param [Array<GameObject>] objects The objects.
    #
    # @return [nil]
    #
    def output( message, objects = [] )
        return
    end

    #
    # __A shortcut for Game#target.__
    #
    # Have game target GameObjects using options from a query.
    #
    # Query options: 
    #
    #   :argument   # A String or Query to describe the target, eg. "2*50.diamond". This option overrides :keywords.
    #   :keywords   # A Set of Symbols to match keywords with. Usually generated by :argument.
    #   :offset     # An Integer offset to pick the Nth result. Usually generated by :argument.
    #   :quantity   # The number of desired results. Usually generated by :argument.
    #   :list       # An array of GameObjects to use as a base list
    #   :type       # A Class or Array of Classes to match
    #   :affect     # An Affect name or Array of Affect names to require results to have as affects
    #   :not        # A GameObject or Array of GameObjects to subtract from the results.
    #   :attacking  # A GameObject or Array of GameObjects that the results must be attacking.
    #   :visible_to # A GameObject which the results must be visible to.
    #   :where_to   # A GameObject which the results must be able to have been "where"d by.
    #   :limit      # Integer to limit the number of results.
    #
    # @param [Hash] **query The query.
    # @option query [Array<GameObject>] :list A list of GameObjects to filter from.
    # @option query [Array<Class>] :type An array containing GameObject Classes
    #
    # @return [Array<GameObjects>] The results of the query.
    #
    def target( **query )
        query[:visible_to] = self
        Game.instance.target(**query)
    end

    def responds_to_event(event)
        Game.instance.responds_to_event(self, event)
    end

    #
    # Returns the GameObject in an Array.
    #
    # @return [Array<GameObject>] The GameObject alone in an array.
    #
    def to_a
        [ self ]
    end

    #
    # Returns the String representation of this object, using its name.
    #
    # @return [String] The representation.
    #
    def to_s
        self.name.to_s
    end

    #
    # Show this object to another. Checks `can_see?`.
    #
    # @param [GameObject] observer The observer object.
    #
    # @return [String] The string to show.
    #
    def show( observer )
        if observer.can_see? self
            return self.long_auras + self.name.to_s
        else
            return self.long_auras + indefinite_name
        end
    end

    #
    # Returns true if this GameObject's keywords are a superset of a given query.
    #
    # @param [String, Array<String>, Set<Symbol>, Query] query The query
    #
    # @return [Boolean] True if this GameObject matches all given keywords.
    #
    def fuzzy_match( query )
        return self.keywords.fuzzy_match(query)
    end

    #
    # Returns the keywords of this GameObject, defaulting to the model's keywords if available.
    # Will return an empty Keywords object if no keywords are available.
    #
    # @return [Set<Symbol>] The keywords.
    #
    def keywords
        if @model
            return @keywords || @model.keywords || Keywords.empty_keywords
        end
        @keywords || Keywords.empty_keywords
    end

    #
    # Returns true if this GameObject can see another given GameObject.
    #
    # @param [GameObject] target The GameObject to be seen (or not!).
    #
    # @return [Boolean] True if this GameObject can see `target`, otherwise false.
    #
    def can_see?(target)
        return true if target == self
        if !self.responds_to_event(:try_can_see) &&
            !self.room.responds_to_event(:try_can_see_room) &&
            !target.responds_to_event(:try_can_be_seen)
            return true
        end
        data = {chance: 100, target: target, observer: self}
        Game.instance.fire_event(self, :try_can_see, data)
        Game.instance.fire_event(self.room, :try_can_see_room, data)
        Game.instance.fire_event(target, :try_can_be_seen, data) if target
        chance = data[:chance]
        if chance >= 100
            return true
        elsif chance <= 0
            return false
        else
            return chance >= dice(1, 100)
        end
    end

    #
    # Take a list of targets and return the list of objects that this GameObject can see.
    #
    # @param [Array<GameObject>] targets The targets to check for visibility.
    # @param [Integer, nil] limit The limit for the number of targets, or `nil` if there isn't one.
    #
    # @return [Array<GameObject>] The visible targets.
    #
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

    #
    # Returns true if the GameObject is affected by an Affect with a matching keyword.
    # Exact match only!
    #
    # @param [String, Array<String>, Set<Symbol>, Query] query The query
    #
    # @return [Boolean] True if this GameObject is affected by a keyword-matching affect.
    #
    def affected?( query )
        if @affects
            @affects.select{ |affect| affect.keywords.fuzzy_match(query) }.count > 0
        else
            return false
        end
    end

    #
    # Applies an affect using an id.
    #
    # @param [Integer] id The ID of the affect.
    # @param [Boolean] silent True if the affect application should be silent.
    # @param [Array<Affect>] array An array of affects to append to. Useful for managing race/class affects, etc.
    # @param [Hash{Symbol => Integer, Float, String}] data Data to overwrite on the affect with.
    #
    # @return [nil]
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
        return
    end

    #
    # Apply an affect using a model.
    #
    # @param [AffectModel] affect_model The AffectModel.
    # @param [Boolean] silent True if the affect application should be silent.
    # @param [Array<Affect>] array An affect of affects to append to. Useful for managing race/class affects, etc.
    #
    # @return [nil]
    #
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
        return
    end

    #
    # Get the currently applied affects for the GameObject.
    #
    # @return [Array<Affect>] The Affects.
    #
    def affects
        return @affects.to_a
    end

    #
    # Adds an (already applied) affect to this object's list of affects.
    #
    # __Only called by the base __`Affect`__ class!__
    #
    # @param [Affect] affect The affect to add.
    #
    # @return [nil]
    #
    def add_affect(affect)
        if @affects.nil?
            @affects = [affect]
        else
            @affects << affect
        end
        return
    end

    #
    # Removes an (already removed) affect from this object's list of affects.
    #
    # __Only called by the base __`Affect`__ class!__
    #
    # @param [Affect] affect The affect to remove.
    #
    # @return [nil]
    #
    def remove_affect(affect)
        if @affects.nil?
            return
        end
        @affects.delete(affect)
        if @affects.empty?
            @affects = nil
        end
        return
    end

    #
    # Returns the affects on _other_ GameObjects that have _this_ object as a source.
    #
    # @return [Array<Affect>] The source affects.
    #
    def source_affects
        return @source_affects.to_a
    end

    #
    # Adds an affect to this object's list of source affects.
    #
    # __Only called by the base __`Affect`__ class!__
    #
    # @param [Affect] affect The source affect to add.
    #
    # @return [nil]
    #
    def add_source_affect(affect)
        if @source_affects.nil?
            @source_affects = [affect]
        else
            @source_affects << affect
        end
        return
    end

    #
    # Removes a source affect from this object's list of source affects.
    #
    # __Only called by the base __`Affect`__ class!__
    #
    # @param [Affect] affect The source affect to remove.
    #
    # @return [nil]
    #
    def remove_source_affect(affect)
        if @source_affects.nil?
            return
        end
        @source_affects.delete(affect)
        if @source_affects.empty?
            @source_affects = nil
        end
        return
    end

    # Remove all affects by a given keyword
    # +term+:: The keyword to match

    #
    # Remove all affects with a given keyword.
    #
    # @param [String, Array<String>, Set<Symbol>, Query] keywords The keywords as any number of types! :)
    #
    # @return [nil]
    #
    def remove_affects_with_keywords(keywords)
        keywords
        list = @affects.select{ |a| a.fuzzy_match( keywords )  }
        list.each do |affect|
            affect.clear(false)
        end
        return
    end

    #
    # Generates a hash to provide affect source fields for the database. Ex)
    #
    #   player.db_source_fields # =>
    #   {source_type_id: 6, source_uuid: 153, source_id: 12}
    #
    # @return [Hash{Symbol => Integer}] The hash of source field values.
    #
    def db_source_fields
        source_data = { source_type_id: self.class.gameobject_id.to_i,
                        source_uuid: @uuid,
                        source_id: (self.respond_to?(:id)) ? self.id : 0 }
        return source_data
    end

    #
    # Set the GameObject class ID (or subclass - Mobile, etc).
    # Used for saving affect sources to database.
    #
    # @param [Integer] id  The new ID.
    #
    # @return [Integer] Returns the new ID.
    #
    def GameObject.set_gameobject_id(id)
        @id = id
        return @id
    end

    #
    # Returns the GameObject class ID (or subclass - Mobile, etc).
    # Used for saving affect sources to database.
    #
    # @return [Integer] The GameObject class's ID.
    #
    def GameObject.gameobject_id
        return @id
    end

    #
    # Show the affects on this GameObject to an observer.
    #
    # @param [GameObject] observer The GameObject observing the affects.
    # @param [Boolean] show_hidden True if the output should include hidden affects.
    # @param [Boolean] full True if the output should include the header.
    #
    # @return [String] The output.
    #
    def show_affects(observer = nil, show_hidden = false, full = true)
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

    #
    # String used for locate object, etc
    # 
    # "in" -> A bandana is __in__ the donation pit.
    #
    # @return [String] The string.
    #
    def carried_by_string
        return "in"
    end

    #
    # The short description of this object. Usually a little more of a sentence than just its name alone.
    # If no `@short_description` is set, it will attempt to default to `@model.short_description`.
    #
    # @return [String] The short description.
    #
    def short_description
        if @model
            return (@short_description || @model.short_description.to_s)
        end
        return @short_description.to_s
    end

    #
    # The long description of this object. The most detailed description, up to around a paragraph of text.
    # If no `@long_description` is set, it will attempt to default to `@model.long_description`.
    #
    # @return [String, nil] The short description.
    #
    def long_description
        if @model
            return (@long_description || @model.long_description.to_s)
        end
        return @long_description.to_s
    end

    # --- Pronouns ---

    #
    # O -> Personal objective pronoun (him, her, it)
    #
    # @return [String] The pronoun.
    #
    def personal_objective_pronoun
        return @gender.personal_objective
    end

    #
    # U -> Personal subjective pronoun (he, she, it)
    #
    # @return [String] The pronoun.
    #
    def personal_subjective_pronoun
        return @gender.personal_subjective
    end

    #
    # P -> Possessive pronoun (his, her, its)
    #
    # @return [String] The pronoun.
    #
    def possessive_pronoun
        return @gender.possessive
    end

    #
    # R -> Reflexive pronoun (himself, herself, itself)
    #
    # @return [String] The pronoun.
    #
    def reflexive_pronoun
        return @gender.reflexive
    end

    # Indefinite name/description/pronouns
    # these are to be used if the gameobject cannot be seen - override in subclasses

    #
    # The indefinite name of this type of GameObject.
    # Override as necessary in subclasses.
    #
    #   item.indefinite_name #=> "something"
    #   mobile.indefinite_name #=> "someone"
    #
    # @return [String] The indefinite name.
    #
    def indefinite_name
        return "something"
    end

    #
    # The indefinite short description of this type of GameObject.
    # Override as necessary in subclasses.
    #
    #   item.indefinite_short_description #=> "something"
    #   mobile.indefinite_short_description #=> "someone"
    #
    # @return [String] The indefinite short description.
    #
    def indefinite_short_description
        return "something"
    end

    #
    # The indefinite long description of this type of GameObject.
    # Override as necessary in subclasses.
    #
    #   item.indefinite_long_description #=> "something"
    #   mobile.indefinite_long_description #=> "someone"
    #
    # @return [String] The indefinite long description.
    #
    def indefinite_long_description
        return "something"
    end

    #
    # The indefinite personal objective pronoun of this type of GameObject.
    # Override as necessary in subclasses.
    #
    #   item.indefinite_personal_objective_pronoun #=> "it"
    #   mobile.indefinite_personal_objective_pronoun #=> "them"
    #
    # @return [String] The indefinite personal objective pronoun.
    #
    def indefinite_personal_objective_pronoun
        return "it"
    end

    #
    # The indefinite personal subjecive pronoun of this type of GameObject.
    # Override as necessary in subclasses.
    #
    #   item.indefinite_personal_subjective_pronoun #=> "it"
    #   mobile.indefinite_personal_subjective_pronoun #=> "they"
    #
    # @return [String] The indefinite personal subjective pronoun.
    #
    def indefinite_personal_subjective_pronoun
        return "it"
    end

    #
    # The indefinite possessive pronoun of this type of GameObject.
    # Override as necessary in subclasses.
    #
    #   item.indefinite_possessive_pronoun #=> "its"
    #   mobile.indefinite_possessive_pronoun #=> "their"
    #
    # @return [String] The indefinite possessive pronoun.
    #
    def indefinite_possessive_pronoun
        return "its"
    end

    #
    # The indefinite personal subjecive pronoun of this type of GameObject.
    # Override as necessary in subclasses.
    #
    #   item.indefinite_possessive_pronoun #=> "itself"
    #   mobile.indefinite_possessive_pronoun #=> "themself"
    #
    # @return [String] The indefinite reflexive pronoun.
    #
    def indefinite_reflexive_pronoun
        return "itself"
    end


    # Resolving of name/descriptions/pronouns of another object

    #
    # Resolve the name of another GameObject.
    # If the target is equal to self, "you" will be returned.
    # If the object can't be seen it will return GameObject#indefinite_name.
    #
    # @param [GameObject] target The GameObject.
    #
    # @return [String] The resolved name.
    #
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

    #
    # Resolve the short description of another GameObject.
    # If the object can't be seen it will return GameObject#indefinite_short_description.
    #
    # @param [GameObject] target The GameObject.
    #
    # @return [String] The resolved short description.
    #
    def resolve_short_description(target)
        if can_see?(target)
            return target.short_description
        else
            return target.indefinite_short_description
        end
    end


    #
    # Resolve the long description of another GameObject.
    # If the object can't be seen it will return GameObject#indefinite_long_description.
    #
    # @param [GameObject] target The GameObject.
    #
    # @return [String] The resolved long description.
    #
    def resolve_long_description(target)
        if can_see?(target)
            return target.long_description
        else
            return target.indefinite_long_description
        end
    end

    #
    # Resolve the personal objective pronoun of another GameObject.
    # If the target is equal to self, `"you"` will be returned.
    # If the object can't be seen it will return GameObject#indefinite_personal_objective_pronoun.
    #
    # @param [GameObject] target The GameObject.
    #
    # @return [String] The resolved pronoun.
    #
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

    #
    # Resolve the personal subjective pronoun of another GameObject.
    # If the target is equal to self, `"you"` will be returned.
    # If the object can't be seen it will return GameObject#indefinite_personal_subjective_pronoun.
    #
    # @param [GameObject] target The GameObject.
    #
    # @return [String] The resolved pronoun.
    #
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

    #
    # Resolve the possessive pronoun of another GameObject.
    # If the target is equal to self, `"your"` will be returned.
    # If the object can't be seen it will return GameObject#indefinite_possessive_pronoun.
    #
    # @param [GameObject] target The GameObject.
    #
    # @return [String] The resolved pronoun.
    #
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

    #
    # Resolve the reflexive pronoun of another GameObject.
    # If the target is equal to self, `"yourself"` will be returned.
    # If the object can't be seen it will return GameObject#indefinite_reflexive_pronoun.
    #
    # @param [GameObject] target The GameObject.
    #
    # @return [String] The resolved pronoun.
    #
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

    # --- End Pronouns ---

    # --- Auras ---

    # aura string generation

    #
    # Generate "Short Auras" -> Things like (K) for Killer, (T) for Thief.
    #
    # @return [String] The generated aura string.
    #
    def short_auras
        if responds_to_event(:calculate_short_auras)
            data = { description: "" }
            Game.instance.fire_event( self, :calculate_short_auras, data )
            return data[:description]
        else
            return ""
        end
    end

    #
    # Generate "Long Auras" -> Things like (White Aura) or (Blessed).
    #
    # @return [String] The generated aura string.
    #
    def long_auras
        if responds_to_event(:calculate_long_auras)
            data = { description: "" }
            Game.instance.fire_event( self, :calculate_long_auras, data )
            return data[:description]
        else
            return ""
        end
    end

    # --- End Auras ---

    #
    # Returns the hash of cooldowns associated with this object.
    # 
    #   object.cooldowns
    #   # could return
    #   {
    #       :lay_hands    => {  :timer => 123534343.34,
    #                           :message => "Your healing powers are restored." },
    #       :martial_arts => {  :timer => 123523145.13,
    #                           :message => nil }
    #   }
    #
    # @return [Hash{ Symbol => Hash{ Symbol => Float, String } }] The cooldown hash.
    #
    def cooldowns
        return @cooldowns.to_h
    end

    #
    # Add a cooldown to this object. If a cooldown with the same symbol already exists,
    # the existing timer will be added onto.
    #
    #   mobile.add_cooldown(:lay_hands, 300, "Your healing powers are restored.")
    #
    # @param [Symbol] symbol The cooldown symbol.
    # @param [Float] timer The duration of the cooldown in seconds.
    # @param [String] message The message to show the GameObject when the cooldown finishes.
    #
    # @return [nil]
    #
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
        return
    end

    #
    # Removes a given cooldown from this GameObject.
    #
    #   mobile.remove_cooldown(:lay_hands)
    #
    # @param [Symbol] symbol The symbol identifier for the cooldown.
    #
    # @return [Boolean] True if the cooldown was removed, otherwise false.
    #
    def remove_cooldown(symbol)
        if @cooldowns.nil? # no cooldowns
            return false
        end
        hash = @cooldowns.delete(symbol)
        if hash.nil? # cooldown not found
            return false
        end
        # cooldown found
        if !hash[:message].nil?
            output hash[:message]
        end
        return true
    end

    #
    # Query this GameObject's cooldowns for a cooldown with a given symbol.
    #
    #   mobile.cooldown(:lay_hands) #=> 35.43
    #   item.cooldown(:lay_hands)   #=> nil
    #
    # @param [Symbol] symbol The identifier symbol for the cooldown.
    #
    # @return [nil, Float] `nil` if the cooldown didn't exist, otherwise the remaining duration on the cooldown.
    #
    def cooldown(symbol)
        symbol = symbol.to_sym
        if !@cooldowns || !@cooldowns.dig(symbol)
            return nil
        end
        return @cooldowns[symbol][:timer] - Game.instance.frame_time
    end

    #
    # Remove cooldowns whose timers have expired. Returns 
    #
    # @param [Float] frame_time The current frame time.
    #
    # @return [Boolean] True if the object still has cooldowns, otherwise false.
    #
    def update_cooldowns(frame_time)
        # could change to a binary search in a sorted container if speed becomes an issue (doubtful?)
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
        if @cooldowns.empty?
            # Cooldowns array set to nil if all cooldowns have been deleted.
            @cooldowns = nil
            return false
        end
        return true
    end
end
