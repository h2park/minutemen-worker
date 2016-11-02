_          = require 'lodash'
cronParser = require 'cron-parser'
moment     = require 'moment'
debug      = require('debug')('minute-man-worker:time-parser')

class TimeParser
  constructor: ({ @timestamp }) ->
    throw new Error 'TimeParser: requires timestamp' unless @timestamp?
    @_offsetSeconds = 60
    @_numberOfSecondsToCapture = @_offsetSeconds * 2
    debug 'currentTime', @getCurrentTime().unix()
    debug 'max', @getMaxRangeTime().unix()
    debug 'min', @getMinRangeTime().unix()

  getCurrentTime: =>
    return @_addOffset(@timestamp)

  getMaxRangeTime: =>
    return @_addOffset(@getCurrentTime().unix())

  getMinRangeTime: =>
    return @getCurrentTime()

  getMinRangeTimeFromProcessAt: (processAt) =>
    return @getMinRangeTime() if processAt < @getMinRangeTime().unix()
    return @getMaxRangeTime() if processAt > @getMaxRangeTime().unix()
    return moment.unix(processAt)

  _addOffset: (timestamp) =>
    return moment.unix(timestamp).add(@_offsetSeconds, 'seconds')

  getSecondsList: ({ intervalTime, cronString, processAt }) =>
    debug 'getSecondsList', { intervalTime, cronString, processAt }
    if intervalTime?
      secondsList = @_getSecondsListFromIntervalTime { intervalTime, processAt }
    else if cronString?
      secondsList = @_getSecondsListFromCronString { cronString , processAt }
    else
      throw new Error 'Invalid interval format'
    return @_getCurrentSecondsFromList secondsList, processAt

  getNextProcessAt: ({ intervalTime, cronString, processAt }) =>
    debug 'getNextProcessAt', { intervalTime, cronString, processAt }
    if intervalTime?
      secondsList = @_getSecondsListFromIntervalTime { intervalTime, processAt }
    else if cronString?
      secondsList = @_getSecondsListFromCronString { cronString, processAt }
    else
      throw new Error 'Invalid interval format'
    return @_getNextSecondFromList secondsList, processAt

  _getSecondsListFromCronString: ({ cronString, processAt }) =>
    throw new Error 'getNextProcessAtFromCronString: requires processAt' unless processAt?
    throw new Error 'getNextProcessAtFromCronString: requires cronString' unless cronString?
    return @_getSecondsFromCronString { cronString, processAt }

  _getSecondsListFromIntervalTime: ({ intervalTime, processAt }) =>
    throw new Error '_getSecondsListFromIntervalTime: requires processAt' unless processAt?
    throw new Error '_getSecondsListFromIntervalTime: requires intervalTime' unless intervalTime?
    intervalSeconds =  @_intervalTimeToSeconds(intervalTime)
    return @_getSecondsFromIntervalSeconds { intervalSeconds, processAt }

  _getNextSecondFromList: (secondsList, processAt) =>
    throw new Error '_getNextSecondFromList: requires secondsList' unless secondsList?
    throw new Error '_getNextSecondFromList: requires processAt' unless processAt?
    max = @getMaxRangeTime().unix()
    nextSecond = _.find secondsList, (time) =>
      inRange = time >= max
      # debug "next #{time} >= #{max}", inRange
      return inRange
    debug 'nextSecond', nextSecond
    return nextSecond

  _getCurrentSecondsFromList: (secondsList, processAt) =>
    throw new Error '_getCurrentSecondsFromList: requires secondsList' unless secondsList?
    throw new Error '_getCurrentSecondsFromList: requires processAt' unless processAt?
    max = @getMaxRangeTime().unix()
    min = @getMinRangeTimeFromProcessAt(processAt).unix()
    secondsList = _.filter secondsList, (time) =>
      inRange = time >= min and time < max
      #debug "current #{time} >= #{min} and #{time} < #{max}", inRange
      return inRange
    debug "found #{secondsList.length} seconds"
    return secondsList

  _intervalTimeToSeconds: (intervalTime) =>
    return _.round(intervalTime / 1000)

  _getSecondsFromIntervalSeconds: ({ intervalSeconds, processAt }) =>
    debug 'intervalSeconds', intervalSeconds
    startDate = @getMinRangeTime()
    debug 'interval startDate', startDate.unix()
    secondsList = []
    _.times @_numberOfSecondsToCapture, =>
      secondWindow = startDate.unix()
      startDate.add(intervalSeconds, 'seconds')
      secondsList.push secondWindow
    #debug 'secondsList', secondsList
    return secondsList

  _getSecondsFromCronString: ({ cronString, processAt }) =>
    debug 'cronString', cronString
    startDate = @getMinRangeTime().subtract(1, 'second')
    debug 'cron startDate', startDate.unix()
    secondsList = []
    _.times @_numberOfSecondsToCapture, =>
      secondWindow = @_calculateNextCronInterval { cronString, startDate }
      secondsList.push secondWindow
      startDate = moment.unix(secondWindow)
    #debug 'secondsList', secondsList
    return secondsList

  _calculateNextCronInterval: ({ cronString, startDate }) =>
    parser = cronParser.parseExpression cronString, currentDate: startDate.toDate()
    nextTime = @_getNextTimeFromCronParser(parser)
    nextTime = @_getNextTimeFromCronParser(parser) if nextTime.unix() == startDate.unix()
    return nextTime.unix()

  _getNextTimeFromCronParser: (parser) =>
    return moment(parser.next()?.toDate().valueOf())

module.exports = TimeParser
