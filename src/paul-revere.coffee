_          = require 'lodash'
async      = require 'async'
TimeParser = require './time-parser'
Secrecy    = require './secrecy'
Soldiers   = require './soldiers'
debug      = require('debug')('minute-man-worker:paul-revere')

class PaulRevere
  constructor: ({ database, @client, @queueName, @timestamp }) ->
    throw new Error('PaulRevere: requires database') unless database?
    throw new Error('PaulRevere: requires client') unless @client?
    throw new Error('PaulRevere: requires queueName') unless @queueName?
    @soldiers = new Soldiers { database }
    @secrecy = new Secrecy { database }

  findAndDeploySoldier: (callback) =>
    @_getTimeParser (error, timeParser) =>
      return callback(error) if error?
      min = timeParser.getMinRangeTime().unix()
      max = timeParser.getMaxRangeTime().unix()
      @soldiers.get { min, max }, (error, record) =>
        return callback(error) if error?
        return callback() unless record?
        @_processSoldier { record, timeParser }, callback

  _processSoldier: ({ record, timeParser }, callback) =>
    debug 'process solider', { record }
    { processAt, data, _id } = record
    { intervalTime, cronString, fireOnce } = data
    processAt ?= timeParser.getCurrentTime().unix()
    secondsList = timeParser.getSecondsList {intervalTime, cronString, processAt}
    @_deploySoldier { secondsList, record, fireOnce }, (error) =>
      return callback(error) if error?
      return @soldiers.remove { _id }, callback if fireOnce
      nextProcessAt = timeParser.getNextProcessAt({ processAt, cronString, intervalTime })
      @soldiers.update { _id, nextProcessAt }, callback

  _deploySoldier: ({ secondsList, record, fireOnce }, callback) =>
    secondsList = [_.first(secondsList)] if fireOnce
    debug 'deploy solider', secondsList, { fireOnce }
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
    return # redis fix

module.exports = PaulRevere
