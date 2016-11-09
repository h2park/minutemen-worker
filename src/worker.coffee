_          = require 'lodash'
async      = require 'async'
PaulRevere = require './controllers/paul-revere'

class Worker
  constructor: (options={})->
    { client, queueName, database } = options
    { @timestamp, offsetSeconds } = options
    throw new Error('Worker: requires client') unless client?
    throw new Error('Worker: requires queueName') unless queueName?
    throw new Error('Worker: requires queueName to be a string') unless _.isString(queueName)
    throw new Error('Worker: requires database') unless database?
    throw new Error('Worker: requires offsetSeconds') unless offsetSeconds?
    throw new Error('Worker: requires offsetSeconds to be an integer') unless _.isInteger(offsetSeconds)
    @shouldStop = false
    @isStopped  = false
    @paulRevere = new PaulRevere {
      database,
      client,
      queueName,
      offsetSeconds,
    }

  doWithNextTick: (callback) =>
    # give some time for garbage collection
    process.nextTick =>
      @do (error) =>
        process.nextTick =>
          callback error

  do: (callback) =>
    @paulRevere.getTime (error, timestamp) =>
      return callback error if error?
      @paulRevere.findAndDeploySoldier timestamp, (error) =>
        return callback error if error? and error?.code != 404
        return callback null
    return # avoid returning promise

  run: (callback) =>
    async.doUntil @doWithNextTick, (=> @shouldStop), =>
      @isStopped = true
      callback null

  stop: (callback) =>
    @shouldStop = true

    timeout = setTimeout =>
      clearInterval interval
      callback new Error 'Stop Timeout Expired'
    , 5000

    interval = setInterval =>
      return unless @isStopped
      clearInterval interval
      clearTimeout timeout
      callback()
    , 250

module.exports = Worker
