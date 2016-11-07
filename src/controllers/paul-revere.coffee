async         = require 'async'
Soldiers      = require '../models/soldiers'
TimeRange     = require '../models/time-range'
TimeGenerator = require '../models/time-generator'
debug         = require('debug')('minute-man-worker:paul-revere')
overview      = require('debug')('minute-man-worker:paul-revere:overview')

class PaulRevere
  constructor: ({ database, @client, @queueName, @timestamp }) ->
    throw new Error('PaulRevere: requires database') unless database?
    throw new Error('PaulRevere: requires client') unless @client?
    throw new Error('PaulRevere: requires queueName') unless @queueName?
    @soldiers = new Soldiers { database }

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
    { metadata, data } = record
    { intervalTime, cronString, processAt } = metadata
    recordId = record._id
    timeGenerator = new TimeGenerator { timeRange, intervalTime, processAt, cronString }
    secondsList = timeGenerator.getCurrentSeconds()
    @_deploySoldier { secondsList, recordId }, (error) =>
      return callback(error) if error?
      nextProcessAt = timeGenerator.getNextSecond()
      @soldiers.update { recordId, nextProcessAt, processAt }, callback

  _deploySoldier: ({ secondsList, recordId }, callback) =>
    debug 'deploy solider', secondsList, recordId
    overview "inserting #{secondsList.length} seconds for #{recordId}"
    async.eachSeries secondsList, async.apply(@_pushSecond, recordId), callback

  _pushSecond: (recordId, queue, callback) =>
    debug 'lpushing', { queue, recordId }
    @client.lpush "#{@queueName}:#{queue}", recordId, callback
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
