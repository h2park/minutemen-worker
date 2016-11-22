_          = require 'lodash'
async      = require 'async'
moment     = require 'moment'
timeExpect = require './time-expect'
debug      = require('debug')('minutemen-worker:test')

class Seconds
  constructor: ({ @client, @queueName, @sampleSize }) ->
    throw new Error 'Seconds (TestHelper): requires client' unless @client?
    throw new Error 'Seconds (TestHelper): requires queueName' unless @queueName?
    @sampleSize ?= 60

  hasSeconds: ({ currentTimestamp, recordId, intervalTime, isCron, processNow }, callback) =>
    throw new Error 'Seconds.hasSeconds (TestHelper): requires currentTimestamp' unless currentTimestamp?
    throw new Error 'Seconds.hasSeconds (TestHelper): requires recordId' unless recordId?
    throw new Error 'Seconds.hasSeconds (TestHelper): requires intervalTime' unless intervalTime?
    offset = _.round(intervalTime / 1000)
    @_get { currentTimestamp, recordId, processNow, isCron, offset }, (error, seconds) =>
      return callback error if error?
      secondsRange = @_getSecondsRange { currentTimestamp, processNow, isCron, offset }
      foundSeconds = @_filterSeconds { seconds, exists: true }
      expectedSeconds = @_getExpectedSeconds { secondsRange, currentTimestamp, isCron, offset }
      console.log { foundSeconds, expectedSeconds }
      timeExpect.shouldMatchMembers 'seconds', foundSeconds, expectedSeconds
      callback()

  hasOneSecond: ({ currentTimestamp, recordId, intervalTime,processNow }, callback) =>
    throw new Error 'Seconds.hasOneSecond (TestHelper): requires currentTimestamp' unless currentTimestamp?
    throw new Error 'Seconds.hasOneSecond (TestHelper): requires recordId' unless recordId?
    throw new Error 'Seconds.hasOneSecond (TestHelper): requires intervalTime' unless intervalTime?
    offset = _.round(intervalTime / 1000)
    @_get { currentTimestamp, recordId,processNow }, (error, seconds) =>
      return callback error if error?
      foundSeconds = @_filterSeconds { seconds, exists: true }
      assert.lengthOf foundSeconds, 1, 'expected seconds to only contain one record'
      timeExpect.shouldInclude 'seconds', foundSeconds, moment.unix(currentTimestamp).add(offset, 'seconds')
      callback()

  doesNotHaveSeconds: ({ currentTimestamp, recordId, intervalTime, processNow }, callback) =>
    throw new Error 'Seconds.doesNotHaveSeconds (TestHelper): requires currentTimestamp' unless currentTimestamp?
    throw new Error 'Seconds.doesNotHaveSeconds (TestHelper): requires recordId' unless recordId?
    throw new Error 'Seconds.doesNotHaveSeconds (TestHelper): requires intervalTime' unless intervalTime?
    offset = _.round(intervalTime / 1000)
    @_get { currentTimestamp, recordId,processNow }, (error, seconds) =>
      return callback error if error?
      foundSeconds = @_filterSeconds { seconds, exists: true }
      assert.lengthOf foundSeconds, 0, "expected no seconds to have been created, instead #{JSON.stringify(foundSeconds)} were found."
      callback()

  _getSecondsRange: ({ currentTimestamp, processNow, isCron, offset }) =>
    return _.range (currentTimestamp + 1), (currentTimestamp + 60) if processNow
    start = currentTimestamp + 60
    if offset > 1 and isCron
      start += start % 2
    start += 1 unless isCron
    return _.range (start + offset), start + 60

  _filterSeconds: ({ seconds, exists }) =>
    return _.map _.filter(seconds, { exists }), 'timestamp'

  _getExpectedSeconds: ({ currentTimestamp, secondsRange, isCron, offset }) =>
    return _.filter secondsRange, (second) =>
      return second % offset == 0

  _get: ({ currentTimestamp, recordId, processNow, isCron, offset }, callback) =>
    throw new Error 'Seconds._get (TestHelper): requires currentTimestamp' unless currentTimestamp?
    throw new Error 'Seconds._get (TestHelper): requires recordId' unless recordId?
    callback = _.once callback
    secondsRange = @_getSecondsRange({ currentTimestamp, processNow, isCron, offset })
    @_multiLists { secondsRange }, (error, results) =>
      return callback error if error?
      [ error, seconds ] = @_parseMultiResults { secondsRange, results, recordId }
      return callback error if error?
      callback null, seconds
    return # redis fix

  _multiLists: ({ secondsRange }, callback) =>
    multi = @client.multi()
    _.each secondsRange, (timestamp) =>
      multi.lrange "test-worker:#{@queueName}:#{timestamp}", 0, -1
    multi.exec callback

  _parseMultiResults: ({ secondsRange, results, recordId }) =>
    seconds = []
    for [ignore, result], index in results
      timestamp = secondsRange[index]
      return [new Error('too many items in the second queue')] if _.size(result) > 1
      if _.size(result) > 0
        data = JSON.parse _.first(result)
        return [new Error 'Record ID does not match'] unless data.recordId == recordId
        return [new Error 'Timestamp does not match'] unless _.parseInt(data.timestamp) == timestamp
      seconds.push { timestamp, exists: _.size(result) == 1 }
    return [null, seconds]

module.exports = Seconds
