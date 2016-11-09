_          = require 'lodash'
cronParser = require 'cron-parser'
moment     = require 'moment'
TimeRange  = require './time-range'
debug      = require('debug')('minute-man-worker:time-generator')

class TimeGenerator
  constructor: ({ @timeRange, @cronString, intervalTime }) ->
    throw new Error 'TimeGenerator: requires timeRange' unless @timeRange?
    throw new Error 'TimeGenerator: requires intervalTime to be an integer' if intervalTime? and !_.isInteger(intervalTime)
    throw new Error 'TimeGenerator: requires cronString to be a string' if @cronString? and !_.isString(@cronString)
    throw new Error 'TimeGenerator: requires either cronString or intervalTime' unless intervalTime? || @cronString?
    @intervalSeconds = @_intervalTimeToSeconds(intervalTime) if intervalTime?
    @secondsList = _.sortedUniq @getSecondsList()
    debug 'secondsList', @secondsList

  getCurrentSeconds: =>
    max = @timeRange.max()
    min = @timeRange.min()
    debug {min,max}
    seconds = _.filter @secondsList, (second) =>
      result = second >= min and second < max
      #debug 'currentSeconds', min, second, max, result
      return result
    return seconds

  getNextSecond: =>
    max = @timeRange.nextMax()
    return _.find @secondsList, (time) =>
      return time >= max

  getSecondsList: =>
    debug 'getSecondsList', { @intervalSeconds, @cronString }
    return @_getSecondsFromIntervalSeconds() if @intervalSeconds?
    return @_getSecondsFromCronString() if @cronString?
    throw new Error 'Invalid interval format'

  _intervalTimeToSeconds: (intervalTime) =>
    return _.round(intervalTime / 1000)

  _getSecondsFromIntervalSeconds: =>
    debug '_getSecondsFromIntervalSeconds', {@intervalSeconds}
    min = @timeRange.min()
    iterations = @timeRange.sampleSize()
    return _.map _.times(iterations), (n) =>
      return (n * @intervalSeconds) + min

  _getSecondsFromCronString: =>
    debug '_getSecondsFromCronString', {@cronString}
    start = @_calculateNextCronInterval { start: (@timeRange.min() - 1) }
    iterations = @timeRange.sampleSize()
    secondsList = []
    _.times iterations, =>
      secondsList.push start
      start = @_calculateNextCronInterval { start }
    return secondsList

  _calculateNextCronInterval: ({ start }) =>
    currentDate = moment.unix(start).toDate()
    parser = cronParser.parseExpression @cronString, { currentDate }
    nextTime = @_getNextTimeFromCronParser(parser)
    nextTime = @_getNextTimeFromCronParser(parser) if nextTime == start
    return nextTime

  _getNextTimeFromCronParser: (parser) =>
    return moment(parser.next()?.toDate().valueOf()).unix()

module.exports = TimeGenerator
