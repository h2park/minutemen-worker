_          = require 'lodash'
cronParser = require 'cron-parser'
later      = require 'later'
moment     = require 'moment'
debug      = require('debug')('minute-man-worker:time-parser')

class TimeParser
  constructor: ({ @timestamp }) ->
    throw new Error 'TimeParser: requires timestamp' unless @timestamp?
    debug 'currentTime', @getCurrentTime().unix()
    @_offsetSeconds = 60

  getCurrentTime: =>
    return moment.unix(@timestamp).add(@_offsetSeconds, 'seconds')

  getMaxRangeTime: =>
    return @getCurrentTime().add(@_offsetSeconds, 'seconds')

  getMinRangeTime: =>
    return @getCurrentTime()

  getSecondsList: ({ intervalTime, cronString, processAt }) =>
    if intervalTime?
      secondsList = @_getSecondsListFromIntervalTime { intervalTime, processAt }
    else if cronString?
      secondsList = @_getSecondsListFromCronString { cronString }
    else
      throw new Error 'Invalid interval format'
    debug 'secondsList', secondsList
    return _.filter secondsList, @_inRange

  getNextProcessAt: ({ processAt, cronString, intervalTime }) =>
    return @getNextProcessAtFromIntervalTime { intervalTime, processAt } if intervalTime?
    return @getNextProcessAtFromCronString { cronString } if cronString?
    throw new Error 'Invalid interval format'

  getNextProcessAtFromIntervalTime: ({ processAt, intervalTime }) =>
    throw new Error 'getNextProcessAtFromIntervalTime: requires processAt' unless processAt?
    secondsList = @_getSecondsListFromIntervalTime { intervalTime, processAt, nextWindow: true }
    max = moment.unix(processAt).add(@_offsetSeconds, 'seconds').unix()
    nextSecond = _.find secondsList, (time) =>
      return time > max
    return nextSecond

  getNextProcessAtFromCronString: ({ cronString }) =>
    secondsList = @_getSecondsListFromCronString { cronString, nextWindow: true }
    nextSecond = _.find secondsList, (time) =>
      return time > @getMaxRangeTime().unix()
    return nextSecond

  _getSecondsListFromCronString: ({ cronString, nextWindow }) =>
    hasSeconds = @_hasSeconds cronString
    debug { hasSeconds, cronString }
    parser = later.parse.cron(cronString, hasSeconds)
    schedules = later.schedule(parser)
    return @_getNextSecondFromSchedules(schedules) if nextWindow
    return @_getSecondsFromSchedules(schedules)

  _getSecondsListFromIntervalTime: ({ intervalTime, processAt, nextWindow }) =>
    throw new Error '_getSecondsListFromIntervalTime: requires processAt' unless processAt?
    debug 'processAt', processAt
    intervalSeconds = @_getSecondsFromMs(intervalTime)
    startDate = moment.unix(processAt)
    startDate = startDate.add(@_offsetSeconds, 'seconds') if nextWindow
    debug 'startDate', startDate.unix()
    return [startDate.unix()] if intervalSeconds > @_offsetSeconds and @_inRange startDate.unix()
    return @_getSecondsFromIntervalSeconds { intervalSeconds, startDate }

  _inRange: (timestamp) =>
    min = @getMinRangeTime()
    max = @getMaxRangeTime()
    inRange = timestamp >= min.unix() and timestamp < max.unix()
    debug "#{timestamp} >= #{min.unix()} and #{timestamp} < #{max.unix()}", { inRange }
    return inRange

  _getSecondsFromMs: (ms) =>
    return _.round(ms / 1000)

  _getSecondsFromSchedules: (schedules) =>
    min = @getMinRangeTime()
    max = @getMaxRangeTime().add(1, 'second')
    timesList = _.compact(schedules.next(@_offsetSeconds, min.toDate(), max.toDate()))
    return _.map timesList, (time) => moment(time).unix()

  _getNextSecondFromSchedules: (schedules) =>
    max = @getMaxRangeTime()
    debug 'max', max.unix()
    timesList = _.compact(schedules.next(@_offsetSeconds, max.toDate()))
    return _.map timesList, (time) => moment(time).unix()

  _getSecondsFromIntervalSeconds: ({ intervalSeconds, startDate, nextWindow }) =>
    debug 'intervalSeconds', intervalSeconds
    startDate = moment(startDate)
    secondsList = []
    _.times @_offsetSeconds, =>
      secondWindow = startDate.unix()
      startDate.add(intervalSeconds, 'seconds')
      secondsList.push secondWindow
    return secondsList

  _hasSeconds: (cronString) =>
    return _.size(_.trim(cronString).split(' ')) == 6

module.exports = TimeParser
