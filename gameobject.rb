class GameObject

    attr_accessor :name, :keywords, :affects, :uuid, :active
    attr_reader :listeners, :room

    def initialize( name, game )
        @name = name
        @keywords = [name]
        @game = game
        @affects = []
        @listeners = {}
        @uuid = @game.new_uuid
        @active = true
    end

    def update( elapsed )
        @affects.each { |aff| aff.update( elapsed ) }
    end

    def output( message, objects = [] )
    end

    def broadcast( message, targets, objects = [], send_to_sleeping: false)
        @game.broadcast(message, targets, objects.to_a, send_to_sleeping: send_to_sleeping)
    end

    def target( query )
        @game.target query
    end

    def to_a
        [ self ]
    end

    def to_s
        @name
    end

    def to_someone
        "someone"
    end

    def show( looker )
        if looker.can_see? self
            data = { description: self.to_s }
            @game.fire_event( :event_calculate_description, data, self )
            return data[:description]
        else
            to_someone
        end
    end

    def fuzzy_match( query )
        query.to_a.all?{ |q|
            !(@keywords.bsearch{ |keyword|
                keyword.fuzzy_match( q ) == true
            }.nil?)
            # @keywords.bsearch{ |keyword|
            #     keyword.fuzzy_match( q )
            # }
        }
    end

    def can_see?(target)
        true
    end

    def add_event_listener(event, responder, method)
        if @listeners[event].nil?
            @listeners[event] = {}
        end
        @listeners[event][responder] = method
        @listeners[event] = Hash[@listeners[event].sort_by{ |responder, method| responder.priority * -1 }]
    end

    def delete_event_listener(event, responder)
        if @listeners[event].nil?
            return
        end
        @listeners[event].delete(responder)
        if @listeners[event].empty?
            @listeners.delete(event)
        end
    end

    def clear_event_listeners
        @listeners.each do |event, value|
            value.each do |responder, method|
                delete_event_listener(event, responder)
            end
        end
    end

    def event(event, data)
        if !@listeners[event]
            return
        end
        @listeners[event]&.each do |responder, method|
            responder.send method, data
        end
    end

    # Returns true if the GameObject is affected by an Affect with a matching keyword.
    # Exact match only!
    def affected?( key )
        @affects.select{ |affect| affect.check(key) }.count > 0
    end

    ##
    # Apply a new affect according to its application type
    # +new_affect+:: The new affect to be applied
    #
    def apply_affect(new_affect, silent = false)
        existing_affects = @affects.select { |a| a.shares_ancestors_with?(new_affect) }
        type = new_affect.application_type
        if [:source_overwrite, :source_stack, :source_single].include?(type)
            existing_affects.select! { |a| a.source == new_affect.source }
        end
        if !existing_affects.empty?
            case type
            when :global_overwrite, :source_overwrite              # delete old affect(s) and push the new one
                existing_affects.each { |a| a.clear(silent: true) }
                new_affect.send_refresh_messages if !silent
                affects.unshift(new_affect)
                @game.add_affect(new_affect)
                new_affect.start
            when :global_stack, :source_stack                      # stack with existing affect
                existing_affects.first.send_refresh_messages if !silent
                existing_affects.first.stack(new_affect)
                existing_affects.first.start
            when :global_single, :source_single                    # do nothing, already applied
                return false
            when :multiple
                new_affect.send_start_messages if !silent
                affects.unshift(new_affect)
                @game.add_affect(new_affect)
                new_affect.start
            else
                log "unknown application type #{affect.application_type} in apply_affect on affect #{affect} belonging to #{self}"
                return false
            end
        else
            new_affect.send_start_messages if !silent
            affects.unshift(new_affect)
            @game.add_affect(new_affect)
            new_affect.start
        end
        return true
    end

    # Applies an group of affects from an array of strings, matching the strings as keys for
    # AFFECT_CLASS_HASH in constants.rb
    # +flags+:: array of flag strings. +["infravision", "hatchling", "flying"]+
    # +silent+:: true if the affects should not output messages
    # +array+:: array to add affects onto
    #  some_mobile.apply_affect_flags(["infravision", "hatchling", "flying"])
    #
    def apply_affect_flags(flags, silent: false, array: nil)
        flags.each do |flag|
            affect_class = Constants::AFFECT_CLASS_HASH[flag]
            if affect_class
                affect = affect_class.new(source: self, target: self, level: 0, game: @game)
                affect.savable = false
                affect.permanent = true
                apply_affect(affect, silent)
                array << affect if array
            end
        end
    end

    # Remove all affects by a given keyword
    # +term+:: The keyword to match
    def remove_affect(term)
        list = @affects.select{ |a| a.check( term )  }
        list.each do |affect|
            affect.clear(silent: false)
        end
    end

    # handles its own destruction - override in subclasses
    def destroy
        log "GameObject::destroy being called by object #{self} : This shouldn't happen!"
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
            affs_to_show = affs_to_show.reject(&:hidden)
        end
        text = ( full ? "#{prefix} affected by the following spells:\n" : "" )
        if affs_to_show.empty?
            return ( full ? "#{prefix} not affected by any spells." : "")
        else
            return "#{text}#{ affs_to_show.map(&:summary).join("\n") }"
        end
    end

end
