_          = require 'lodash'
cronParser = require 'cron-parser'
moment     = require 'moment'
TimeRange  = require './time-range'
debug      = require('debug')('minutemen-worker:time-generator')

class TimeGenerator
  constructor: ({ @timeRange, @cronString, intervalTime }) ->
    throw new Error 'TimeGenerator: requires timeRange' unless @timeRange?
    throw new Error 'TimeGenerator: requires intervalTime to be an integer' if intervalTime? and !_.isInteger(intervalTime)
    throw new Error 'TimeGenerator: requires cronString to be a string' if @cronString? and !_.isString(@cronString)
    throw new Error 'TimeGenerator: requires either cronString or intervalTime' unless intervalTime? || @cronString?
    @intervalSeconds = @_intervalTimeToSeconds(intervalTime) if intervalTime?

  getIntervalsForTimeRange: =>
    max   = @timeRange.max()
    min   = @timeRange.min()
    start = @timeRange.start()
    return @_getSecondsFromCron({ min, max }) if @cronString?
    return @_getSecondsFromInterval({ min, max, start })

  getNextProcessAt: =>
    return @timeRange.nextWindow()

  _intervalTimeToSeconds: (intervalTime) =>
    return _.round(intervalTime / 1000)

  _getSecondsFromInterval: ({ start, min, max }) =>
    debug '_getSecondsFromInterval', {@intervalSeconds, min, max, start}
    secondsList = []
    second = start
    while second <= max
      secondsList.push second if second >= min
      second = @_getNextProcessAtFromInterval { second }
    return secondsList

  _getNextProcessAtFromInterval: ({ second }) =>
    return @intervalSeconds + second

  _getSecondsFromCron: ({ min, max }) =>
    debug '_getSecondsFromCron', {@cronString, min, max}
    secondsList = []
    second = @_getNextProcessAtFromCron { second: min }
    while second <= max
      secondsList.push second
      second = @_getNextProcessAtFromCron { second }
    return secondsList

  _getNextProcessAtFromCron: ({ second }) =>
    currentDate = moment.unix(second).toDate()
    parser = cronParser.parseExpression @cronString, { currentDate }
    nextTime = @_getNextTimeFromCronParser(parser)
    debug 'uh oh', nextTime, second if nextTime == second
    nextTime = @_getNextTimeFromCronParser(parser) if nextTime == second
    return nextTime

  _getNextTimeFromCronParser: (parser) =>
    return moment(parser.next()?.toDate().valueOf()).unix()

module.exports = TimeGenerator
