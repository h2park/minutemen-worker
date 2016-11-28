_            = require 'lodash'
moment       = require 'moment'
{ ObjectId } = require 'mongojs'

class Soldier
  constructor: ({ database }) ->
    throw new Error 'Soldier (TestHelper): requires database' unless database?
    @collection = database.collection 'soldiers'

  create: (metadata={}, callback) =>
    data =
      nonce: "nonce-#{_.random()}"
      uuid: "uuid-#{_.random()}"
      token: "token-#{_.random()}"
      sendTo: "send-to-#{_.random()}"
      nodeId: "node-id-#{_.random()}"
      transactionId: "transaction-id-#{_.random()}"
    record = { metadata, data }
    @collection.insert record, (error, record) =>
      return callback error if error?
      @recordId = record._id
      @get callback

  checkSameRecord: =>
    assert.deepEqual @record, @prevRecord, "expected record to not have changed"

  getRecordId: =>
    return @recordId.toString()

  getMetadata: =>
    return @record.metadata

  getPrevMetadata: =>
    return @prevRecord.metadata

  get: (callback) =>
    @prevRecord = _.cloneDeep @record
    @collection.findOne { _id: @recordId }, {_id: false}, (error, @record) =>
      return callback error if error?
      return callback new Error('Unable to find the record') unless @record?
      callback()

module.exports = Soldier
