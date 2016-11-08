_            = require 'lodash'
moment       = require 'moment'
{ ObjectId } = require 'mongojs'
timeExpect   = require './time-expect'

class Soldier
  constructor: ({ database, @currentTimestamp }) ->
    @collection = database.collection 'soldiers'

  create: (metadata, callback) =>
    metadata.processAt = @currentTimestamp
    metadata.processNow = true
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

  checkUpdatedRecord: =>
    processAt = moment.unix(@record.metadata.processAt)
    lastProcessAt = moment.unix(@record.metadata.lastProcessAt)
    pervProcessAt = moment.unix(@prevRecord.metadata.processAt)
    timeExpect.shouldBeGreaterThan 'processAt', processAt, processAt.add(2, 'minute')
    timeExpect.shouldEqual 'lastProcessAt', lastProcessAt, pervProcessAt
    if @record.metadata.processing
      assert.fail @record.metadata.processing, false, "processing should be set to false"

  checkSameRecord: =>
    return if _.isEqual @record, @prevRecord
    assert.fail @record, @pervRecord, "expected record not to update"

  getRecordId: =>
    return @recordId.toString()

  get: (callback) =>
    @prevRecord = _.cloneDeep @record
    @collection.findOne { _id: @recordId }, {_id: false}, (error, @record) =>
      return callback error if error?
      return callback new Error('Unable to find the record') unless @record?
      callback()

module.exports = Soldier
