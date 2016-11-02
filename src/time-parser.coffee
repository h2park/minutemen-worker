_          = require 'lodash'
cronParser = require 'cron-parser'
moment     = require 'moment'
TimeRange  = require './time-range'
debug      = require('debug')('minute-man-worker:time-parser')

class TimeParser
  constructor: ({ @timeRange, @cronString, intervalTime, @processAt }) ->
    throw new Error 'TimeParser: requires timeRange' unless @timeRange?
    @processAt ?= @timeRange.current().unix()
    @intervalSeconds = @_intervalTimeToSeconds(intervalTime) if intervalTime?
    @secondsList = @getSecondsList()
    debug 'secondsList', @secondsList

  getMinRangeTimeFromProcessAt: =>
    return @timeRange.min() if @processAt < @timeRange.min().unix()
    return @timeRange.max() if @processAt > @timeRange.max().unix()
    return moment.unix(@processAt)

  getCurrentSeconds: =>
    max = @timeRange.max().unix()
    min = @getMinRangeTimeFromProcessAt().unix()
    return _.filter @secondsList, (time) =>
      return time >= min and time < max

  getNextSecond: =>
    max = @timeRange.max().unix()
    return _.find @secondsList, (time) =>
      return time >= max

  getSecondsList: =>
    debug 'getSecondsList', { @intervalSeconds, @cronString, @processAt }
    return @_getSecondsFromIntervalSeconds() if @intervalSeconds?
    return @_getSecondsFromCronString() if @cronString?
    throw new Error 'Invalid interval format'

  _intervalTimeToSeconds: (intervalTime) =>
    return _.round(intervalTime / 1000)

  _getSecondsFromIntervalSeconds: =>
    debug 'intervalSeconds', @intervalSeconds
    startDate = @timeRange.min()
    debug 'interval startDate', startDate.unix()
    secondsList = []
    _.times @timeRange.sampleSize(), =>
      secondWindow = startDate.unix()
      startDate.add(@intervalSeconds, 'seconds')
      secondsList.push secondWindow
      return
    #debug 'secondsList', secondsList
    return secondsList

  _getSecondsFromCronString: =>
    debug 'cronString', @cronString
    startDate = @timeRange.min().subtract(1, 'second')
    debug 'cron startDate', startDate.unix()
    secondsList = []
    _.times @timeRange.sampleSize(), =>
      secondWindow = @_calculateNextCronInterval { startDate }
      secondsList.push secondWindow
      startDate = moment.unix(secondWindow)
      return
    #debug 'secondsList', secondsList
    return secondsList

  _calculateNextCronInterval: ({ startDate }) =>
    parser = cronParser.parseExpression @cronString, currentDate: startDate.toDate()
    nextTime = @_getNextTimeFromCronParser(parser)
    nextTime = @_getNextTimeFromCronParser(parser) if nextTime.unix() == startDate.unix()
    return nextTime.unix()

  _getNextTimeFromCronParser: (parser) =>
    return moment(parser.next()?.toDate().valueOf())

module.exports = TimeParser
