async  = require 'async'
moment = require 'moment'

INDEXES = [
  {
    index: { 'metadata.nodeId': 1, 'metadata.ownerUuid': 1 }
    name : 'interval-service-search'
  }
  {
    index: { 'metadata.processAt': 1, 'metadata.processing': -1 }
    name : 'minutemen-worker'
  }
]

class Soldiers
  constructor: ({ database }) ->
    throw new Error 'Soldiers: requires database' unless database?
    @collection = database.collection 'soldiers'

  ensureIndexes: (callback) =>
    async.eachSeries INDEXES, @ensureIndex, callback

  ensureIndex: ({ index, name }, callback) =>
    @collection.createIndex index, {background:true, name}, callback

  createFromInterval: (interval, callback) =>
    @exists interval, (error, exists) =>
      return callback error if error?
      @upsert interval, callback

  exists: ({ ownerId, nodeId }, callback) =>
    query = @_getQuery { ownerId, nodeId }
    @collection.count query, (error, count) =>
      return callback error if error?
      return callback new Error 'More than one soldier exists for that query' if count > 1
      callback null, count == 1

  upsert: ({ id, token, ownerId, data }, callback) =>
    {
      intervalTime,
      fireOnce,
      nonce,
      cronString,
      transactionId,
      nodeId,
      sendTo,
    } = data ? {}
    update = {}
    update['data.nodeId'] = nodeId
    update['data.sendTo'] = sendTo ? ownerId
    update['data.transactionId'] = transactionId if transactionId?
    update['data.fireOnce'] = fireOnce
    update['data.uuid'] = id if id?
    update['data.token'] = token if token?
    update['data.nodeId'] = nodeId
    update['metadata.nonce'] = nonce if nonce?
    update['metadata.intervalTime'] = parseInt(intervalTime) if intervalTime?
    update['metadata.cronString'] = cronString if cronString?
    update['metadata.processAt'] = moment().unix() unless fireOnce
    update['metadata.processNow'] = true unless fireOnce
    update['metadata.fireOnce'] = fireOnce
    update['metadata.ownerUuid'] = ownerId
    update['metadata.intervalUuid'] = id if id?
    update['metadata.nodeId'] = nodeId
    query = @_getQuery({ sendTo, nodeId })
    console.log 'update query', query
    @collection.update query, { $set: update }, { upsert: true }, (error, result) =>
      return callback error if error?
      console.log 'updated record', update
      console.log 'updated result', result
      callback null

  _getQuery: ({ sendTo, nodeId }) =>
    return {
      'metadata.nodeId'   : nodeId
      'metadata.ownerUuid': sendTo
    }

module.exports = Soldiers
