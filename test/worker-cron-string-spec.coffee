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

    describe 'when an cronString record exists for that minute', ->
      beforeEach (done) ->
        record =
          processAt: @currentTime.unix()
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
