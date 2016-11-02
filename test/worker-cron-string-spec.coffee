_       = require 'lodash'
Worker  = require '../src/worker'
Redis   = require 'ioredis'
RedisNS = require '@octoblu/redis-ns'
mongojs = require 'mongojs'
moment  = require 'moment'
uuid    = require 'uuid'
async   = require 'async'

describe 'Worker (CronString)', ->
  beforeEach (done) ->
    @queueName = "seconds-#{uuid.v1()}"
    client = new Redis 'localhost', dropBufferSupport: true
    client.on 'ready', =>
      @client = new RedisNS 'test-worker', client
      @client.del @queueName
      done()

  beforeEach (done) ->
    @database = mongojs 'minute-man-worker-test', ['intervals']
    @database.dropDatabase (error) =>
      console.error error if error?
      done()

  beforeEach ->
    @sut = new Worker { @database, @client, @queueName, timestamp: 1478041516 }

  afterEach (done) ->
    @sut.stop done

  describe '->do', ->
    describe 'when an cronString that runs once every 10 seconds and has no processAt', ->
      beforeEach (done) ->
        record =
          ownerId: 'the-owner-id'
          nodeId: 'the-node-id'
          data:
            nonce: uuid.v1()
            sendTo: 'the-owner-id'
            cronString: '* * * * * *'
            fireOnce: false
            nodeId: 'the-node-id'
        @database.intervals.insert record, (error, @record) =>
          done error

      beforeEach (done) ->
        @sut.do done

      it 'should create 6 in the seconds queue', (done) ->
        async.timesSeries 6, (n, next) =>
          secondWindow = 1478041576 + n
          @client.brpop "#{@queueName}:#{secondWindow}", 1, (error, result) =>
            return next error if error?
            console.log { secondWindow } unless result?
            expect(result).to.exist
            next()
          return # redis fix
        , done

      it 'should have the correct processAt time', (done) ->
        @database.intervals.findOne { _id: @record._id }, (error, updatedRecord) =>
          return done error if error?
          expect(updatedRecord.processAt).to.equal 1478041576 + 60
          expect(updatedRecord.processing).to.be.false
          done()

    describe 'when an cronString that runs every second exists', ->
      beforeEach (done) ->
        record =
          processAt: 1478041581
          ownerId: 'the-owner-id'
          nodeId: 'the-node-id'
          data:
            nonce: uuid.v1()
            sendTo: 'the-owner-id'
            cronString: '* * * * * *'
            fireOnce: false
            nodeId: 'the-node-id'
        @database.intervals.insert record, (error, @record) =>
          done error

      beforeEach (done) ->
        @sut.do done

      it 'should create 55 in the seconds queue', (done) ->
        async.timesSeries 55, (n, next) =>
          secondWindow = 1478041581 + n
          @client.brpop "#{@queueName}:#{secondWindow}", 1, (error, result) =>
            return next error if error?
            console.log { secondWindow } unless result?
            expect(result).to.exist
            next()
          return # redis fix
        , done

      it 'should have the correct processAt time', (done) ->
        @database.intervals.findOne { _id: @record._id }, (error, updatedRecord) =>
          return done error if error?
          expect(updatedRecord.processAt).to.equal 1478041576 + 60
          expect(updatedRecord.processing).to.be.false
          done()

    describe 'when an cronString that runs every 15 seconds exists', ->
      beforeEach (done) ->
        record =
          processAt: 1478041581
          ownerId: 'the-owner-id'
          nodeId: 'the-node-id'
          data:
            nonce: uuid.v1()
            sendTo: 'the-owner-id'
            cronString: '*/15 * * * * *'
            fireOnce: false
            nodeId: 'the-node-id'
        @database.intervals.insert record, (error, @record) =>
          done error

      beforeEach (done) ->
        @sut.do done

      it 'should create 4 in the seconds queue', (done) ->
        async.timesSeries 4, (n, next) =>
          secondWindow = 1478041590 + (n * 15)
          @client.brpop "#{@queueName}:#{secondWindow}", 1, (error, result) =>
            return next error if error?
            console.log { secondWindow } unless result?
            expect(result).to.exist
            next()
          return # redis fix
        , done

      it 'should have the correct processAt time', (done) ->
        @database.intervals.findOne { _id: @record._id }, (error, updatedRecord) =>
          return done error if error?
          expect(updatedRecord.processAt).to.equal 1478041650
          expect(updatedRecord.processing).to.be.false
          done()
