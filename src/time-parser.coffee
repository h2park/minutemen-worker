_          = require 'lodash'
cronParser = require 'cron-parser'
later      = require 'later'
moment     = require 'moment'
debug      = require('debug')('minute-man-worker:time-parser')

class TimeParser
  constructor: ({ @timestamp }) ->
    throw new Error 'TimeParser: requires timestamp' unless @timestamp?
    debug 'currentTime', @getCurrentTime().unix()
    @minTimeDiff = 500

  getCurrentTime: =>
    return moment.unix(@timestamp).add(1, 'minute')

  getMaxRangeTime: =>
    return @getCurrentTime().add(1, 'minute')

  getMinRangeTime: =>
    return @getCurrentTime()

  getSecondsList: ({ intervalTime, cronString, processAt }) =>
    if intervalTime?
      secondsList = @_getSecondsListFromIntervalTime { intervalTime, processAt }
    else if cronString?
      secondsList = @_getSecondsListFromCronString { cronString, processAt }
    else
      throw new Error 'Invalid interval format'
    return _.filter secondsList, @_inRange

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
    hasSeconds = @_hasSeconds cronString
    debug { hasSeconds, cronString }
    parser = later.parse.cron(cronString, hasSeconds)
    schedules = later.schedule(parser)
    return @_getNextFromSchedules(schedules)

  _getSecondsListFromIntervalTime: ({ intervalTime, processAt }) =>
    throw new Error '_getSecondsListFromIntervalTime: requires processAt' unless processAt?
    debug 'processAt', processAt
    intervalSeconds = @_getSecondsFromMs(intervalTime)
    return [processAt] if intervalSeconds > 60 and @_inRange processAt
    return @_getNextFromIntervalSeconds { intervalSeconds, processAt }

  _inRange: (timestamp) =>
    min = @getMinRangeTime()
    max = @getMaxRangeTime()
    debug "#{timestamp} >= #{min.unix()} and #{timestamp} < #{max.unix()}"
    return timestamp >= min.unix() and timestamp < max.unix()

  _getSecondsFromMs: (ms) =>
    return _.round(ms / 1000)

  _getNextFromSchedules: (schedules) =>
    min = @getMinRangeTime()
    max = @getMaxRangeTime().add(1, 'second')
    timesList = _.compact(schedules.next(60, min.toDate(), max.toDate()))
    return _.map timesList, (time) => moment(time).unix()

  _getNextFromIntervalSeconds: ({ intervalSeconds, processAt }) =>
    times  = _.round(60 / intervalSeconds)
    offset = _.round(60 / times)
    return _.times times, (n) =>
      return moment.unix(processAt).add((offset * n), 'seconds').unix()

  _hasSeconds: (cronString) =>
    return _.size(_.trim(cronString).split(' ')) == 6

module.exports = TimeParser
