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
    currentTime = moment.unix(currentTimestamp)
    offset = _.round(intervalTime / 1000)
    @_get { currentTimestamp, recordId }, (error, seconds) =>
      return callback error if error?
      allSeconds = _.range currentTime.unix(), (currentTime.unix() + @sampleSize)
      foundSeconds = _.map _.filter(seconds, 'value'), 'timestamp'
      expectedSeconds = _.filter allSeconds, (second) => return second % offset == 0
      _.each _.difference(expectedSeconds, allSeconds), (second) =>
        timeExpect.shouldInclude 'seconds', allSeconds, moment.unix(second)
      _.each _.difference(foundSeconds, allSeconds), (second) =>
        timeExpect.shouldNotInclude 'seconds', allSeconds, moment.unix(second)
      callback()

  doesNotHaveSeconds: ({ currentTimestamp, recordId, intervalTime }, callback) =>
    throw new Error 'Seconds.doesNotHaveSeconds (TestHelper): requires currentTimestamp' unless currentTimestamp?
    throw new Error 'Seconds.doesNotHaveSeconds (TestHelper): requires recordId' unless recordId?
    throw new Error 'Seconds.doesNotHaveSeconds (TestHelper): requires intervalTime' unless intervalTime?
    currentTime = moment.unix(currentTimestamp)
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
    currentTime = moment.unix(currentTimestamp)
    async.times @sampleSize, (n, next) =>
      timestamp = moment(currentTime).add(n, 'seconds').unix()
      @client.llen "#{@queueName}:#{timestamp}", (error, count) =>
        return next error if error?
        return next new Error('too many items in the second queue') if count > 1
        return next null, {timestamp} if count == 0
        @client.brpop "#{@queueName}:#{timestamp}", 1, (error, result) =>
          return next error if error?
          data = JSON.parse result[1]
          return next new Error 'Record ID does not match' unless data.recordId == recordId
          return next new Error 'Timestamp does not match' unless _.parseInt(data.timestamp) == timestamp
          next null, {timestamp,value:data}
    , callback

module.exports = Seconds
