_ = require 'lodash'

class Intervals
  constructor: ({ database, @skip, @limit }) ->
    throw new Error 'Intervals: requires database' unless database?
    throw new Error 'Intervals: requires skip' unless @skip?
    throw new Error 'Intervals: requires limit' unless @limit?
    @collection = database.collection 'intervals'
    @totalProcessed = 0

  getBatch: (callback) =>
    return callback null, [] if @totalProcessed >= @limit
    limit = @limit if @limit < 10
    limit ?= 10
    query = {
      ownerId: 'b47887f8-e897-4d79-9b60-42b7c965591d',
      data: {$exists:true}
    }
    @collection
      .find(query)
      .sort({_id: -1})
      .limit(limit)
      .skip(@totalProcessed + @skip)
      .toArray (error, records) =>
        return callback error if error?
        @totalProcessed += _.size(records)
        callback null, records

  getCredentials: (interval, callback) =>
    { ownerId, id, token } = interval
    { nodeId } = interval.data ? {}
    return callback null, interval unless id? || token?
    return callback new Error 'Missing nodeID' unless nodeId?
    query = {
      ownerId,
      nodeId,
      id: {$exists:true}
      token: {$exists:true}
      data: {$exists:false}
    }
    @collection.findOne query, { id: true, token: true }, (error, device) =>
      return callback error if error?
      interval.id = device.id if device?.id?
      interval.token = device.token if device?.token?
      callback null, interval

module.exports = Intervals
