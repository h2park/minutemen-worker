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
      @client.del @queueName
      done()

  beforeEach (done) ->
    @database = mongojs 'minute-man-worker-test', ['intervals']
    @database.dropDatabase (error) =>
      console.error error if error?
      done()

  beforeEach ->
    @timestamp = moment().unix()
    @currentTime = moment(_.parseInt(@timestamp) * 1000).add(1, 'minute')
    @baseTime = moment(@currentTime).seconds(0)
    @sut = new Worker { @database, @client, @queueName, @timestamp }

  afterEach (done) ->
    @sut.stop done

  describe '->do', ->
    describe 'when an cronString that runs every second exists', ->
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
        async.timesSeries 60, (n, next) =>
          secondWindow = @baseTime.unix()
          @client.brpop "#{@queueName}:#{secondWindow}", 1, (error, result) =>
            return next error if error?
            console.log secondWindow
            expect(result).to.exist
            @baseTime.add(1, 'seconds')
            next()
          return # redis fix
        , done

    describe 'when an cronString that runs every 15 seconds exists', ->
      beforeEach (done) ->
        record =
          processAt: @currentTime.unix()
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

      it 'should create one item for every 15 seconds', (done) ->
        async.timesSeries 4, (n, next) =>
          secondWindow = @baseTime.unix()
          @client.brpop "#{@queueName}:#{secondWindow}", 1, (error, result) =>
            return next error if error?
            console.log secondWindow
            expect(result).to.exist
            @baseTime.add(15, 'seconds')
            next()
          return # redis fix
        , done
