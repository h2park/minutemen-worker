_          = require 'lodash'
async      = require 'async'
TimeParser = require './time-parser'
debug      = require('debug')('minute-man-worker:paul-revere')

class PaulRevere
  constructor: ({ database, @client, @queueName, @timestampRedisKey }) ->
    throw new Error('PaulRevere: requires database') unless database?
    throw new Error('PaulRevere: requires client') unless @client?
    throw new Error('PaulRevere: requires queueName') unless @queueName?
    @collection = database.collection 'intervals'

  findAndDeployMilitia: (callback) =>
    @_getTimeParser (error, timeParser) =>
      return callback error if error?
      debug 'got timeParser', timeParser.toString()
      @_findMilitia { timeParser }, (error) =>
        return callback error if error?
        callback null

  _findMilitia: ({ timeParser }, callback) =>
    query =
      processing: { $ne: true }
      $or: [
        {
          processAt: {
            $gt: timeParser.lastMinute()
            $lte: timeParser.nextMinute()
          }
        }
        { processAt: $exists: false }
      ]
    update = $set: { processing: true }
    debug 'findAndModifying', query, update
    debug 'lastMinute', timeParser.lastMinute()
    debug 'nextMinute', timeParser.nextMinute()
    @collection.findAndModify { query, update, sort: -1 }, (error, record) =>
      return callback error if error?
      return callback null unless record?
      debug 'got record', { record }
      @_processMilitia { record, timeParser }, callback

  _processMilitia: ({ record, timeParser }, callback) =>
    debug 'process militia', { record }
    { processAt, data } = record
    { intervalTime, cronString } = data
    secondsList = timeParser.getSecondsList {intervalTime, cronString, processAt}
    @_deployMilitia { secondsList, record }, (error) =>
      return callback error if error?
      query  = _id: record._id
      update =
        processing: false
        processAt:  timeParser.getNextProcessAt({ processAt, intervalTime })
      @collection.update query, { $set: update }, callback

  _deployMilitia: ({ secondsList, record }, callback) =>
    debug 'deploy militia', _.size(secondsList)
    async.eachSeries secondsList, async.apply(@_pushSecond, record), callback

  _pushSecond: (record, queue, callback) =>
    debug 'lpushing', { queue, record }
    @client.lpush "#{@queueName}:#{queue}", JSON.stringify(record), callback
    return # redis fix

  _getTimeParser: (callback) =>
    @client.time (error, result) =>
      return callback error if error?
      [ timestamp ] = result ? []
      return callback new Error('Missing timestamp in redis') unless timestamp?
      callback null, new TimeParser { timestamp }

module.exports = PaulRevere
