_          = require 'lodash'
async      = require 'async'
TimeParser = require './time-parser'
debug      = require('debug')('minute-man-worker:paul-revere')

class PaulRevere
  constructor: ({ database, @client, @queueName, @timestamp }) ->
    throw new Error('PaulRevere: requires database') unless database?
    throw new Error('PaulRevere: requires client') unless @client?
    throw new Error('PaulRevere: requires queueName') unless @queueName?
    @collection = database.collection 'intervals'

  findAndDeployMilitia: (callback) =>
    @_getTimeParser (error, timeParser) =>
      return callback error if error?
      debug 'got timeParser', timeParser.getCurrentTime().unix()
      @_findMilitia { timeParser }, (error) =>
        return callback error if error?
        callback null

  _findMilitia: ({ timeParser }, callback) =>
    query =
      processing: { $ne: true }
      $or: [
        {
          processAt: {
            $gte: timeParser.getMinRangeTime().unix()
            $lt: timeParser.getMaxRangeTime().unix()
          }
        }
        { processAt: $exists: false }
      ]
    update = $set: { processing: true }
    debug 'findAndModifying', JSON.stringify { query, update }, null, 2
    @collection.findAndModify { query, update, sort: { processAt: 1 } }, (error, record) =>
      return callback error if error?
      debug 'no record found' unless record?
      return callback null unless record?
      debug 'got record', { record }
      @_processMilitia { record, timeParser }, callback

  _processMilitia: ({ record, timeParser }, callback) =>
    debug 'process militia', { record }
    { processAt, data } = record
    { intervalTime, cronString } = data
    processAt ?= timeParser.getCurrentTime().unix()
    secondsList = timeParser.getSecondsList {intervalTime, cronString, processAt}
    @_deployMilitia { secondsList, record }, (error) =>
      return callback error if error?
      query  = _id: record._id
      update =
        processing: false
        processAt:  timeParser.getNextProcessAt({ processAt, cronString, intervalTime })
      debug 'updating militia', { query, update }
      @collection.update query, { $set: update }, callback

  _deployMilitia: ({ secondsList, record }, callback) =>
    debug 'deploy militia', _.size(secondsList)
    async.eachSeries secondsList, async.apply(@_pushSecond, record), callback

  _pushSecond: (record, queue, callback) =>
    debug 'lpushing', { queue, record: record._id }
    @client.lpush "#{@queueName}:#{queue}", JSON.stringify(record), callback
    return # redis fix

  _getTimeParser: (callback) =>
    return callback null, new TimeParser { @timestamp } if @timestamp?
    @client.time (error, result) =>
      return callback error if error?
      [ timestamp ] = result ? []
      return callback new Error('Missing timestamp in redis') unless timestamp?
      callback null, new TimeParser { timestamp }

module.exports = PaulRevere
