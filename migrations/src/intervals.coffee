_     = require 'lodash'
debug = require('debug')('migrate:intervals')

class Intervals
  constructor: ({ database, @client, @skip, @limit, @flowId }) ->
    throw new Error 'Intervals: requires database' unless database?
    throw new Error 'Intervals: requires skip' unless @skip?
    throw new Error 'Intervals: requires limit' unless @limit?
    throw new Error 'Intervals: requires client' unless @client?
    @pageSize = 100
    @collection = database.collection 'intervals'
    @totalProcessed = 0

  getBatch: (callback) =>
    return callback null, [] if @totalProcessed >= @limit
    limit = @limit if @limit < @pageSize
    limit ?= @pageSize
    query = {
      data: {$exists:true}
      'data.fireOnce': {$ne: true}
    }
    query.ownerId = @flowId if @flowId?
    @collection
      .find(query)
      .sort({_id: -1})
      .limit(limit)
      .skip(@totalProcessed + @skip)
      .toArray (error, records) =>
        return callback error if error?
        @totalProcessed += _.size(records)
        debug 'totalProcessed', @totalProcessed
        callback null, records

  getCredentials:  (interval, callback) =>
    @getCredentialsFromRedis interval, (error, interval) =>
      return callback error if error?
      @getCredentialsFromMongo interval, callback

  getCredentialsFromRedis: (interval, callback) =>
    { ownerId, id, token } = interval
    { nodeId } = interval.data ? {}
    return callback null, interval if id? && token?
    { transactionId } = data ? {}
    redisNodeId = transactionId ? nodeId
    debug 'redis get credentials', {redisNodeId,ownerId}
    @client.mget [
      "interval/uuid/#{ownerId}/#{redisNodeId}",
      "interval/token/#{ownerId}/#{redisNodeId}",
    ], (error, results) =>
      return callback error if error?
      debug 'redis got credentials', results
      [uuid, token] = results
      interval.id = uuid if uuid?
      interval.token = token if token?
      callback null, interval

  getCredentialsFromMongo: (interval, callback) =>
    { ownerId, id, token } = interval
    { nodeId } = interval.data ? {}
    return callback null, interval if id? && token?
    return callback new Error 'Missing nodeID' unless nodeId?
    query = {
      ownerId,
      nodeId,
      id: {$exists:true}
      token: {$exists:true}
      data: {$exists:false}
    }
    debug 'mongo get credentials', {nodeId,ownerId}
    @collection.findOne query, { id: true, token: true }, (error, device) =>
      return callback error if error?
      debug 'mongo got credentials', device
      interval.id = device.id if device?.id?
      interval.token = device.token if device?.token?
      callback null, interval

module.exports = Intervals
