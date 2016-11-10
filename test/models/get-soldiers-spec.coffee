mongojs    = require 'mongojs'
{ObjectId} = require 'mongojs'
Soldiers   = require '../../src/models/soldiers'

describe 'Get Soldiers', ->
  before (done) ->
    @database = mongojs 'minutemen-worker-test', ['soldiers']
    @database.soldiers.drop =>
      @collection = @database.collection 'soldiers'
      done()

  beforeEach ->
    @sut = new Soldiers { @database, offsetSeconds: 60 }

  before 'insert records that should not be processed', (done) ->
    records = [
      { metadata: { processing: false, processAt: 1478724782 + 100 }}
      { metadata: { processing: false, processAt: 1478724782 + 300 }}
      { metadata: { processing: true, processAt: 1478724782 + 10 }}
      { metadata: { processing: true, processAt: 1478724782 + 10 }}
    ]
    @collection.insert records, done

  describe 'when a record exists and the processAt is within the next minute', ->
    describe 'when it is set to not processing', ->
      beforeEach (done) ->
        record =
          metadata:
            processing: false
            processAt: 1478724782 + 8
        @collection.insert record, (error, record) =>
          @recordId = record?._id.toString()
          done error

      beforeEach (done) ->
        @sut.get { timestamp: 1478724782 }, (error, @record) =>
          done error

      it 'should find the record', ->
        expect(@record._id.toString()).to.equal @recordId

      describe 'when the record is checked again', ->
        beforeEach (done) ->
          @collection.findOne { _id: new ObjectId(@recordId) }, (error, @updatedRecord) =>
            done error

        it 'should it to processing', ->
          expect(@updatedRecord.metadata.processing).to.be.true

    describe 'when it is set to processing', ->
      beforeEach (done) ->
        record =
          metadata:
            processing: true
            processAt: 1478724782 + 8
        @collection.insert record, (error, record) =>
          @recordId = record?._id.toString()
          done error

      beforeEach (done) ->
        @sut.get { timestamp: 1478724782 }, (error, @record) =>
          done error

      it 'should find the record', ->
        expect(@record).to.not.exist

      describe 'when the record is checked again', ->
        beforeEach (done) ->
          @collection.findOne { _id: new ObjectId(@recordId) }, (error, @updatedRecord) =>
            done error

        it 'should it to processing', ->
          expect(@updatedRecord.metadata.processing).to.be.true

  describe 'when a record exists and the processAt is 1 seconds before the current time', ->
    beforeEach (done) ->
      record =
        metadata:
          processing: false
          processAt: 1478724782 - 1
      @collection.insert record, (error, record) =>
        @recordId = record?._id.toString()
        done error

    beforeEach (done) ->
      @sut.get { timestamp: 1478724782 }, (error, @record) =>
        done error

    it 'should find still the record', ->
      expect(@record._id.toString()).to.equal @recordId

    describe 'when the record is checked again', ->
      beforeEach (done) ->
        @collection.findOne { _id: new ObjectId(@recordId) }, (error, @updatedRecord) =>
          done error

      it 'should it to processing', ->
        expect(@updatedRecord.metadata.processing).to.be.true

  describe 'when a record exists and the processAt is 80 seconds before the current time', ->
    beforeEach (done) ->
      record =
        metadata:
          processing: false
          processAt: 1478724782 - 80
      @collection.insert record, (error, record) =>
        @recordId = record?._id.toString()
        done error

    beforeEach (done) ->
      @sut.get { timestamp: 1478724782 }, (error, @record) =>
        done error

    it 'should find still the record', ->
      expect(@record._id.toString()).to.equal @recordId

    describe 'when the record is checked again', ->
      beforeEach (done) ->
        @collection.findOne { _id: new ObjectId(@recordId) }, (error, @updatedRecord) =>
          done error

      it 'should it to processing', ->
        expect(@updatedRecord.metadata.processing).to.be.true

  describe 'when a record exists and the processAt is 61 seconds to after the current time', ->
    beforeEach (done) ->
      record =
        metadata:
          processing: false
          processAt: 1478724780 + 61
      @collection.insert record, (error, record) =>
        @recordId = record?._id.toString()
        done error

    beforeEach (done) ->
      @sut.get { timestamp: 1478724780 }, (error, @record) =>
        done error

    it 'should not find the record', ->
      expect(@record).to.not.exist

    describe 'when the record is checked again', ->
      beforeEach (done) ->
        @collection.findOne { _id: new ObjectId(@recordId) }, (error, @updatedRecord) =>
          done error

      it 'should not be set to processing', ->
        expect(@updatedRecord.metadata.processing).to.be.false

  describe 'when a record exists and the processAt is 60 seconds to after the current time', ->
    beforeEach (done) ->
      record =
        metadata:
          processing: false
          processAt: 1478724780 + 60
      @collection.insert record, (error, record) =>
        @recordId = record?._id.toString()
        done error

    beforeEach (done) ->
      @sut.get { timestamp: 1478724780 }, (error, @record) =>
        done error

    it 'should find still the record', ->
      expect(@record._id.toString()).to.equal @recordId

    describe 'when the record is checked again', ->
      beforeEach (done) ->
        @collection.findOne { _id: new ObjectId(@recordId) }, (error, @updatedRecord) =>
          done error

      it 'should be set to processing', ->
        expect(@updatedRecord.metadata.processing).to.be.true
