_           = require 'lodash'
async       = require 'async'
Intervals   = require './intervals'
Soldiers    = require './soldiers'
LegacyRedis = require './legacy-redis'
debug       = require('debug')('migrate:transfer')

class Transfer
  constructor: ({ database, client, skip, limit, flowId }) ->
    throw new Error 'Transfer: requires database' unless database?
    throw new Error 'Transfer: requires client' unless client?
    throw new Error 'Transfer: requires skip' unless skip?
    throw new Error 'Transfer: requires limit' unless limit?
    @intervals = new Intervals { database, client, skip, limit, flowId }
    @soldiers = new Soldiers { database }
    @legacyRedis = new LegacyRedis { client }

  setup: (callback) =>
    @soldiers.ensureIndexes callback

  processAll: (callback) =>
    async.doUntil @processBatch, @shouldContinue, callback

  processBatch: (callback) =>
    @intervals.getBatch (error, intervals) =>
      return callback error if error?
      debug "got #{_.size(intervals)} intervals"
      async.each intervals, @processSingle, (error) =>
        return callback error if error?
        callback null, _.size(intervals)

  processSingle: (interval, callback) =>
    @intervals.getCredentials interval, (error, interval) =>
      return callback error if error?
      { ownerId, nodeId, id, token } = interval
      { fireOnce } = interval?.data ? {}
      unless id? || token?
        debug 'not migrating due to lack of credentials, skipping...', {ownerId, nodeId, id}
        callback null
        return
      @soldiers.createFromInterval interval, (error) =>
        return callback error if error?
        @legacyRedis.disable interval, (error) =>
          return callback error if error?
          debug 'migrated', {ownerId, nodeId, id} unless fireOnce
          callback null

  shouldContinue: (count) =>
    return count < 1

module.exports = Transfer
