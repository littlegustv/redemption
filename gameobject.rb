class GameObject

    attr_accessor :name, :keywords, :affects
    attr_reader :listeners, :uuid, :room

    @@next_uuid = 1

    def initialize( name, game )
        @name = name
        @keywords = [name]
        @game = game
        @affects = []
        @listeners = {}
        @uuid = @@next_uuid
        @@next_uuid += 1
    end

    def update( elapsed )
    end

    def output( message, objects = [] )
    end

    def broadcast( message, targets, objects = [] )
        @game.broadcast message, targets, objects
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
            to_s
        else
            to_someone
        end
    end

    def fuzzy_match( query )
        query.to_a.all?{ |q|
            @keywords.any?{ |keyword|
                keyword.fuzzy_match( q )
            }
        }
    end

    def can_see?
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
    def apply_affect(new_affect)
        existing_affects = @affects.select { |a| a.shares_ancestors_with?(new_affect) }
        type = new_affect.application_type
        if [:source_overwrite, :source_stack, :source_single].include?(type)
            existing_affects.select! { |a| a.source == new_affect.source }
        end
        if existing_affects.length > 1 # This shouldn't ever happen, I don't think!
            puts "Multiple pre-existing affects in apply_effect on affect #{affect} belonging to #{self}"
        end
        if !existing_affects.empty?
            case type
            when :global_overwrite, :source_overwrite              # delete old affect(s) and push the new one
                existing_affects.each do |a|
                    a.unhook
                    affects.delete(a)
                end
                affects.push(new_affect)
                new_affect.hook
                new_affect.refresh
            when :global_stack, :source_stack                      # stack with existing affect
                existing_affects.first.stack(new_affect)
                existing_affects.first.refresh
            when :global_single, :source_single                    # do nothing, already applied
                return
            else
                puts "unknown application type #{affect.application_type} in apply_affect on affect #{affect} belonging to #{self}"
                return
            end
        else
            affects.push(new_affect)
            new_affect.hook
            new_affect.start
        end
    end

end
