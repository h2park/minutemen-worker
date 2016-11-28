_          = require 'lodash'
async      = require 'async'
moment     = require 'moment'
debug      = require('debug')('minutemen-worker:test')

class Seconds
  constructor: ({ @client, @queueName, @sampleSize }) ->
    throw new Error 'Seconds (TestHelper): requires client' unless @client?
    throw new Error 'Seconds (TestHelper): requires queueName' unless @queueName?
    @sampleSize ?= 60

  getSeconds: ({ currentTimestamp, recordId, intervalTime, isCron, processNow }, callback) =>
    throw new Error 'Seconds.hasSeconds (TestHelper): requires currentTimestamp' unless currentTimestamp?
    throw new Error 'Seconds.hasSeconds (TestHelper): requires recordId' unless recordId?
    throw new Error 'Seconds.hasSeconds (TestHelper): requires intervalTime' unless intervalTime?
    offset = _.round(intervalTime / 1000)
    @_get { currentTimestamp, recordId, processNow, isCron, offset }, (error, secondList) =>
      return callback error if error?
      secondList = _.filter secondList, { exists: true }
      secondList = _.map secondList, 'timestamp'
      callback null, {
        first : _.first secondList
        second: _.nth secondList, 1
        last  : _.last secondList
      }

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
    @client.keys '*', (error, keys) =>
      secondsRange = _.map keys, (key) => _.parseInt _.last _.split key, ':'
      @_multiLists { secondsRange }, (error, results) =>
        return callback error if error?
        [ error, secondList ] = @_parseMultiResults({ secondsRange, results, recordId })
        return callback error, secondList
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
    seconds =_.sortBy seconds, 'timestamp'
    return [null, seconds]

module.exports = Seconds
