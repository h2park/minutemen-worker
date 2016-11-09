_          = require 'lodash'
Redis      = require 'ioredis'
RedisNS    = require '@octoblu/redis-ns'
mongojs    = require 'mongojs'
uuid       = require 'uuid'
Soldier    = require '../helpers/soldier'
Seconds    = require '../helpers/seconds'
PaulRevere = require '../../src/controllers/paul-revere'

describe 'Multiple Runs (Cron)', ->
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
    @soldier = new Soldier { @database }
    @sut     = new PaulRevere { @database, @client, @queueName, offsetSeconds: 60 }

  describe 'when cronString is once a second', ->
    beforeEach (done) ->
      @sut.getTime (error, @currentTimestamp) =>
        done error

    beforeEach (done) ->
      metadata = {
        cronString: '* * * * * *',
        processNow: true,
        processAt: _.clone(@currentTimestamp)
      }
      @soldier.create metadata, done

    beforeEach (done) ->
      @recordId = @soldier.getRecordId()
      @sut.findAndDeploySoldier @currentTimestamp, (error) =>
        return done error if error?
        @soldier.get done

    it 'should create the correct seconds', (done) ->
      @seconds.hasSeconds { @currentTimestamp, @recordId, intervalTime: 1000 }, done

    it 'should have an updated record', ->
      @soldier.checkUpdatedRecord({ @currentTimestamp })

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
        @soldier.checkUpdatedRecord({ currentTimestamp:@nextTimestamp })

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

  describe 'when cronString is every other second', ->
    beforeEach (done) ->
      @sut.getTime (error, @currentTimestamp) =>
        done error

    beforeEach (done) ->
      metadata = {
        cronString: '*/30 * * * * *',
        processNow: true,
        processAt: _.clone(@currentTimestamp)
      }
      @soldier.create metadata, done

    beforeEach (done) ->
      @recordId = @soldier.getRecordId()
      @sut.findAndDeploySoldier @currentTimestamp, (error) =>
        return done error if error?
        @soldier.get done

    it 'should create the correct seconds', (done) ->
      @seconds.hasSeconds { @currentTimestamp, @recordId, intervalTime: 2000 }, done

    it 'should have an updated record', ->
      @soldier.checkUpdatedRecord({ @currentTimestamp })

    describe 'wait 2 minutes and run again', ->
      beforeEach (done) ->
        @client.flushall done
        return # redis

      beforeEach (done) ->
        @nextTimestamp = _.clone @currentTimestamp + 120
        @sut.findAndDeploySoldier @nextTimestamp, (error) =>
          return done error if error?
          @soldier.get done

      it 'should create a new set of correct seconds', (done) ->
        @seconds.hasSeconds { currentTimestamp:@nextTimestamp, @recordId, intervalTime:2000 }, done

      it 'should have an updated record', ->
        @soldier.checkUpdatedRecord({ currentTimestamp:@nextTimestamp })

    describe 'wait 1 second and run again', ->
      beforeEach (done) ->
        @client.flushall done
        return # redis

      beforeEach (done) ->
        @nextTimestamp = _.clone @currentTimestamp + 1
        @sut.findAndDeploySoldier @nextTimestamp, (@error) =>
          @soldier.get done

      it 'should have a 404 error', ->
        expect(@error.code).to.equal 404

      it 'should not create any seconds', (done) ->
        @seconds.doesNotHaveSeconds { currentTimestamp:@nextTimestamp, @recordId, intervalTime:2000 }, done

      it 'should remain untouched since the last process', ->
        @soldier.checkSameRecord()

    describe 'wait 30 seconds and run again', ->
      beforeEach (done) ->
        @client.flushall done
        return # redis

      beforeEach (done) ->
        @nextTimestamp = _.clone @currentTimestamp + 30
        @sut.findAndDeploySoldier @nextTimestamp, (@error) =>
          @soldier.get done

      it 'should have a 404 error', ->
        expect(@error.code).to.equal 404

      it 'should not create any seconds', (done) ->
        @seconds.doesNotHaveSeconds {currentTimestamp:@nextTimestamp,@recordId,intervalTime:2000 }, done

      it 'should remain untouched since the last process', ->
        @soldier.checkSameRecord()
