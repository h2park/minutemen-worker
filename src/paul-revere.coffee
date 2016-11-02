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
      @_findMilitia { timeParser }, callback

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
    sort = { processAt: 1 }
    debug 'findAndModifying.query', query
    debug 'findAndModifying.update', update
    debug 'findAndModifying.sort', sort
    @collection.findAndModify { query, update, sort }, (error, record) =>
      return callback error if error?
      debug 'no record found' unless record?
      return callback null unless record?
      debug 'got record', { record }
      @_processMilitia { record, timeParser }, callback

  _processMilitia: ({ record, timeParser }, callback) =>
    debug 'process militia', { record }
    { processAt, data } = record
    { intervalTime, cronString, fireOnce } = data
    processAt ?= timeParser.getCurrentTime().unix()
    secondsList = timeParser.getSecondsList {intervalTime, cronString, processAt}
    @_deployMilitia { secondsList, record, fireOnce }, (error) =>
      return callback error if error?
      return @_removeMilitia { record }, callback if fireOnce
      nextProcessAt = timeParser.getNextProcessAt({ processAt, cronString, intervalTime })
      @_updateMilitia { record, nextProcessAt }, callback

  _deployMilitia: ({ secondsList, record, fireOnce }, callback) =>
    secondsList = [_.first(secondsList)] if fireOnce
    debug 'deploy militia', secondsList, { fireOnce }
    async.eachSeries secondsList, async.apply(@_pushSecond, record), callback

  _removeMilitia: ({ record }, callback) =>
    debug 'removing militia'
    @collection.remove { _id: record._id }, callback

  _updateMilitia: ({ record, nextProcessAt }, callback) =>
    query  = _id: record._id
    update =
      processing: false
      processAt:  nextProcessAt
    debug 'updating militia', { query, update }
    @collection.update query, { $set: update }, callback

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
    return # redis fix

module.exports = PaulRevere
