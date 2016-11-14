_            = require 'lodash'
moment       = require 'moment'
{ObjectId}   = require 'mongojs'
debug        = require('debug')('minutemen-worker:soldiers')
overview     = require('debug')('minutemen-worker:soldiers:overview')

class Soldiers
  constructor: ({ database, @offsetSeconds }) ->
    throw new Error 'Soldiers: requires database' unless database?
    throw new Error 'Soldiers: requires database' unless database?
    throw new Error 'Soldiers: requires offsetSeconds' unless @offsetSeconds?
    throw new Error 'Soldiers: requires offsetSeconds to be an integer' unless _.isInteger(@offsetSeconds)
    @collection = database.collection 'soldiers'

  get: ({ timestamp }, callback) =>
    debug 'finding soldier', { timestamp }
    query = {
      $and: [
          { 'metadata.processing': { $ne: true } }
          { 'metadata.processAt': @_getTimeQuery({ timestamp }) }
          {
            $or: [
              {'metadata.intervalTime': {$exists: true}}
              {'metadata.cronString': {$exists: true}}
            ]
          }
      ]

    }
    update = { 'metadata.processing': true }
    sort = { 'metadata.processAt': -1 }
    debug 'get.query', JSON.stringify(query)
    @collection.findAndModify { query, update: { $set: update }, sort }, (error, record) =>
      return callback error if error?
      overview 'found record', record.metadata if record?
      debug 'no record found' unless record?
      callback null, record

  update: ({ recordId, nextProcessAt, processAt, timestamp }, callback) =>
    query  = { _id: new ObjectId(recordId) }
    update = {
      $set: {
        'metadata.processing': false
        'metadata.processAt': nextProcessAt
        'metadata.lastProcessAt': processAt
        'metadata.processNow': false
        'metadata.lastRunAt': timestamp
      }
    }
    overview 'updating solider', { query, update }
    @collection.update query, update, callback

  remove: ({ recordId }, callback) =>
    overview 'removing solider', { recordId }
    @collection.remove { _id: new ObjectId(recordId) }, callback

  _getTimeQuery: ({ timestamp }) =>
    max = moment.unix(timestamp).add(@offsetSeconds, 'seconds').unix()
    return {
      $lte: max
      #$gte: ( timestamp - 1) # it should never process things in the past
    }

module.exports = Soldiers
