_          = require 'lodash'
Redis      = require 'ioredis'
RedisNS    = require '@octoblu/redis-ns'
mongojs    = require 'mongojs'
moment     = require 'moment'
uuid       = require 'uuid'
async      = require 'async'
PaulRevere = require '../../src/controllers/paul-revere'

describe 'PaulRevere', ->
  beforeEach (done) ->
    @queueName = "seconds-#{uuid.v1()}"
    client = new Redis 'localhost', dropBufferSupport: true
    client.on 'ready', =>
      @client = new RedisNS 'test-worker', client
      @client.flushall done

  beforeEach (done) ->
    @database = mongojs 'minute-man-worker-test', ['soldiers']
    @database.dropDatabase (error) =>
      console.error error if error?
      done()

  beforeEach ->
    @sut = new PaulRevere { @database, @client, @queueName }

  describe '->findAndDeploySoldier', ->
    beforeEach (done) ->
      @sut.getTime (error, @timestamp) =>
        done error

    describe 'when the intervalTime is 1 second', ->
      beforeEach (done) ->
        record =
          metadata:
            intervalTime: 1000
            processAt: @timestamp
          data:
            nonce: uuid.v1()
            fireOnce: false
            uuid: 'the-uuid'
            token: 'the-token'
            sendTo: 'the-sendTo-uuid'
            nodeId: 'the-node-id'
            transactionId: 'the-transaction-id'
        @database.soldiers.insert record, (error, @record) =>
          done error

      beforeEach (done) ->
        @sut.findAndDeploySoldier @timestamp, done

      it 'should create one for each second in the seconds queue', (done) ->
        async.timesSeries 60, (n, next) =>
          secondWindow = @timestamp + n
          @client.brpop "#{@queueName}:#{secondWindow}", 1, (error, result) =>
            return next error if error?
            console.log 'part 1', {secondWindow, @timestamp} unless result?
            expect(result[1]).to.equal @record._id.toString()
            next()
          return # redis fix
        , done

      it 'should have the correct processAt time', (done) ->
        @database.soldiers.findOne { _id: @record._id }, (error, updatedRecord) =>
          return done error if error?
          expect(updatedRecord.metadata.processAt).to.equal @timestamp + 60
          expect(updatedRecord.metadata.lastProcessAt).to.equal @timestamp
          expect(updatedRecord.metadata.processing).to.be.false
          done()

      describe 'when it do is called again', ->
        beforeEach (done) ->
          @client.flushall done
          return # redis

        describe 'when it should be processed', ->
          beforeEach (done) ->
            @sut.findAndDeploySoldier (@timestamp + 60), done

          it 'should create one for each second in the seconds queue', (done) ->
            async.timesSeries 60, (n, next) =>
              secondWindow = (@timestamp + 60) + n
              @client.brpop "#{@queueName}:#{secondWindow}", 1, (error, result) =>
                return next error if error?
                console.log 'part 2', {secondWindow,@timestamp} unless result?
                expect(result[1]).to.equal @record._id.toString()
                next()
              return # redis fix
            , done

          it 'should have the correct processAt time', (done) ->
            @database.soldiers.findOne { _id: @record._id }, (error, updatedRecord) =>
              return done error if error?
              expect(updatedRecord.metadata.processAt).to.equal @timestamp + 60 + 60
              expect(updatedRecord.metadata.processing).to.be.false
              done()

        describe 'when it should not be processed', ->
          beforeEach (done) ->
            @sut.findAndDeploySoldier (@timestamp + 80), done

          it 'should not create one for each second in the seconds queue', (done) ->
            async.timesSeries 60, (n, next) =>
              secondWindow = (@timestamp + 80) + n
              @client.llen "#{@queueName}:#{secondWindow}", (error, count) =>
                return next error if error?
                expect(count).to.equal 0
                next()
              return # redis fix
            , done

          it 'should have the correct processAt time', (done) ->
            @database.soldiers.findOne { _id: @record._id }, (error, updatedRecord) =>
              return done error if error?
              expect(updatedRecord.metadata.processAt).to.equal @timestamp + 60
              expect(updatedRecord.metadata.lastProcessAt).to.equal @timestamp
              expect(updatedRecord.metadata.processing).to.be.false
              done()
