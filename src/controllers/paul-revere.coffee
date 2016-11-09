_             = require 'lodash'
async         = require 'async'
moment        = require 'moment'
Soldiers      = require '../models/soldiers'
TimeRange     = require '../models/time-range'
TimeGenerator = require '../models/time-generator'
debug         = require('debug')('minute-man-worker:paul-revere')
overview      = require('debug')('minute-man-worker:paul-revere:overview')

class PaulRevere
  constructor: ({ database, @client, @queueName, @offsetSeconds }) ->
    throw new Error('PaulRevere: requires database') unless database?
    throw new Error('PaulRevere: requires client') unless @client?
    throw new Error('PaulRevere: requires queueName') unless @queueName?
    throw new Error('PaulRevere: requires queueName to be a string') unless _.isString(@queueName)
    throw new Error('PaulRevere: requires offsetSeconds') unless @offsetSeconds?
    throw new Error('PaulRevere: requires offsetSeconds to be an integer') unless _.isInteger(@offsetSeconds)
    @soldiers = new Soldiers { database, @offsetSeconds }

  getTime: (callback) =>
    @client.time (error, result) =>
      return callback error if error?
      [ timestamp ] = result ? []
      return callback new Error('Missing timestamp in redis') unless timestamp?
      timestamp = _.parseInt timestamp
      return callback new Error('Timestamp is not a integer') unless _.isInteger(timestamp)
      callback null, timestamp
    return # stupid redis promise fix

  findAndDeploySoldier: (timestamp, callback) =>
    timestamp = _.clone timestamp
    @soldiers.get { timestamp }, (error, record) =>
      return callback(error) if error?
      return callback(@_createNotFoundError()) unless record?
      @_processSoldier { record, timestamp }, callback

  _processSoldier: ({ record, timestamp }, callback) =>
    return callback new Error 'Missing record in _processSoldier' unless record?
    return callback new Error 'Missing record._id in _processSoldier' unless record._id?
    return callback new Error 'Missing timestamp in _processSoldier' unless timestamp?
    debug 'process solider', { record }
    { metadata, data } = record
    {
      intervalTime,
      cronString,
      processAt,
      processNow,
      lastRunAt,
      fireOnce,
    } = metadata
    recordId      = record._id
    timeRange     = new TimeRange { timestamp, lastRunAt, processNow, @offsetSeconds, fireOnce }
    timeGenerator = new TimeGenerator { timeRange, intervalTime, cronString }
    secondsList   = timeGenerator.getCurrentSeconds()
    secondsList   = [_.first(secondsList)] if fireOnce && _.size(secondsList) > 0
    @_deploySoldier { secondsList, recordId }, (error) =>
      return callback(error) if error?
      nextProcessAt = timeGenerator.getNextSecond()
      timestamp     = timeRange.current()
      @soldiers.update { recordId, nextProcessAt, processAt, timestamp }, callback

  _deploySoldier: ({ secondsList, recordId }, callback) =>
    #debug 'deploy solider', secondsList, recordId
    overview "inserting #{_.size(secondsList)} seconds for #{recordId}"
    overview "first: #{_.first(secondsList)} last: #{_.last(secondsList)}" if _.size(secondsList) > 0
    async.eachSeries secondsList, async.apply(@_pushSecond, recordId), callback

  _pushSecond: (recordId, timestamp, callback) =>
    #debug 'lpushing', { timestamp, recordId }
    data = {recordId,timestamp}
    @client.lpush "#{@queueName}:#{timestamp}", JSON.stringify(data), callback
    return # redis fix

  _createNotFoundError: =>
    error = new Error 'Not Found'
    error.code = 404
    return error

module.exports = PaulRevere
