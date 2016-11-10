_         = require 'lodash'
async     = require 'async'
Intervals = require './intervals'
Soldiers  = require './soldiers'

class Transfer
  constructor: ({ database }) ->
    throw new Error 'Transfer: requires database' unless database?
    @intervals = new Intervals { database }
    @soldiers = new Soldiers { database }

  setup: (callback) =>
    @soldiers.ensureIndexes callback

  processAll: (callback) =>
    async.doUntil @processBatch, @shouldContinue, callback

  processBatch: (callback) =>
    @intervals.getBatch (error, intervals) =>
      return callback error if error?
      console.log 'interval batch size', _.size(intervals)
      async.each intervals, @processSingle, (error) =>
        return callback error if error?
        callback null, _.size(intervals)

  processSingle: (interval, callback) =>
    @soldiers.createFromInterval interval, callback

  shouldContinue: (count) =>
    return count < 1

module.exports = Transfer
