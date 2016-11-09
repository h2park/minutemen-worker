_          = require 'lodash'
Redis      = require 'ioredis'
RedisNS    = require '@octoblu/redis-ns'
mongojs    = require 'mongojs'
moment     = require 'moment'
uuid       = require 'uuid'
async      = require 'async'
Soldier    = require '../helpers/soldier'
Seconds    = require '../helpers/seconds'
PaulRevere = require '../../src/controllers/paul-revere'

describe.only 'Multiple Runs (Interval)', ->
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
    @seconds = new Seconds { @client, @queueName }
    @sut     = new PaulRevere { @database, @client, @queueName }

  describe 'when intervalTime is once a second', ->
    beforeEach (done) ->
      @sut.getTime (error, @currentTimestamp) =>
        @soldier = new Soldier { @database, @currentTimestamp }
        done error

    beforeEach (done) ->
      @soldier.create {intervalTime: 1000}, done

    beforeEach (done) ->
      @recordId = @soldier.getRecordId()
      @sut.findAndDeploySoldier @currentTimestamp, (error) =>
        return done error if error?
        @soldier.get done

    it 'should create the correct seconds', (done) ->
      @seconds.hasSeconds { @currentTimestamp, @recordId, intervalTime: 1000 }, done

    it 'should have an updated record', ->
      @soldier.checkUpdatedRecord()

    describe 'wait 2 minutes and run again', ->
      beforeEach (done) ->
        @client.flushall done
        return # redis

      beforeEach (done) ->
        @nextTimestamp = @currentTimestamp + 120
        @sut.findAndDeploySoldier @nextTimestamp, (error) =>
          return done error if error?
          @soldier.get done

      it 'should create the correct seconds', (done) ->
        @seconds.hasSeconds { currentTimestamp:@nextTimestamp, @recordId, intervalTime: 1000 }, done

      it 'should have an updated record', ->
        @soldier.checkUpdatedRecord()

    describe 'wait 1 second and run again', ->
      beforeEach (done) ->
        @client.flushall done
        return # redis

      beforeEach (done) ->
        @nextTimestamp = @currentTimestamp + 1
        @sut.findAndDeploySoldier @nextTimestamp, (@error) =>
          @soldier.get done

      it 'should have a 404 error', ->
        expect(@error.code).to.equal 404

      it 'should not create any seconds', (done) ->
        @seconds.doesNotHaveSeconds { currentTimestamp:@nextTimestamp, @recordId, intervalTime: 1000 }, done

      it 'should remain untouched since the last process', ->
        @soldier.checkSameRecord()

    describe 'wait 30 seconds and run again', ->
      beforeEach (done) ->
        @client.flushall done
        return # redis

      beforeEach (done) ->
        @nextTimestamp = @currentTimestamp + 30
        @sut.findAndDeploySoldier @nextTimestamp, (@error) =>
          @soldier.get done

      it 'should have a 404 error', ->
        expect(@error.code).to.equal 404

      it 'should not create any seconds', (done) ->
        @seconds.doesNotHaveSeconds {currentTimestamp:@nextTimestamp,@recordId,intervalTime: 1000 }, done

      it 'should remain untouched since the last process', ->
        @soldier.checkSameRecord()

  describe 'when intervalTime is every other second', ->
    beforeEach (done) ->
      @sut.getTime (error, @currentTimestamp) =>
        @soldier = new Soldier { @database, @currentTimestamp }
        done error

    beforeEach (done) ->
      @soldier.create {intervalTime: 2000}, done

    beforeEach (done) ->
      @recordId = @soldier.getRecordId()
      @sut.findAndDeploySoldier @currentTimestamp, (error) =>
        return done error if error?
        @soldier.get done

    it 'should create the correct seconds', (done) ->
      @seconds.hasSeconds { @currentTimestamp, @recordId, intervalTime: 2000 }, done

    it 'should have an updated record', ->
      @soldier.checkUpdatedRecord()

    describe 'wait 2 minutes and run again', ->
      beforeEach (done) ->
        @client.flushall done
        return # redis

      beforeEach (done) ->
        @nextTimestamp = @currentTimestamp + 120
        @sut.findAndDeploySoldier @nextTimestamp, (error) =>
          return done error if error?
          @soldier.get done

      it 'should create the correct seconds', (done) ->
        @seconds.hasSeconds { currentTimestamp:@nextTimestamp, @recordId, intervalTime: 2000 }, done

      it 'should have an updated record', ->
        @soldier.checkUpdatedRecord()

    describe 'wait 1 second and run again', ->
      beforeEach (done) ->
        @client.flushall done
        return # redis

      beforeEach (done) ->
        @nextTimestamp = @currentTimestamp + 1
        @sut.findAndDeploySoldier @nextTimestamp, (@error) =>
          @soldier.get done

      it 'should have a 404 error', ->
        expect(@error.code).to.equal 404

      it 'should not create any seconds', (done) ->
        @seconds.doesNotHaveSeconds { currentTimestamp:@nextTimestamp, @recordId, intervalTime: 2000 }, done

      it 'should remain untouched since the last process', ->
        @soldier.checkSameRecord()

    describe 'wait 30 seconds and run again', ->
      beforeEach (done) ->
        @client.flushall done
        return # redis

      beforeEach (done) ->
        @nextTimestamp = @currentTimestamp + 30
        @sut.findAndDeploySoldier @nextTimestamp, (@error) =>
          @soldier.get done

      it 'should have a 404 error', ->
        expect(@error.code).to.equal 404

      it 'should not create any seconds', (done) ->
        @seconds.doesNotHaveSeconds {currentTimestamp:@nextTimestamp,@recordId,intervalTime: 2000 }, done

      it 'should remain untouched since the last process', ->
        @soldier.checkSameRecord()
