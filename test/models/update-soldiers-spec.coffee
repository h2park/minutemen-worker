mongojs    = require 'mongojs'
{ObjectId} = require 'mongojs'
Soldiers   = require '../../src/models/soldiers'

describe 'Update Soldiers', ->
  before (done) ->
    @database = mongojs 'minutemen-worker-test', ['soldiers']
    @database.soldiers.drop =>
      @collection = @database.collection 'soldiers'
      done()

  beforeEach ->
    @sut = new Soldiers { @database, offsetSeconds: 60 }

  describe 'when a record exists', ->
    beforeEach (done) ->
      record = {
        uuid: 'some-uuid'
        metadata: {
          processAt: 'old'
          lastProcessAt: 'old'
          lastRunAt: 'old'
        }
      }
      @collection.insert record, (error, record) =>
        return done error if error?
        @recordId = record?._id.toString()
        done()

    describe 'when using a string for the id', ->
      beforeEach (done) ->
        options = {
          @recordId,
          nextProcessAt: 300,
          processAt: 200,
          timestamp: 100,
          lastRunAt: 120
        }
        @sut.update options, done

      beforeEach (done) ->
        @collection.findOne { _id: new ObjectId(@recordId) }, (error, @record) =>
          done error

      it 'should find the record', ->
        expect(@record).to.exist

      it 'should have processing: false', ->
        expect(@record.metadata.processing).to.be.false

      it 'should have processAt: 300', ->
        expect(@record.metadata.processAt).to.equal 300

      it 'should have lastProcessAt: 200', ->
        expect(@record.metadata.lastProcessAt).to.equal 200

      it 'should the lastRunAt of 120', ->
        expect(@record.metadata.lastRunAt).to.equal 120

      it 'should have processNow: false', ->
        expect(@record.metadata.processNow).to.be.false

    describe 'when using the uuid', ->
      beforeEach (done) ->
        options = {
          uuid: 'some-uuid',
          nextProcessAt: 300,
          processAt: 200,
          timestamp: 100,
          lastRunAt: 120
        }
        @sut.update options, done

      beforeEach (done) ->
        @collection.findOne { uuid: 'some-uuid' }, (error, @record) =>
          done error

      it 'should find the record', ->
        expect(@record).to.exist

      it 'should have processing: false', ->
        expect(@record.metadata.processing).to.be.false

      it 'should have processAt: 300', ->
        expect(@record.metadata.processAt).to.equal 300

      it 'should have lastProcessAt: 200', ->
        expect(@record.metadata.lastProcessAt).to.equal 200

      it 'should the lastRunAt of 120', ->
        expect(@record.metadata.lastRunAt).to.equal 120

      it 'should have processNow: false', ->
        expect(@record.metadata.processNow).to.be.false

    describe 'when using the uuid and recordId', ->
      beforeEach (done) ->
        options = {
          uuid: 'some-uuid',
          recordId: 'some-crazy-id-that-will-not-work'
          nextProcessAt: 300,
          processAt: 200,
          timestamp: 100,
          lastRunAt: 120
        }
        @sut.update options, done

      beforeEach (done) ->
        @collection.findOne { uuid: 'some-uuid' }, (error, @record) =>
          done error

      it 'should find the record', ->
        expect(@record).to.exist

      it 'should have processing: false', ->
        expect(@record.metadata.processing).to.be.false

      it 'should have processAt: 300', ->
        expect(@record.metadata.processAt).to.equal 300

      it 'should have lastProcessAt: 200', ->
        expect(@record.metadata.lastProcessAt).to.equal 200

      it 'should the lastRunAt of 120', ->
        expect(@record.metadata.lastRunAt).to.equal 120

      it 'should have processNow: false', ->
        expect(@record.metadata.processNow).to.be.false

    describe 'when using a ObjectId for the id', ->
      beforeEach (done) ->
        options = {
          recordId: new ObjectId(@recordId),
          nextProcessAt: 300,
          processAt: 200,
          timestamp: 100,
          lastRunAt: 120
        }
        @sut.update options, done

      beforeEach (done) ->
        @collection.findOne { _id: new ObjectId(@recordId) }, (error, @record) =>
          done error

      it 'should find the record', ->
        expect(@record).to.exist

      it 'should have processing: false', ->
        expect(@record.metadata.processing).to.be.false

      it 'should have processAt: 300', ->
        expect(@record.metadata.processAt).to.equal 300

      it 'should have lastProcessAt: 200', ->
        expect(@record.metadata.lastProcessAt).to.equal 200

      it 'should the lastRunAt of 120', ->
        expect(@record.metadata.lastRunAt).to.equal 120

      it 'should have processNow: false', ->
        expect(@record.metadata.processNow).to.be.false

    describe 'when no lastRunAt is passed', ->
      beforeEach (done) ->
        options = {
          recordId: new ObjectId(@recordId),
          nextProcessAt: 300,
          processAt: 200,
          timestamp: 100
        }
        @sut.update options, done

      beforeEach (done) ->
        @collection.findOne { _id: new ObjectId(@recordId) }, (error, @record) =>
          done error

      it 'should find the record', ->
        expect(@record).to.exist

      it 'should have processing: false', ->
        expect(@record.metadata.processing).to.be.false

      it 'should have processAt: 300', ->
        expect(@record.metadata.processAt).to.equal 300

      it 'should have lastProcessAt: 200', ->
        expect(@record.metadata.lastProcessAt).to.equal 200

      it 'should the lastRunAt of "old"', ->
        expect(@record.metadata.lastRunAt).to.equal 'old'

      it 'should have processNow: false', ->
        expect(@record.metadata.processNow).to.be.false
