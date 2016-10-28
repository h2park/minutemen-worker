async      = require 'async'
PaulRevere = require './paul-revere'

class Worker
  constructor: (options={})->
    { client, queueName, database, timestampRedisKey } = options
    throw new Error('Worker: requires client') unless client?
    throw new Error('Worker: requires queueName') unless queueName?
    throw new Error('Worker: requires database') unless database?
    throw new Error('Worker: requires timestampRedisKey') unless timestampRedisKey?
    @shouldStop = false
    @isStopped = false
    @paulRevere = new PaulRevere {
      database,
      client,
      queueName,
      timestampRedisKey,
    }

  doWithNextTick: (callback) =>
    # give some time for garbage collection
    process.nextTick =>
      @do (error) =>
        process.nextTick =>
          callback error

  do: (callback) =>
    @paulRevere.findAndDeployMilitia(callback)
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
      return unless @isStopped?
      clearInterval interval
      clearTimeout timeout
      callback()
    , 250

module.exports = Worker
