_        = require 'lodash'
moment   = require 'moment'
debug    = require('debug')('minutemen-worker:time-generator')
overview = require('debug')('minutemen-worker:time-generator:overview')

class TimeRange
  constructor: ({ @timestamp, @lastRunAt, @offsetSeconds, @processNow }) ->
    throw new Error 'TimeRange: requires timestamp' unless @timestamp?
    throw new Error 'TimeRange: requires timestamp to be an integer' unless _.isInteger(@timestamp)
    throw new Error 'TimeRange: requires offsetSeconds' unless @offsetSeconds?
    throw new Error 'TimeRange: requires offsetSeconds to be an integer' unless _.isInteger(@offsetSeconds)
    debug 'timestamp', @timestamp
    debug 'max', @max()
    debug 'min', @min()
    debug 'processNow', @processNow
    debug 'lastRunAt', @lastRunAt

  max: =>
    return @min() + (@offsetSeconds * 2) if @processNow
    return @min() + @offsetSeconds

  nextWindow: =>
    return @timestamp + @offsetSeconds

  min: =>
    return @timestamp if @processNow
    return @timestamp + @offsetSeconds

  start: =>
    return @lastRunAt ? @timestamp

module.exports = TimeRange
