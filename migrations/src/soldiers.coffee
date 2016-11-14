async  = require 'async'
moment = require 'moment'
debug = require('debug')('migrate:soldiers')

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
    # @exists interval, (error, exists) =>
    #   return callback error if error?
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
    remove = {}
    update['data.nodeId'] = nodeId
    update['data.sendTo'] = sendTo ? ownerId
    update['data.transactionId'] = transactionId if transactionId?
    update['data.fireOnce'] = fireOnce
    update['data.uuid'] = id if id?
    update['data.token'] = token if token?
    update['data.nodeId'] = nodeId
    update['metadata.nonce'] = nonce if nonce?
    if fireOnce
      remove['metadata.intervalTime'] = true
      remove['metadata.cronString'] = true
      remove['metadata.processAt'] = true
      remove['metadata.processNow'] = true
      remove['metadata.fireOnce'] = true
    else
      update['metadata.intervalTime'] = parseInt(intervalTime) if intervalTime?
      update['metadata.cronString'] = cronString if cronString?
      update['metadata.processAt'] = moment().unix()
      update['metadata.processNow'] = true
      update['metadata.fireOnce'] = false
    update['metadata.ownerUuid'] = ownerId
    update['metadata.intervalUuid'] = id if id?
    update['metadata.nodeId'] = nodeId
    query = @_getQuery({ sendTo, nodeId })
    debug 'update query', query
    @collection.update query, { $set: update, $unset: remove }, { upsert: true }, (error, result) =>
      return callback error if error?
      debug 'updated record', update
      debug 'updated result', result
      callback null

  _getQuery: ({ ownerId, nodeId }) =>
    return {
      'metadata.nodeId'   : nodeId
      'metadata.ownerUuid': ownerId
    }

module.exports = Soldiers
