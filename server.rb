require 'socket'
require 'weakref'
require 'digest'
require 'json'
require 'set'
require 'sequel'
require 'logger'
require 'rb-readline'
require 'pry'
require 'objspace'
require 'memory_profiler' if $VERBOSE
# require 'allocation_tracer'
# require 'pp'
require_relative 'util'
require_relative 'commands/commands'
require_relative 'game'
require_relative 'gameobject'
require_relative 'area'
require_relative 'exit'
require_relative 'room'
require_relative 'mobile'
require_relative 'item'
require_relative 'player'
require_relative 'inventory'
require_relative 'equipslot'
require_relative 'affects/affects'
require_relative 'commands/spells/spells'
require_relative 'commands/skills/skills'
require_relative 'resets/resetmobile'
require_relative 'continent'
require_relative 'constants'
require_relative 'client'
require_relative 'formula'

Game.instance.start(ARGV[0], ARGV[1] || 4000, ARGV[2] || "all")
