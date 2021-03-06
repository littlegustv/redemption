require 'singleton'
require 'socket'
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
require_relative 'query.rb'
require_relative 'keywords'
require_relative 'data_classes/dataobject'
require_relative 'data_classes/direction'
require_relative 'data_classes/element'
require_relative 'data_classes/equipslotinfo'
require_relative 'data_classes/genre'
require_relative 'data_classes/gender'
require_relative 'data_classes/material'
require_relative 'data_classes/mobileclass'
require_relative 'data_classes/noun'
require_relative 'data_classes/position'
require_relative 'data_classes/race'
require_relative 'data_classes/sector'
require_relative 'data_classes/size'
require_relative 'data_classes/stat'
require_relative 'data_classes/wearlocation'
require_relative 'commands/commands'
require_relative 'game'
require_relative 'game_lookups'
require_relative 'game_save'
require_relative 'game_setup'
require_relative 'gameobject'
require_relative 'area'
require_relative 'group'
require_relative 'exit'
require_relative 'room'
require_relative 'mobile'
require_relative 'mobile_item'
require_relative 'item'
require_relative 'player'
require_relative 'inventory'
require_relative 'equipslot'
require_relative 'affects/affects'
require_relative 'commands/spells/spells'
require_relative 'commands/skills/skills'
require_relative 'resets/reset'
require_relative 'resets/exitreset'
require_relative 'resets/itemreset'
require_relative 'resets/mobilereset'
require_relative 'models/model'
require_relative 'models/keywordedmodel'
require_relative 'models/itemmodel'
require_relative 'models/lightmodel'
require_relative 'models/affectmodel'
require_relative 'models/consumablemodel'
require_relative 'models/pillmodel'
require_relative 'models/portalmodel'
require_relative 'models/potionmodel'
require_relative 'models/containermodel'
require_relative 'models/mobilemodel'
require_relative 'models/playermodel'
require_relative 'models/weaponmodel'
require_relative 'continent'
require_relative 'constants'
require_relative 'client'
require_relative 'formula'

Game.instance.start(ARGV[0], ARGV[1] || 4000)
