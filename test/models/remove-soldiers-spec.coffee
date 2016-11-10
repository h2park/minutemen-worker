mongojs    = require 'mongojs'
{ObjectId} = require 'mongojs'
Soldiers   = require '../../src/models/soldiers'

describe 'Remove Soldiers', ->
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

    describe 'when removed', ->
      describe 'when using a string for the id', ->
        beforeEach (done) ->
          @sut.remove { @recordId }, done

        beforeEach (done) ->
          @collection.findOne { _id: new ObjectId(@recordId) }, (error, @record) =>
            done error

        it 'should not find the record', ->
          expect(@record).to.not.exist

      describe 'when using a ObjectId for the id', ->
        beforeEach (done) ->
          @sut.remove { recordId: new ObjectId(@recordId) }, done

        beforeEach (done) ->
          @collection.findOne { _id: new ObjectId(@recordId) }, (error, @record) =>
            done error

        it 'should not find the record', ->
          expect(@record).to.not.exist
