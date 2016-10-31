_          = require 'lodash'
cronParser = require 'cron-parser'
later      = require 'later'
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

  _getNextProcessAtFromIntervalTime: ({ processAt, intervalTime }) =>
    throw new Error '_getNextProcessAtFromIntervalTime: requires processAt' unless processAt?
    intervalSeconds = @_getSecondsFromMs(intervalTime)
    oneMinute = 1000 * 60
    intervalSeconds = 60 if intervalTime < oneMinute
    moment.unix(processAt).add(intervalSeconds, 'seconds').unix()

  _getSecondsListFromCronString: ({ cronString }) =>
    # handle crazy seconds problem
    try
      parser = later.parse.cron(cronString, true)
      schedules = later.schedule(parser)
    catch
      parser = later.parse.cron(cronString)
      schedules = later.schedule(parser)
    return _.filter @_getNextTimes(schedules), @_inRange

  _getSecondsListFromIntervalTime: ({ intervalTime, processAt }) =>
    throw new Error '_getSecondsListFromIntervalTime: requires processAt' unless processAt?
    everySeconds = @_getSecondsFromMs(intervalTime)
    debug 'everySeconds', everySeconds
    parser = later.parse.recur()
      .every(everySeconds)
      .second()
    schedules = later.schedule(parser)
    return _.filter @_getNextTimes(schedules, processAt), @_inRange

  _inRange: (timestamp) =>
    min = @getMinRangeTime()
    max = @getMaxRangeTime()
    debug "#{timestamp} >= #{min} and #{timestamp} < #{max}"
    return timestamp >= min and timestamp < max

  _getSecondsFromMs: (ms) =>
    return _.round(ms / 1000)

  _getNextTimes: (schedules, minTime) =>
    debug 'minTime', minTime if minTime?
    min = moment.unix(minTime ? @getMinRangeTime())
    max = moment.unix(@getMaxRangeTime()).add(1, 'second')
    timesList = _.compact(schedules.next(60, min.toDate(), max.toDate()))
    secondsList = _.map timesList, (time) =>
      return moment(time).unix()
    debug 'secondsList', secondsList
    return secondsList

module.exports = TimeParser
