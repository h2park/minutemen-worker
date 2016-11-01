_          = require 'lodash'
cronParser = require 'cron-parser'
later      = require 'later'
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

  _addOffset: (timestamp) =>
    return moment.unix(timestamp).add(@_offsetSeconds, 'seconds')

  getSecondsList: ({ intervalTime, cronString, processAt }) =>
    if intervalTime?
      secondsList = @_getSecondsListFromIntervalTime { intervalTime, processAt }
    else if cronString?
      secondsList = @_getSecondsListFromCronString { cronString }
    else
      throw new Error 'Invalid interval format'
    return @_getCurrentSecondsFromList secondsList

  getNextProcessAt: ({ processAt, cronString, intervalTime }) =>
    if intervalTime?
      secondsList = @_getSecondsListFromIntervalTime { intervalTime, processAt }
    else if cronString?
      secondsList = @_getSecondsListFromCronString { cronString }
    else
      throw new Error 'Invalid interval format'
    return @_getNextSecondFromList secondsList

  _getSecondsListFromCronString: ({ cronString }) =>
    throw new Error 'getNextProcessAtFromCronString: requires cronString' unless cronString?
    hasSeconds = @_hasSeconds cronString
    debug { hasSeconds, cronString }
    parser = later.parse.cron(cronString, hasSeconds)
    schedules = later.schedule(parser)
    return @_getSecondsFromSchedules(schedules)

  _getSecondsListFromIntervalTime: ({ intervalTime, processAt }) =>
    throw new Error '_getSecondsListFromIntervalTime: requires processAt' unless processAt?
    throw new Error '_getSecondsListFromIntervalTime: requires intervalTime' unless intervalTime?
    debug 'processAt', processAt
    intervalSeconds = @_getSecondsFromMs(intervalTime)
    return @_getSecondsFromIntervalSeconds { intervalSeconds, processAt }

  _getNextSecondFromList: (secondsList) =>
    max = @getMaxRangeTime().unix()
    nextSecond = _.find secondsList, (time) =>
      inRange = time >= max
      debug "next #{time} >= #{max}", { inRange }
      return inRange
    debug 'nextSecond', nextSecond
    return nextSecond

  _getCurrentSecondsFromList: (secondsList) =>
    max = @getMaxRangeTime().unix()
    min = @getMinRangeTime().unix()
    secondsList = _.filter secondsList, (time) =>
      inRange = time >= min and time < max
      debug "current #{time} >= #{min} and #{time} < #{max}", { inRange }
      return inRange
    return secondsList

  _getSecondsFromMs: (ms) =>
    return _.round(ms / 1000)

  _getSecondsFromSchedules: (schedules) =>
    min = @getMinRangeTime().toDate()
    timesList = schedules.next(@_numberOfSecondsToCapture, min)
    return _.compact _.map timesList, (time) => moment(time).unix()

  _getSecondsFromIntervalSeconds: ({ intervalSeconds, processAt }) =>
    debug 'intervalSeconds', intervalSeconds
    startDate = moment.unix(processAt)
    debug 'startDate', startDate.unix()
    secondsList = []
    _.times @_numberOfSecondsToCapture, =>
      secondWindow = startDate.unix()
      startDate.add(intervalSeconds, 'seconds')
      secondsList.push secondWindow
    debug 'secondsList', secondsList
    return secondsList

  _hasSeconds: (cronString) =>
    return _.size(_.trim(cronString).split(' ')) == 6

module.exports = TimeParser
