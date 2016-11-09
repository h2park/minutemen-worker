_            = require 'lodash'
{ ObjectId } = require 'mongojs'
debug        = require('debug')('minute-man-worker:soldiers')
overview     = require('debug')('minute-man-worker:soldiers:overview')

class Soldiers
  constructor: ({ database }) ->
    @collection = database.collection 'soldiers'

  get: ({ max, min }, callback) =>
    debug { max, min }
    query = {
      'metadata.processing': { $ne: true }
      'metadata.processAt': {
        $lte: max
      }
      # '$or': [
      #   { 'metadata.processNow': true }
      #   {
      #     'metadata.processAt': {
      #       $lte: max,
      #       $gte: min
      #     }
      #   }
      # ]
    }
    update = { 'metadata.processing': true }
    sort = { 'metadata.processAt': 1 }
    debug 'get.query', JSON.stringify(query)
    debug 'get.update', update
    debug 'get.sort', sort
    @collection.findAndModify { query, update: { $set: update }, sort }, (error, record) =>
      return callback error if error?
      debug 'found processAt', record?.metadata?.processAt
      overview 'found record' if record?
      debug 'no record found' unless record?
      callback null, record

  update: ({ recordId, nextProcessAt, processAt, timestamp }, callback) =>
    query  = { _id: recordId }
    update = {
      $set: {
        'metadata.processing': false
        'metadata.processAt': nextProcessAt
        'metadata.lastProcessAt': processAt
        'metadata.processNow': false
      }
      $addToSet: {
        'metadata.lastRunAt': {
          $each: [timestamp]
          $slice: 5
          $sort: 1
        }
      }
    }

    overview 'updating solider', { query, update }
    debug 'setting processAt', nextProcessAt
    @collection.update query, update, callback

  remove: ({ recordId }, callback) =>
    overview 'removing solider', { recordId }
    @collection.remove { _id: recordId }, callback

module.exports = Soldiers
