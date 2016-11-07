_          = require 'lodash'
Redis      = require 'ioredis'
RedisNS    = require '@octoblu/redis-ns'
mongojs    = require 'mongojs'
moment     = require 'moment'
uuid       = require 'uuid'
async      = require 'async'
PaulRevere = require '../../src/controllers/paul-revere'

describe.only 'PaulRevere', ->
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
        @nextProcessAt = @timestamp + 120
        @sut.findAndDeploySoldier @timestamp, done

      it 'should create one for each second in the seconds queue', (done) ->
        async.timesSeries 60, (n, next) =>
          secondWindow = @timestamp + n
          @client.brpop "#{@queueName}:#{secondWindow}", 1, (error, result) =>
            return next error if error?
            console.log 'part 1', {secondWindow, @timestamp} unless result?
            {recordId} = JSON.parse result[1]
            expect(recordId).to.equal @record._id.toString()
            next()
          return # redis fix
        , done

      it 'should have the processAt incremented to the next window', (done) ->
        @database.soldiers.findOne { _id: @record._id }, (error, updatedRecord) =>
          return done error if error?
          expect(updatedRecord.metadata.processAt).to.equal @nextProcessAt
          expect(updatedRecord.metadata.lastProcessAt).to.equal @timestamp
          expect(updatedRecord.metadata.processing).to.be.false
          done()

      describe 'when it do is called again', ->
        beforeEach (done) ->
          @lastProcessAt = @nextProcessAt
          @client.flushall done
          return # redis

        describe 'when time is incremented by 60 seconds', ->
          beforeEach (done) ->
            @nextTimestamp = @timestamp + 60
            @nextProcessAt = @nextTimestamp + 120
            @sut.findAndDeploySoldier @nextTimestamp, done

          it 'should create one for each second in the seconds queue', (done) ->
            async.timesSeries 60, (n, next) =>
              secondWindow = @nextTimestamp + n
              @client.brpop "#{@queueName}:#{secondWindow}", 1, (error, result) =>
                return next error if error?
                console.log 'part 2', {secondWindow,@nextTimestamp} unless result?
                {recordId} = JSON.parse result[1]
                expect(recordId).to.equal @record._id.toString()
                next()
              return # redis fix
            , done

          it 'should have the new timestamps', (done) ->
            @database.soldiers.findOne { _id: @record._id }, (error, updatedRecord) =>
              return done error if error?
              expect(updatedRecord.metadata.processAt).to.equal @nextProcessAt
              expect(updatedRecord.metadata.lastProcessAt).to.equal @lastProcessAt
              expect(updatedRecord.metadata.processing).to.be.false
              done()

        describe 'when time is incremented by 1 second', ->
          beforeEach (done) ->
            @nextTimestamp = @timestamp + 1
            @sut.findAndDeploySoldier @nextTimestamp, (@error) =>
              done()

          it 'should have a 404 error', ->
            expect(@error.code).to.equal 404

          it 'should not create one for each second in the seconds queue', (done) ->
            async.timesSeries 60, (n, next) =>
              secondWindow = @nextTimestamp + n
              @client.llen "#{@queueName}:#{secondWindow}", (error, count) =>
                return next error if error?
                expect(count).to.equal 0
                next()
              return # redis fix
            , done

          it 'should remain untouched since the last process', (done) ->
            @database.soldiers.findOne { _id: @record._id }, (error, record) =>
              return done error if error?
              expect(record.metadata.processAt).to.equal @lastProcessAt
              expect(record.metadata.lastProcessAt).to.equal @timestamp
              expect(record.metadata.processing).to.be.false
              done()

        describe 'when time is incremented by 30 second', ->
          beforeEach (done) ->
            @nextTimestamp = @timestamp + 30
            @sut.findAndDeploySoldier @nextTimestamp, (@error) =>
              done()

          it 'should have a 404 error', ->
            expect(@error.code).to.equal 404

          it 'should not create one for each second in the seconds queue', (done) ->
            async.timesSeries 60, (n, next) =>
              secondWindow = @nextTimestamp + n
              @client.llen "#{@queueName}:#{secondWindow}", (error, count) =>
                return next error if error?
                expect(count).to.equal 0
                next()
              return # redis fix
            , done

          it 'should remain untouched since the last process', (done) ->
            @database.soldiers.findOne { _id: @record._id }, (error, record) =>
              return done error if error?
              expect(record.metadata.processAt).to.equal @lastProcessAt
              expect(record.metadata.lastProcessAt).to.equal @timestamp
              expect(record.metadata.processing).to.be.false
              done()
