mongojs    = require 'mongojs'
{ObjectId} = require 'mongojs'
Soldiers   = require '../../src/models/soldiers'

describe 'Update Soldiers', ->
  before (done) ->
    @database = mongojs 'minute-man-worker-test', ['soldiers']
    @database.soldiers.drop =>
      @collection = @database.collection 'soldiers'
      done()

  beforeEach ->
    @sut = new Soldiers { @database, offsetSeconds: 60 }

  describe 'when a record exists', ->
    beforeEach (done) ->
      record = {
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

    describe 'when updated', ->
      describe 'when using a string for the id', ->
        beforeEach (done) ->
          options = { @recordId, nextProcessAt: 300, processAt: 200, timestamp: 100 }
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

        it 'should the lastRunAt of 100', ->
          expect(@record.metadata.lastRunAt).to.equal 100

        it 'should have processNow: false', ->
          expect(@record.metadata.processNow).to.be.false

      describe 'when using a ObjectId for the id', ->
        beforeEach (done) ->
          options = { recordId: new ObjectId(@recordId), nextProcessAt: 300, processAt: 200, timestamp: 100 }
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

        it 'should the lastRunAt of 100', ->
          expect(@record.metadata.lastRunAt).to.equal 100

        it 'should have processNow: false', ->
          expect(@record.metadata.processNow).to.be.false
