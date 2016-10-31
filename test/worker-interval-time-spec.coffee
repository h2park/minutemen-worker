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
      @client.del @timestampRedisKey
      @client.del @queueName
      done()

  beforeEach ->
    @database = mongojs 'minute-man-worker-test', ['intervals']
    @database.intervals.drop()

  beforeEach ->
    @sut = new Worker { @database, @client, @queueName }

  afterEach (done) ->
    @sut.stop done

  describe '->do', ->
    beforeEach (done) ->
      @client.time (error, result) =>
        return done error if error?
        [ timestamp ] = result
        @currentTime = moment(timestamp * 1000)
        done()
      return # redis promise fix

    describe 'when an interval record exists for every second in a minute', ->
      beforeEach (done) ->
        record =
          processAt: @currentTime.unix()
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
        currentTime = @currentTime
        async.timesSeries 60, (n, next) =>
          secondWindow = currentTime.unix()
          @client.brpop "#{@queueName}:#{secondWindow}", 1, (error, result) =>
            return next error if error?
            expect(result).to.exist
            currentTime.add(1, 'seconds')
            next()
          return # redis fix
        , done

    describe 'when an interval record exists for that minute', ->
      beforeEach (done) ->
        record =
          processAt: @currentTime.unix()
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

      it 'should create a m+10s in the seconds queue', (done) ->
        secondWindow = @currentTime.add(10, 'seconds').unix()
        @client.brpop "#{@queueName}:#{secondWindow}", 1, (error, result) =>
          return done error if error?
          expect(result).to.exist
          done()
        return # redis fix

      it 'should create a m+20s in the seconds queue', (done) ->
        secondWindow = @currentTime.add(20, 'seconds').unix()
        @client.brpop "#{@queueName}:#{secondWindow}", 1, (error, result) =>
          return done error if error?
          expect(result).to.exist
          done()
        return # redis fix

      it 'should create a m+30s in the seconds queue', (done) ->
        secondWindow = @currentTime.add(30, 'seconds').unix()
        @client.brpop "#{@queueName}:#{secondWindow}", 1, (error, result) =>
          return done error if error?
          expect(result).to.exist
          done()
        return # redis fix

      it 'should create a m+40s in the seconds queue', (done) ->
        secondWindow = @currentTime.add(40, 'seconds').unix()
        @client.brpop "#{@queueName}:#{secondWindow}", 1, (error, result) =>
          return done error if error?
          expect(result).to.exist
          done()
        return # redis fix

      it 'should create a m+50s in the seconds queue', (done) ->
        secondWindow = @currentTime.add(50, 'seconds').unix()
        @client.brpop "#{@queueName}:#{secondWindow}", 1, (error, result) =>
          return done error if error?
          expect(result).to.exist
          done()
        return # redis fix

      it 'should have the correct processAt time', (done) ->
        @database.intervals.findOne { _id: @record._id }, (error, updatedRecord) =>
          return done error if error?
          expect(updatedRecord.processAt).to.equal @currentTime.add(1, 'minute').unix()
          expect(updatedRecord.processing).to.be.false
          done()

    describe 'when an interval record with a crazy intervalTime', ->
      beforeEach (done) ->
        record =
          processAt: @currentTime.unix()
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

      it 'should create a m+1s in the seconds queue', (done) ->
        secondWindow = @currentTime.add(1, 'seconds').unix()
        @client.brpop "#{@queueName}:#{secondWindow}", 1, (error, result) =>
          return done error if error?
          expect(result).to.exist
          done()
        return # redis fix

      it 'should create a m+2s in the seconds queue', (done) ->
        secondWindow = @currentTime.add(2, 'seconds').unix()
        @client.brpop "#{@queueName}:#{secondWindow}", 1, (error, result) =>
          return done error if error?
          expect(result).to.exist
          done()
        return # redis fix

      it 'should have the correct processAt time', (done) ->
        @database.intervals.findOne { _id: @record._id }, (error, updatedRecord) =>
          return done error if error?
          expect(updatedRecord.processAt).to.equal @currentTime.add(1, 'minute').unix()
          expect(updatedRecord.processing).to.be.false
          done()

    describe 'when an interval record with a over-a-minute intervalTime', ->
      beforeEach (done) ->
        record =
          processAt: @currentTime.unix()
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

      it 'should create a m+0s in the seconds queue', (done) ->
        secondWindow = @currentTime.unix()
        @client.brpop "#{@queueName}:#{secondWindow}", 1, (error, result) =>
          return done error if error?
          expect(result).to.exist
          done()
        return # redis fix

      it 'should have the correct processAt time', (done) ->
        @database.intervals.findOne { _id: @record._id }, (error, updatedRecord) =>
          return done error if error?
          expect(updatedRecord.processAt).to.equal @currentTime.add(2, 'minute').unix()
          expect(updatedRecord.processing).to.be.false
          done()
