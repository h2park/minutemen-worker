_          = require 'lodash'
moment     = require 'moment'

class TimeParser
  constructor: ({ timestamp }) ->
    @timestamp = @_getMoment(timestamp)

  toString: =>
    @timestamp.toDate().toString()

  lastMinute: =>
    return @timestamp.subtract(1, 'minute').unix()

  nextMinute: (timestamp) =>
    return @timestamp.add(1, 'minute').unix()

  getSecondsList: ({ intervalTime, processAt }) =>
    secondsList = @_getSecondsList { intervalTime, processAt }
    _.filter secondsList, (second) =>
      return second < @nextMinute()
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
