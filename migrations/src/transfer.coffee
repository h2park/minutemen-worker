_           = require 'lodash'
async       = require 'async'
Intervals   = require './intervals'
Soldiers    = require './soldiers'
LegacyRedis = require './legacy-redis'

class Transfer
  constructor: ({ database, client, skip, limit }) ->
    throw new Error 'Transfer: requires database' unless database?
    throw new Error 'Transfer: requires client' unless client?
    throw new Error 'Transfer: requires skip' unless skip?
    throw new Error 'Transfer: requires limit' unless limit?
    @intervals = new Intervals { database, skip, limit }
    @soldiers = new Soldiers { database }
    @legacyRedis = new LegacyRedis { client }

  setup: (callback) =>
    @soldiers.ensureIndexes callback

  processAll: (callback) =>
    async.doUntil @processBatch, @shouldContinue, callback

  processBatch: (callback) =>
    @intervals.getBatch (error, intervals) =>
      return callback error if error?
      console.log "got #{_.size(intervals)} intervals"
      async.eachSeries intervals, @processSingle, (error) =>
        return callback error if error?
        callback null, _.size(intervals)

  processSingle: (interval, callback) =>
    @intervals.getCredentials interval, (error, interval) =>
      return callback error if error?
      @soldiers.createFromInterval interval, (error) =>
        return callback error if error?
        @legacyRedis.disable interval, (error) =>
          return callback error if error?
          { ownerId, nodeId, id } = interval
          { fireOnce } = interval?.data ? {}
          console.log 'migrated', {ownerId, nodeId, id} unless fireOnce
          callback null

  shouldContinue: (count) =>
    return count < 1

module.exports = Transfer
