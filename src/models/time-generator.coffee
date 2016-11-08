_          = require 'lodash'
cronParser = require 'cron-parser'
moment     = require 'moment'
TimeRange  = require './time-range'
debug      = require('debug')('minute-man-worker:time-generator')

class TimeGenerator
  constructor: ({ @timeRange, @cronString, intervalTime, @processAt, @processNow, @fireOnce }) ->
    throw new Error 'TimeGenerator: requires timeRange' unless @timeRange?
    @processAt ?= @timeRange.current().unix()
    @intervalSeconds = @_intervalTimeToSeconds(intervalTime) if intervalTime?
    @secondsList = _.sortedUniq @getSecondsList()
    debug 'secondsList', @secondsList

  getCurrentSeconds: =>
    max = @timeRange.max().unix()
    min = @processAt - 1 if @processNow
    min = @processAt - 60 unless @processNow
    return _.filter @secondsList, (time) =>
      # console.log time, min, max
      return time >= min and time < max

  getNextSecond: =>
    max = @timeRange.max().unix()
    return _.find @secondsList, (time) =>
      return time >= ( max + 60 )

  getSecondsList: =>
    debug 'getSecondsList', { @intervalSeconds, @cronString, @processAt }
    return @_getSecondsFromIntervalSeconds() if @intervalSeconds?
    return @_getSecondsFromCronString() if @cronString?
    throw new Error 'Invalid interval format'

  _intervalTimeToSeconds: (intervalTime) =>
    return _.round(intervalTime / 1000)

  _getSecondsFromIntervalSeconds: =>
    debug 'intervalSeconds', @intervalSeconds
    # return [ @timeRange.min().add(@intervalSeconds, 'seconds').unix() ] if @fireOnce
    startDate = @timeRange.min()
    debug 'interval startDate', startDate.unix()
    secondsList = []
    iterations = 1
    iterations = @timeRange.sampleSize() unless @fireOnce
    _.times iterations, =>
      startDate.add(@intervalSeconds, 'seconds')
      secondWindow = startDate.unix()
      secondsList.push secondWindow
      return
    #debug 'secondsList', secondsList
    return secondsList

  _getSecondsFromCronString: =>
    debug 'cronString', @cronString
    return [ @timeRange.min().add(@intervalSeconds, 'seconds').unix() ] if @fireOnce
    startDate = @timeRange.min().subtract(1, 'second')
    debug 'cron startDate', startDate.unix()
    secondsList = []
    iterations = 1
    iterations = @timeRange.sampleSize() unless @fireOnce
    _.times iterations, =>
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

module.exports = TimeGenerator
