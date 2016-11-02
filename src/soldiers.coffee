debug      = require('debug')('minute-man-worker:soldiers')

class Soldiers
  constructor: ({ database }) ->
    @collection = database.collection 'soldiers'

  get: ({ min, max }, callback) =>
    query = {
      processing: { $ne: true }
      $or: [
        {
          processAt: { $gte: min, $lt: max }
        }
        { processAt: $exists: false }
      ]
    }
    update = { $set: { processing: true } }
    sort = { processAt: 1 }
    debug 'get.query', JSON.stringify query, null, 2
    debug 'get.update', update
    debug 'get.sort', sort
    @collection.findAndModify { query, update, sort }, (error, record) =>
      return callback error if error?
      debug 'found record', record if record?
      debug 'no record found' unless record?
      callback null, record

  update: ({ _id, nextProcessAt }, callback) =>
    query  = { _id: _id }
    update = { processing: false, processAt: nextProcessAt }
    debug 'updating solider', { query, update }
    @collection.update query, { $set: update }, callback

  remove: ({ _id }, callback) =>
    debug 'removing solider', { _id }
    @collection.remove { _id: _id }, callback

module.exports = Soldiers
