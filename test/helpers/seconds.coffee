_          = require 'lodash'
async      = require 'async'
moment     = require 'moment'
debug      = require('debug')('minutemen-worker:test')

class Seconds
  constructor: ({ @client, @queueName, @sampleSize }) ->
    throw new Error 'Seconds (TestHelper): requires client' unless @client?
    throw new Error 'Seconds (TestHelper): requires queueName' unless @queueName?
    @sampleSize ?= 60

  getSeconds: ({ currentTimestamp, recordId, intervalTime, processNow }, callback) =>
    throw new Error 'Seconds.hasSeconds (TestHelper): requires currentTimestamp' unless currentTimestamp?
    throw new Error 'Seconds.hasSeconds (TestHelper): requires recordId' unless recordId?
    throw new Error 'Seconds.hasSeconds (TestHelper): requires intervalTime' unless intervalTime?
    intervalSeconds = _.round(intervalTime / 1000)
    @_get { currentTimestamp, recordId, processNow, intervalSeconds }, (error, seconds) =>
      return callback error if error?
      secondList = @_filterSeconds { seconds, exists: true }
      callback null, {
        first : _.first secondList
        second: _.nth secondList, 1
        last  : _.last secondList
      }

  _getSecondsRange: ({ currentTimestamp, processNow, intervalSeconds }) =>
    return _.range (currentTimestamp + 1), (currentTimestamp + 60) if processNow
    start = currentTimestamp + 60
    start += 1
    return _.range (start + intervalSeconds), start + 60

  _filterSeconds: ({ seconds, exists }) =>
    return _.map _.filter(seconds, { exists }), 'timestamp'

  _get: ({ currentTimestamp, recordId, processNow, isCron, intervalSeconds }, callback) =>
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
