_       = require 'lodash'
Worker  = require '../src/worker'
Redis   = require 'ioredis'
RedisNS = require '@octoblu/redis-ns'
mongojs = require 'mongojs'
moment  = require 'moment'
uuid    = require 'uuid'

describe 'Worker (Interval)', ->
  beforeEach (done) ->
    @timestampRedisKey = 'mm-timestamp'
    client = new Redis 'localhost', dropBufferSupport: true
    client.on 'ready', =>
      @client = new RedisNS 'test-worker', client
      @client.del @timestampRedisKey
      done()

  beforeEach ->
    @database = mongojs 'minute-man-worker-test', ['intervals']
    @database.intervals.drop()

  beforeEach ->
    @queueName = 'seconds'
    @currentTime = moment()
    @sut = new Worker { @database, @client, @queueName, @timestampRedisKey }

  afterEach (done) ->
    @sut.stop done

  describe '->do', ->
    describe 'when the timestamp does not exist', ->
      beforeEach (done) ->
        @sut.do (@error) =>
          done()

      it 'should have the error', ->
        expect(@error.message).to.equal 'Missing timestamp in redis'

    describe 'when the timestamp exists', ->
      beforeEach (done) ->
        @client.set @timestampRedisKey, @currentTime.unix(), done
        return # redis fix

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
          @database.intervals.insert record, done

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
          @database.intervals.insert record, done

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
          @database.intervals.insert record, done

        beforeEach (done) ->
          @sut.do done

        it 'should create a m+0s in the seconds queue', (done) ->
          secondWindow = @currentTime.unix()
          @client.brpop "#{@queueName}:#{secondWindow}", 1, (error, result) =>
            return done error if error?
            expect(result).to.exist
            done()
          return # redis fix
