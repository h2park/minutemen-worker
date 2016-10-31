_          = require 'lodash'
cronParser = require 'cron-parser'
moment     = require 'moment'
debug      = require('debug')('minute-man-worker:time-parser')

class TimeParser
  constructor: ({ timestamp }) ->
    @currentTime = @_getMoment(timestamp)
    @currentDate = @currentTime.toDate()
    @minTimeDiff = 0

  toString: =>
    @currentTime.toDate().toString()

  lastMinute: =>
    return @currentTime.subtract(1, 'minute').unix()

  nextMinute: (timestamp) =>
    return @currentTime.add(1, 'minute').unix()

  getSecondsList: ({ intervalTime, cronString, processAt }) =>
    return @getSecondsListFromIntervalTime { intervalTime, processAt } if intervalTime?
    return @getSecondsListFromCronString { cronString, processAt } if cronString?
    throw new Error 'Invalid interval format'

  getNextTimeFromCronParser: (parser) =>
    nextDate = null
    timeDiff = 0
    while timeDiff <= @minTimeDiff
      nextDate = parser.next()?.toDate()
      if nextDate?
        nextDate.setMilliseconds 0
        timeDiff = nextDate - @currentDate.valueOf()
    return unless nextDate?
    return nextDate.valueOf() / 1000

  getSecondsListFromCronString: ({ cronString }) =>
    parser = cronParser.parseExpression cronString, {@currentDate}
    nextTimestamp = @getNextTimeFromCronParser(parser)
    secondsList = []
    debug 'cronString nextTimestamp', nextTimestamp
    while @isInMinute nextTimestamp
      secondsList.push nextTimestamp
      nextTimestamp = @getNextTimeFromCronParser(parser)
    return secondsList

  isInMinute: (timestamp) =>
    return timestamp <= @nextMinute() and timestamp > @lastMinute()

  getSecondsListFromIntervalTime: ({ intervalTime, processAt }) =>
    secondsList = @_getSecondsList { intervalTime, processAt }
    _.filter secondsList, (second) =>
      return second <= @nextMinute()
    return secondsList

  getNextProcessAt: ({ processAt, intervalTime }) =>
    intervalSeconds = @_getSecondsFromMs(intervalTime)
    oneMinute = 1000 * 60
    intervalSeconds = 60 if intervalTime < oneMinute
    @_getMoment(processAt).add(intervalSeconds, 'seconds').unix()

  _getSecondsList: ({ intervalTime, processAt }) =>
    intervalSeconds = @_getSecondsFromMs(intervalTime)
    times           = _.round(60 / intervalSeconds)
    offset          = _.round(60 / times)
    _.times times, (n) =>
      @_getMoment(processAt).add((offset * n), 'seconds').unix()

  _getSecondsFromMs: (ms) =>
    _.round(ms / 1000)

  _getMoment: (timestamp) =>
    moment(_.parseInt(timestamp) * 1000)

module.exports = TimeParser
