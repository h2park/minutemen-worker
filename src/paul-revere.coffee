_          = require 'lodash'
async      = require 'async'
TimeParser = require './time-parser'
TimeRange       = require './time-range'
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
    @_getTimeRange (error, timeRange) =>
      return callback(error) if error?
      min = timeRange.min().unix()
      max = timeRange.max().unix()
      @soldiers.get { min, max }, (error, record) =>
        return callback(error) if error?
        return callback() unless record?
        @_processSoldier { record, timeRange }, callback

  _processSoldier: ({ record, timeRange }, callback) =>
    debug 'process solider', { record }
    { _id, metadata, data } = record
    { intervalTime, cronString, fireOnce, processAt } = metadata
    timeParser = new TimeParser { timeRange, intervalTime, processAt, cronString }
    secondsList = timeParser.getCurrentSeconds()
    @_deploySoldier { secondsList, data, fireOnce }, (error) =>
      return callback(error) if error?
      return @soldiers.remove { _id }, callback if fireOnce
      nextProcessAt = timeParser.getNextSecond()
      @soldiers.update { _id, nextProcessAt, processAt }, callback

  _deploySoldier: ({ secondsList, data, fireOnce }, callback) =>
    secondsList = [_.first(secondsList)] if fireOnce
    debug 'deploy solider', secondsList, { fireOnce }
    async.eachSeries secondsList, async.apply(@_pushSecond, data), callback

  _pushSecond: (data, queue, callback) =>
    debug 'lpushing', { queue, data }
    @client.lpush "#{@queueName}:#{queue}", JSON.stringify(data), callback
    return # redis fix

  _getTimeRange: (callback) =>
    return callback null, new TimeRange { @timestamp } if @timestamp?
    @client.time (error, result) =>
      return callback error if error?
      [ timestamp ] = result ? []
      return callback new Error('Missing timestamp in redis') unless timestamp?
      callback null, new TimeRange({ timestamp })
    return # redis fix

module.exports = PaulRevere
