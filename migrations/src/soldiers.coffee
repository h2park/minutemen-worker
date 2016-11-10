async  = require 'async'
moment = require 'moment'

INDEXES = [
  {
    index: { 'metadata.nodeId': 1, 'metadata.ownerUuid': 1 }
    name : 'interval-service-search'
  }
  {
    index: { 'metadata.processAt': 1, 'metadata.processing': -1 }
    name : 'minute-man-worker'
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
      return callback null if exists
      @upsert interval, callback

  exists: ({ ownerId, nodeId }, callback) =>
    query = @_getQuery { ownerId, nodeId }
    @collection.count query, (error, count) =>
      return callback error if error?
      return callback new Error 'More than one soldier exists for that query' if count > 1
      callback null, count == 1

  upsert: ({ ownerId, nodeId, data }, callback) =>
    {
      sendTo,
      intervalTime,
      fireOnce,
      nodeId,
      transactionId,
      nonce,
      cronString,
      uuid,
      token,
    } = data
    update = {}
    update['data.nodeId'] = nodeId
    update['data.sendTo'] = sendTo
    update['data.transactionId'] = transactionId if transactionId?
    update['data.fireOnce'] = fireOnce
    update['data.uuid'] = uuid if uuid?
    update['data.token'] = token if token?
    update['data.nodeId'] = nodeId
    update['metadata.nonce'] = nonce if nonce?
    update['metadata.intervalTime'] = intervalTime if intervalTime?
    update['metadata.cronString'] = cronString if cronString?
    update['metadata.processAt'] = moment().unix()
    update['metadata.processNow'] = true
    update['metadata.fireOnce'] = fireOnce
    update['metadata.ownerUuid'] = ownerId
    update['metadata.intervalUuid'] = uuid if uuid?
    update['metadata.nodeId'] = nodeId
    query = @_getQuery({ ownerId, nodeId })
    @collection.update query, { $set: update }, { upsert: true }, callback

  _getQuery: ({ ownerId, nodeId }) =>
    return {
      'metadata.nodeId'   : nodeId
      'metadata.ownerUuid': ownerId
    }

module.exports = Soldiers
