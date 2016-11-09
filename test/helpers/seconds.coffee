_          = require 'lodash'
async      = require 'async'
moment     = require 'moment'
timeExpect = require './time-expect'
debug      = require('debug')('minute-man-worker:test')

class Seconds
  constructor: ({ @client, @queueName, @sampleSize }) ->
    throw new Error 'Seconds (TestHelper): requires client' unless @client?
    throw new Error 'Seconds (TestHelper): requires queueName' unless @queueName?
    @sampleSize ?= 60

  hasSeconds: ({ currentTimestamp, recordId, intervalTime }, callback) =>
    throw new Error 'Seconds.hasSeconds (TestHelper): requires currentTimestamp' unless currentTimestamp?
    throw new Error 'Seconds.hasSeconds (TestHelper): requires recordId' unless recordId?
    throw new Error 'Seconds.hasSeconds (TestHelper): requires intervalTime' unless intervalTime?
    offset = _.round(intervalTime / 1000)
    @_get { currentTimestamp, recordId }, (error, seconds) =>
      return callback error if error?
      allSeconds = _.range currentTimestamp, (currentTimestamp + @sampleSize)
      foundSeconds = _.map _.filter(seconds, 'value'), 'timestamp'
      expectedSeconds = _.filter allSeconds, (second) => return second % offset == 0
      _.each _.difference(expectedSeconds, allSeconds), (second) =>
        timeExpect.shouldInclude 'seconds', allSeconds, moment.unix(second)
      _.each _.difference(foundSeconds, allSeconds), (second) =>
        timeExpect.shouldNotInclude 'seconds', allSeconds, moment.unix(second)
      callback()

  hasOneSecond: ({ currentTimestamp, recordId, intervalTime }, callback) =>
    throw new Error 'Seconds.hasOneSecond (TestHelper): requires currentTimestamp' unless currentTimestamp?
    throw new Error 'Seconds.hasOneSecond (TestHelper): requires recordId' unless recordId?
    throw new Error 'Seconds.hasOneSecond (TestHelper): requires intervalTime' unless intervalTime?
    offset = _.round(intervalTime / 1000)
    @_get { currentTimestamp, recordId }, (error, seconds) =>
      return callback error if error?
      foundSeconds = _.map _.filter(seconds, 'value'), 'timestamp'
      expect(foundSeconds.length).to.equal 1
      expect(_.first(foundSeconds)).to.equal currentTimestamp + offset
      callback()

  doesNotHaveSeconds: ({ currentTimestamp, recordId, intervalTime }, callback) =>
    throw new Error 'Seconds.doesNotHaveSeconds (TestHelper): requires currentTimestamp' unless currentTimestamp?
    throw new Error 'Seconds.doesNotHaveSeconds (TestHelper): requires recordId' unless recordId?
    throw new Error 'Seconds.doesNotHaveSeconds (TestHelper): requires intervalTime' unless intervalTime?
    offset = _.round(intervalTime / 1000)
    @_get { currentTimestamp, recordId }, (error, seconds) =>
      return callback error if error?
      foundSeconds = _.map _.filter(seconds, 'value'), 'timestamp'
      _.each foundSeconds, (second) =>
        timeExpect.shouldNotInclude 'seconds', allSeconds, moment.unix(second)
      callback()

  _get: ({ currentTimestamp, recordId }, callback) =>
    throw new Error 'Seconds._get (TestHelper): requires currentTimestamp' unless currentTimestamp?
    throw new Error 'Seconds._get (TestHelper): requires recordId' unless recordId?
    multi = @client.multi()
    allSeconds = _.times @sampleSize, (n) =>
      return currentTimestamp + n
    _.each allSeconds, (timestamp) =>
      multi.lrange "test-worker:#{@queueName}:#{timestamp}", 0, -1
      return
    multi.exec (error, results) =>
      return callback error if error?
      callback = _.once callback
      seconds = []
      _.each results, ([ignore, result], i) =>
        count = _.size(result)
        timestamp = allSeconds[i]
        return callback new Error('too many items in the second queue') if count > 1
        return seconds.push {timestamp} if count == 0
        data = JSON.parse _.first(result)
        return callback new Error 'Record ID does not match' unless data.recordId == recordId
        return callback new Error 'Timestamp does not match' unless _.parseInt(data.timestamp) == timestamp
        seconds.push {timestamp,value:data}
      callback null, seconds
    return # redis fix

module.exports = Seconds
