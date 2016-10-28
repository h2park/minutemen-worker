_      = require 'lodash'
moment = require 'moment'
async  = require 'async'
debug  = require('debug')('minute-man-worker:paul-revere')

class PaulRevere
  constructor: ({ database, @client, @queueName, @timestampRedisKey }) ->
    throw new Error('PaulRevere: requires database') unless database?
    throw new Error('PaulRevere: requires client') unless @client?
    throw new Error('PaulRevere: requires queueName') unless @queueName?
    throw new Error('PaulRevere: requires timestampRedisKey') unless @timestampRedisKey?
    @collection = database.collection 'intervals'

  findAndDeployMilitia: (callback) =>
    @_getTimestamp (error, timestamp) =>
      return callback error if error?
      debug 'got timestamp', { timestamp }
      @_findMilitia { timestamp }, (error) =>
        return callback error if error?
        callback null

  _findMilitia: ({ timestamp }, callback) =>
    query =
      'data.intervalTime':
        $lt : 60000
      processAt:
        $gt: @_getPervDate(timestamp)
        $lt: @_getNextDate(timestamp)
    update =
      $inc:
        processAt: 60
    debug 'findAndModifying', { query, update }
    @collection.findAndModify { query, update, sort: -1 }, (error, record) =>
      return callback error if error?
      return callback null unless record?
      debug 'got record', { record }
      @_createMilitia record, callback

  _createMilitia: (record, callback) =>
    debug 'creating militia', { record }
    intervalTime = _.get(record, 'data.intervalTime')
    processAt = _.get(record, 'processAt')
    seconds = @_getSecondsQueues {intervalTime, processAt}
    async.eachSeries seconds, async.apply(@_pushSecond, record), callback

  _pushSecond: (record, queue, callback) =>
    debug 'lpushing', { queue, record }
    @client.lpush queue, JSON.stringify(record), callback

  _getPervDate: (timestamp) =>
    debug 'perv date', { timestamp }
    return moment(timestamp).subtract(1, 'minute').unix()

  _getNextDate: (timestamp) =>
    return moment(timestamp).add(1, 'minute').unix()

  _getSecondsQueues: ({ intervalTime, processAt }) =>
    intervalSeconds = _.round(intervalTime / 1000)
    times = _.round(60 / intervalSeconds)
    debug 'times', times
    return _.times times, (n) =>
      offset = 60 / times
      debug 'second queue', { n, offset, intervalTime, processAt }
      second = moment(processAt * 1000).add((offset * n), 'seconds').unix()
      return "#{@queueName}:#{second}"

  _getTimestamp: (callback) =>
    @client.get @timestampRedisKey, (error, timestamp) =>
      return callback error if error?
      return callback new Error('Missing timestamp in redis') unless timestamp?
      callback null, _.parseInt(timestamp) * 1000

module.exports = PaulRevere
