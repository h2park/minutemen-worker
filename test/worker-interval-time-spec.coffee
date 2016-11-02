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
    @queueName = "seconds-#{uuid.v1()}"
    client = new Redis 'localhost', dropBufferSupport: true
    client.on 'ready', =>
      @client = new RedisNS 'test-worker', client
      @client.del @queueName
      done()

  beforeEach (done) ->
    @database = mongojs 'minute-man-worker-test', ['soldiers']
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
          metadata:
            intervalTime: 1000
            fireOnce: false
            processAt: 1478035140
          data:
            nonce: uuid.v1()
            uuid: 'the-uuid'
            token: 'the-token'
            sendTo: 'the-sendTo-uuid'
            nodeId: 'the-node-id'
            transactionId: 'the-transaction-id'
        @database.soldiers.insert record, (error, @record) =>
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
        @database.soldiers.findOne { _id: @record._id }, (error, updatedRecord) =>
          return done error if error?
          expect(updatedRecord.metadata.processAt).to.equal 1478035140 + 60
          expect(updatedRecord.metadata.processing).to.be.false
          done()

    describe 'when the intervalTime is 10 seconds', ->
      beforeEach (done) ->
        record =
          metadata:
            processAt: 1478035140
            intervalTime: 10000
            fireOnce: false
          data:
            nonce: uuid.v1()
            uuid: 'the-uuid'
            token: 'the-token'
            sendTo: 'the-sendTo-uuid'
            nodeId: 'the-node-id'
            transactionId: 'the-transaction-id'
        @database.soldiers.insert record, (error, @record) =>
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
        @database.soldiers.findOne { _id: @record._id }, (error, updatedRecord) =>
          return done error if error?
          expect(updatedRecord.metadata.processAt).to.equal 1478035140 + 60
          expect(updatedRecord.metadata.processing).to.be.false
          done()

    describe 'when the intervalTime is 10 seconds and there is no processAt', ->
      beforeEach (done) ->
        record =
          metadata:
            intervalTime: 10000
            fireOnce: false
          data:
            nonce: uuid.v1()
            uuid: 'the-uuid'
            token: 'the-token'
            sendTo: 'the-sendTo-uuid'
            nodeId: 'the-node-id'
            transactionId: 'the-transaction-id'
        @database.soldiers.insert record, (error, @record) =>
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
        @database.soldiers.findOne { _id: @record._id }, (error, updatedRecord) =>
          return done error if error?
          expect(updatedRecord.metadata.processAt).to.equal 1478035140 + 60
          expect(updatedRecord.metadata.processing).to.be.false
          done()

    describe 'when the intervalTime is 10 seconds and it should only be fired once', ->
      beforeEach (done) ->
        record =
          metadata:
            processAt: 1478035140
            intervalTime: 10000
            fireOnce: true
          data:
            nonce: uuid.v1()
            uuid: 'the-uuid'
            token: 'the-token'
            sendTo: 'the-sendTo-uuid'
            nodeId: 'the-node-id'
            transactionId: 'the-transaction-id'
        @database.soldiers.insert record, (error, @record) =>
          done error

      beforeEach (done) ->
        @sut.do done

      it 'should create one second in the seconds queue', (done) ->
        secondWindow = 1478035140
        @client.brpop "#{@queueName}:#{secondWindow}", 1, (error, result) =>
          return done error if error?
          expect(result).to.exist
          done()
        return # redis fix

      it 'should not create the next one', (done) ->
        secondWindow = 1478035140 + 10
        @client.llen "#{@queueName}:#{secondWindow}", (error, count) =>
          return done error if error?
          expect(count).to.equal 0
          done()
        return # redis fix

      it 'should have the correct processAt time', (done) ->
        @database.soldiers.findOne { _id: @record._id }, (error, updatedRecord) =>
          return done error if error?
          expect(updatedRecord).to.not.exist
          done()

    describe 'when the intervalTime is 30 seconds and it is set to processing', ->
      beforeEach (done) ->
        record =
          metadata:
            processAt: 1478035140
            intervalTime: 30 * 1000
            fireOnce: false
            processing: true
          data:
            nonce: uuid.v1()
            uuid: 'the-uuid'
            token: 'the-token'
            sendTo: 'the-sendTo-uuid'
            nodeId: 'the-node-id'
            transactionId: 'the-transaction-id'
        @database.soldiers.insert record, (error, @record) =>
          done error

      beforeEach (done) ->
        @sut.do done

      it 'should create one for each second in the seconds queue', (done) ->
        async.timesSeries 2, (n, next) =>
          secondWindow = 1478035140 + (n * 30)
          @client.llen "#{@queueName}:#{secondWindow}", (error, count) =>
            return next error if error?
            expect(count).to.equal 0
            next()
          return # redis fix
        , done

      it 'should have the correct processAt time', (done) ->
        @database.soldiers.findOne { _id: @record._id }, (error, updatedRecord) =>
          return done error if error?
          expect(updatedRecord.metadata.processAt).to.equal 1478035140
          expect(updatedRecord.metadata.processing).to.be.true
          done()

    describe 'when the intervalTime is 30 seconds and there are two records', ->
      beforeEach (done) ->
        record =
          metadata:
            processAt: 1478035141
            intervalTime: 30 * 1000
            fireOnce: false
          data:
            nonce: uuid.v1()
            uuid: 'the-uuid'
            token: 'the-token'
            sendTo: 'the-sendTo-uuid'
            nodeId: 'the-node-id'
            transactionId: 'the-transaction-id'
        @database.soldiers.insert record, (error, @recordTwo) =>
          done error

      beforeEach (done) ->
        record =
          metadata:
            processAt: 1478035140
            intervalTime: 30 * 1000
            fireOnce: false
          data:
            nonce: uuid.v1()
            uuid: 'the-uuid'
            token: 'the-token'
            sendTo: 'the-sendTo-uuid'
            nodeId: 'the-node-id'
            transactionId: 'the-transaction-id'
        @database.soldiers.insert record, (error, @recordOne) =>
          done error

      beforeEach (done) ->
        @sut.do done

      it 'should create one for each second in the seconds queue', (done) ->
        async.timesSeries 2, (n, next) =>
          secondWindow = 1478035140 + (n * 30)
          @client.brpop "#{@queueName}:#{secondWindow}", 1, (error, result) =>
            return next error if error?
            expect(result).to.exist
            [_, data] = result
            record = JSON.parse data
            expect(record.nonce).to.equal @recordOne.data.nonce
            next()
          return # redis fix
        , done

      it 'should have the correct processAt time on recordOne', (done) ->
        @database.soldiers.findOne { _id: @recordOne._id }, (error, updatedRecord) =>
          return done error if error?
          expect(updatedRecord.metadata.processAt).to.equal 1478035200
          done()

      it 'should have the correct processAt time on recordTwo', (done) ->
        @database.soldiers.findOne { _id: @recordTwo._id }, (error, updatedRecord) =>
          return done error if error?
          expect(updatedRecord.metadata.processAt).to.equal 1478035141
          done()

    describe 'when the intervalTime is 30 seconds and there are two records and one is processing', ->
      beforeEach (done) ->
        record =
          metadata:
            processAt: 1478035141
            intervalTime: 30 * 1000
            fireOnce: false
            processing: true
          data:
            nonce: uuid.v1()
            uuid: 'the-uuid'
            token: 'the-token'
            sendTo: 'the-sendTo-uuid'
            nodeId: 'the-node-id'
            transactionId: 'the-transaction-id'
        @database.soldiers.insert record, (error, @recordTwo) =>
          done error

      beforeEach (done) ->
        record =
          metadata:
            processAt: 1478035140
            intervalTime: 30 * 1000
            fireOnce: false
          data:
            nonce: uuid.v1()
            uuid: 'the-uuid'
            token: 'the-token'
            sendTo: 'the-sendTo-uuid'
            nodeId: 'the-node-id'
            transactionId: 'the-transaction-id'
        @database.soldiers.insert record, (error, @recordOne) =>
          done error

      beforeEach (done) ->
        @sut.do done

      it 'should create one for each second in the seconds queue', (done) ->
        async.timesSeries 2, (n, next) =>
          secondWindow = 1478035140 + (n * 30)
          @client.brpop "#{@queueName}:#{secondWindow}", 1, (error, result) =>
            return next error if error?
            expect(result).to.exist
            [_, data] = result
            record = JSON.parse data
            expect(record.nonce).to.equal @recordOne.data.nonce
            next()
          return # redis fix
        , done

      it 'should have the correct processAt time on recordOne', (done) ->
        @database.soldiers.findOne { _id: @recordOne._id }, (error, updatedRecord) =>
          return done error if error?
          expect(updatedRecord.metadata.processAt).to.equal 1478035200
          done()

      it 'should have the correct processAt time on recordTwo', (done) ->
        @database.soldiers.findOne { _id: @recordTwo._id }, (error, updatedRecord) =>
          return done error if error?
          expect(updatedRecord.metadata.processAt).to.equal 1478035141
          done()

    describe 'when the intervalTime is 1250 ms', ->
      beforeEach (done) ->
        record =
          metadata:
            processAt: 1478035140
            intervalTime: 1250
            fireOnce: false
          data:
            nonce: uuid.v1()
            uuid: 'the-uuid'
            token: 'the-token'
            sendTo: 'the-sendTo-uuid'
            nodeId: 'the-node-id'
            transactionId: 'the-transaction-id'
        @database.soldiers.insert record, (error, @record) =>
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
        @database.soldiers.findOne { _id: @record._id }, (error, updatedRecord) =>
          return done error if error?
          expect(updatedRecord.metadata.processAt).to.equal 1478035140 + 60
          expect(updatedRecord.metadata.processing).to.be.false
          done()

    describe 'when the intervalTime is 2 minutes', ->
      beforeEach (done) ->
        record =
          metadata:
            processAt: 1478035140
            intervalTime: 60 * 1000 * 2
            fireOnce: false
          data:
            nonce: uuid.v1()
            uuid: 'the-uuid'
            token: 'the-token'
            sendTo: 'the-sendTo-uuid'
            nodeId: 'the-node-id'
            transactionId: 'the-transaction-id'
        @database.soldiers.insert record, (error, @record) =>
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
        @database.soldiers.findOne { _id: @record._id }, (error, updatedRecord) =>
          return done error if error?
          expect(updatedRecord.metadata.processAt).to.equal 1478035140 + (60 * 2)
          expect(updatedRecord.metadata.processing).to.be.false
          done()
