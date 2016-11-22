_            = require 'lodash'
moment       = require 'moment'
{ ObjectId } = require 'mongojs'
timeExpect   = require './time-expect'

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

  checkUpdatedRecord: ({ currentTimestamp }) =>
    throw new Error 'Soldier.checkUpdatedRecord (TestHelper): requires currentTimestamp' unless currentTimestamp?
    processAt     = moment.unix(@record.metadata.processAt)
    lastProcessAt = moment.unix(@record.metadata.lastProcessAt)
    pervProcessAt = moment.unix(@prevRecord.metadata.processAt)
    timeExpect.shouldBeAtLeast 'processAt', processAt, processAt.add(2, 'minute')
    timeExpect.shouldEqual 'lastProcessAt', lastProcessAt, pervProcessAt
    # timeExpect.shouldEqual 'lastRunAt', moment.unix(@record.metadata.lastRunAt), moment.unix(currentTimestamp)
    assert.isFalse @record.metadata.processing, "processing should be set to false"
    assert.isFalse @record.metadata.processNow, "processNow should be set to false"

  checkSameRecord: =>
    assert.deepEqual @record, @prevRecord, "expected record to not have changed"

  getRecordId: =>
    return @recordId.toString()

  get: (callback) =>
    @prevRecord = _.cloneDeep @record
    @collection.findOne { _id: @recordId }, {_id: false}, (error, @record) =>
      return callback error if error?
      return callback new Error('Unable to find the record') unless @record?
      callback()

module.exports = Soldier
