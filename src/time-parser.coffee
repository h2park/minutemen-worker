_          = require 'lodash'
cronParser = require 'cron-parser'
moment     = require 'moment'
debug      = require('debug')('minute-man-worker:time-parser')

class TimeParser
  constructor: ({ @timestamp }) ->
    debug 'timestamp', @timestamp
    throw new Error 'TimeParser: requires timestamp' unless @timestamp?
    @minTimeDiff = 500

  getCurrentTime: =>
    return moment.unix(@timestamp).add(1, 'minute')

  getMaxRangeTime: =>
    return @getCurrentTime().add(1, 'minute').unix()

  getMinRangeTime: =>
    return @getCurrentTime().unix()

  getSecondsList: ({ intervalTime, cronString, processAt }) =>
    return @_getSecondsListFromIntervalTime { intervalTime, processAt } if intervalTime?
    return @_getSecondsListFromCronString { cronString, processAt } if cronString?
    throw new Error 'Invalid interval format'

  getNextProcessAt: ({ processAt, cronString, intervalTime }) =>
    return @_getNextProcessAtFromIntervalTime { intervalTime, processAt } if intervalTime?
    return @_getNextProcessAtFromCronString { cronString, processAt } if cronString?
    throw new Error 'Invalid interval format'

  getNextTimeFromCronParser: (parser) =>
    nextDate = null
    timeDiff = 0
    while timeDiff <= @minTimeDiff
      nextDate = parser.next()?.toDate()
      if nextDate?
        nextDate.setMilliseconds 0
        timeDiff = nextDate - @getCurrentTime().valueOf()
    return moment(nextDate.valueOf()).unix()

  _getNextProcessAtFromIntervalTime: ({ processAt, intervalTime }) =>
    throw new Error '_getNextProcessAtFromIntervalTime: requires processAt' unless processAt?
    intervalSeconds = @_getSecondsFromMs(intervalTime)
    oneMinute = 1000 * 60
    intervalSeconds = 60 if intervalTime < oneMinute
    moment.unix(processAt).add(intervalSeconds, 'seconds').unix()

  _getSecondsListFromCronString: ({ cronString }) =>
    # passing in currentDate only sets the timezone
    parser = cronParser.parseExpression cronString, {currentDate: @getCurrentTime().toDate() }
    nextTimestamp = @getNextTimeFromCronParser(parser)
    secondsList = []
    debug 'cronString nextTimestamp', nextTimestamp
    while @_inRange nextTimestamp, 0, 1
      secondsList.push nextTimestamp
      nextTimestamp = @getNextTimeFromCronParser(parser)
    return secondsList

  _getSecondsListFromIntervalTime: ({ intervalTime, processAt }) =>
    throw new Error '_getSecondsListFromIntervalTime: requires processAt' unless processAt?
    intervalSeconds = @_getSecondsFromMs(intervalTime)
    times           = _.round(60 / intervalSeconds)
    offset          = _.round(60 / times)
    secondsList = _.times times, (n) =>
      moment.unix(processAt).add((offset * n), 'seconds').unix()
    return _.filter secondsList, (item) => @_inRange item

  _inRange: (timestamp, minOffset=0, maxOffset=0) =>
    min = @getMinRangeTime() + minOffset
    max = @getMaxRangeTime() + maxOffset
    debug "#{timestamp} >= #{min} and #{timestamp} < #{max}"
    return timestamp >= min and timestamp < max

  _getSecondsFromMs: (ms) =>
    _.round(ms / 1000)

module.exports = TimeParser
