_             = require 'lodash'
async         = require 'async'
moment        = require 'moment'
Soldiers      = require '../models/soldiers'
TimeRange     = require '../models/time-range'
TimeGenerator = require '../models/time-generator'
debug         = require('debug')('minute-man-worker:paul-revere')
overview      = require('debug')('minute-man-worker:paul-revere:overview')

class PaulRevere
  constructor: ({ database, @client, @queueName }) ->
    throw new Error('PaulRevere: requires database') unless database?
    throw new Error('PaulRevere: requires client') unless @client?
    throw new Error('PaulRevere: requires queueName') unless @queueName?
    @soldiers = new Soldiers { database }

  getTime: (callback) =>
    @client.time (error, result) =>
      return callback error if error?
      [ timestamp ] = result ? []
      return callback new Error('Missing timestamp in redis') unless timestamp?
      callback null, _.parseInt timestamp
    return # stupid redis promise fix

  findAndDeploySoldier: (timestamp, callback) =>
    timeRange = new TimeRange { timestamp }
    max = timeRange.max().unix()
    min = timeRange.min().unix()
    @soldiers.get { max, min }, (error, record) =>
      return callback(error) if error?
      return callback(@_createNotFoundError()) unless record?
      @_processSoldier { record, timeRange }, callback

  _processSoldier: ({ record, timeRange }, callback) =>
    debug 'process solider', { record }
    { metadata, data } = record
    { intervalTime, cronString, processAt, processNow } = metadata
    { fireOnce } = data
    recordId = record._id
    timeGenerator = new TimeGenerator { timeRange, intervalTime, processAt, cronString, processNow, fireOnce }
    secondsList = timeGenerator.getCurrentSeconds()
    @_deploySoldier { secondsList, recordId }, (error) =>
      return callback(error) if error?
      nextProcessAt = timeGenerator.getNextSecond()
      overview 'now', moment().unix()
      overview 'min', timeRange.min().unix()
      overview 'max', timeRange.max().unix()
      overview 'current', timeRange.current().unix()
      @soldiers.update { recordId, nextProcessAt, processAt }, callback

  _deploySoldier: ({ secondsList, recordId }, callback) =>
    debug 'deploy solider', secondsList, recordId
    overview "inserting #{secondsList.length} seconds for #{recordId}"
    async.eachSeries secondsList, async.apply(@_pushSecond, recordId), callback

  _pushSecond: (recordId, timestamp, callback) =>
    debug 'lpushing', { timestamp, recordId }
    data = {recordId,timestamp}
    @client.lpush "#{@queueName}:#{timestamp}", JSON.stringify(data), callback
    return # redis fix

  _createNotFoundError: =>
    error = new Error 'Not Found'
    error.code = 404
    return error

module.exports = PaulRevere
