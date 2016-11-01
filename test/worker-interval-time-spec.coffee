_       = require 'lodash'
Worker  = require '../src/worker'
Redis   = require 'ioredis'
RedisNS = require '@octoblu/redis-ns'
mongojs = require 'mongojs'
moment  = require 'moment'
uuid    = require 'uuid'
async   = require 'async'

describe 'Worker (Interval)', ->
  beforeEach (done) ->
    @queueName = 'seconds'
    client = new Redis 'localhost', dropBufferSupport: true
    client.on 'ready', =>
      @client = new RedisNS 'test-worker', client
      @client.del @queueNme
      done()

  beforeEach (done) ->
    @database = mongojs 'minute-man-worker-test', ['intervals']
    @database.dropDatabase (error) =>
      console.error error if error?
      done()

  beforeEach ->
    @currentTime = moment()
    @sut = new Worker { @database, @client, @queueName, timestamp: 1478035080 }

  afterEach (done) ->
    @sut.stop done

  describe '->do', ->
    describe 'when the intervalTime is 1 second', ->
      beforeEach (done) ->
        record =
          processAt: 1478035140
          ownerId: 'the-owner-id'
          nodeId: 'the-node-id'
          data:
            nonce: uuid.v1()
            sendTo: 'the-owner-id'
            intervalTime: 1000
            fireOnce: false
            nodeId: 'the-node-id'
        @database.intervals.insert record, (error, @record) =>
          done error

      beforeEach (done) ->
        @sut.do done

      it 'should create one for each second in the seconds queue', (done) ->
        async.timesSeries 60, (n, next) =>
          secondWindow = 1478035140 + n
          @client.brpop "#{@queueName}:#{secondWindow}", 1, (error, result) =>
            return next error if error?
            expect(result).to.exist
            next()
          return # redis fix
        , done

      it 'should have the correct processAt time', (done) ->
        @database.intervals.findOne { _id: @record._id }, (error, updatedRecord) =>
          return done error if error?
          expect(updatedRecord.processAt).to.equal 1478035140 + 60
          expect(updatedRecord.processing).to.be.false
          done()

    describe 'when the intervalTime is 10 seconds', ->
      beforeEach (done) ->
        record =
          processAt: 1478035140
          ownerId: 'the-owner-id'
          nodeId: 'the-node-id'
          data:
            nonce: uuid.v1()
            sendTo: 'the-owner-id'
            intervalTime: 10000
            fireOnce: false
            nodeId: 'the-node-id'
        @database.intervals.insert record, (error, @record) =>
          done error

      beforeEach (done) ->
        @sut.do done

      it 'should create one for each second in the seconds queue', (done) ->
        async.timesSeries 6, (n, next) =>
          secondWindow = 1478035140 + (n * 10)
          @client.brpop "#{@queueName}:#{secondWindow}", 1, (error, result) =>
            return next error if error?
            expect(result).to.exist
            next()
          return # redis fix
        , done

      it 'should have the correct processAt time', (done) ->
        @database.intervals.findOne { _id: @record._id }, (error, updatedRecord) =>
          return done error if error?
          expect(updatedRecord.processAt).to.equal 1478035140 + 60
          expect(updatedRecord.processing).to.be.false
          done()

    describe 'when the intervalTime is 1250 ms', ->
      beforeEach (done) ->
        record =
          processAt: 1478035140
          ownerId: 'the-owner-id'
          nodeId: 'the-node-id'
          data:
            nonce: uuid.v1()
            sendTo: 'the-owner-id'
            intervalTime: 1250
            fireOnce: false
            nodeId: 'the-node-id'
        @database.intervals.insert record, (error, @record) =>
          done error

      beforeEach (done) ->
        @sut.do done

      it 'should create one for each second in the seconds queue', (done) ->
        async.timesSeries 60, (n, next) =>
          secondWindow = 1478035140 + n
          @client.brpop "#{@queueName}:#{secondWindow}", 1, (error, result) =>
            return next error if error?
            expect(result).to.exist
            next()
          return # redis fix
        , done

      it 'should have the correct processAt time', (done) ->
        @database.intervals.findOne { _id: @record._id }, (error, updatedRecord) =>
          return done error if error?
          expect(updatedRecord.processAt).to.equal 1478035140 + 60
          expect(updatedRecord.processing).to.be.false
          done()

    describe 'when the intervalTime is 2 minutes', ->
      beforeEach (done) ->
        record =
          processAt: 1478035140
          ownerId: 'the-owner-id'
          nodeId: 'the-node-id'
          data:
            nonce: uuid.v1()
            sendTo: 'the-owner-id'
            intervalTime: 60 * 1000 * 2
            fireOnce: false
            nodeId: 'the-node-id'
        @database.intervals.insert record, (error, @record) =>
          done error

      beforeEach (done) ->
        @sut.do done

      it 'should create one for each second in the seconds queue', (done) ->
        secondWindow = 1478035140
        @client.brpop "#{@queueName}:#{secondWindow}", 1, (error, result) =>
          return done error if error?
          expect(result).to.exist
          done()
        return # redis fix

      it 'should have the correct processAt time', (done) ->
        @database.intervals.findOne { _id: @record._id }, (error, updatedRecord) =>
          return done error if error?
          expect(updatedRecord.processAt).to.equal 1478035140 + (60 * 2)
          expect(updatedRecord.processing).to.be.false
          done()
