_        = require 'lodash'
moment   = require 'moment'
debug    = require('debug')('minute-man-worker:time-generator')
overview = require('debug')('minute-man-worker:time-generator:overview')

class TimeRange
  constructor: ({ @timestamp, @lastRunAt, @offsetSeconds, @processNow, @fireOnce }) ->
    throw new Error 'TimeRange: requires timestamp' unless @timestamp?
    throw new Error 'TimeRange: requires timestamp to be an integer' unless _.isInteger(@timestamp)
    throw new Error 'TimeRange: requires offsetSeconds' unless @offsetSeconds?
    throw new Error 'TimeRange: requires offsetSeconds to be an integer' unless _.isInteger(@offsetSeconds)
    debug 'currentTime', @current()
    debug 'offset', @offset()
    debug 'nextMax', @nextMax()
    debug 'max', @max()
    debug 'min', @min()
    debug 'processNow', @processNow
    debug 'lastRunAt', @lastRunAt

  offset: =>
    return _.clone @offsetSeconds

  current: =>
    return _.clone @timestamp

  max: =>
    return @addOffset(@current())

  nextMax: =>
    return @addOffset(@max())

  min: =>
    return _.clone @lastRunAt if @lastRunAt > @current()
    return @current()

  start: =>
    return @current() unless @lastRunAt?
    return _.clone @lastRunAt

  sampleSize: =>
    return 1 if @fireOnce
    return @offset() * 4

  addOffset: (timestamp) =>
    return _.clone moment.unix(timestamp).add(@offset(), 'seconds').unix()

module.exports = TimeRange
