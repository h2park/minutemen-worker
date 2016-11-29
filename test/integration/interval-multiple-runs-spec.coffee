_          = require 'lodash'
Redis      = require 'ioredis'
RedisNS    = require '@octoblu/redis-ns'
mongojs    = require 'mongojs'
uuid       = require 'uuid'
Soldier    = require '../helpers/soldier'
Seconds    = require '../helpers/seconds'
PaulRevere = require '../../src/controllers/paul-revere'

describe 'Multiple Runs (Interval)', ->
  before (done) ->
    @queueName = "seconds-#{uuid.v1()}"
    client = new Redis 'localhost', dropBufferSupport: true
    client.on 'ready', =>
      @client = new RedisNS 'test-worker', client
      done()

  before ->
    @database = mongojs "minutemen-worker-test", ['soldiers']

  beforeEach (done) ->
    @client.flushall (error) =>
      return done error if error?
      @database.soldiers.drop (error) =>
        # return done error if error?
        done()
    return # redis fix

  beforeEach ->
    @seconds = new Seconds { @client, @queueName }
    @soldier = new Soldier { @database }
    @sut     = new PaulRevere { @database, @client, @queueName, offsetSeconds: 60 }

  describe 'when intervalTime is every second', ->
    beforeEach (done) ->
      @intervalSeconds = 1
      @intervalTime = @intervalSeconds * 1000
      @sut.getTime (error, @currentTimestamp) =>
        @soldier = new Soldier { @database, @currentTimestamp }
        done error

    beforeEach (done) ->
      metadata = {
        @intervalTime,
        processNow: true,
        processAt: @currentTimestamp
      }
      @soldier.create metadata, done

    beforeEach (done) ->
      @recordId = @soldier.getRecordId()
      @nextTimestamp = @currentTimestamp + 120
      @nextNextTimestamp = @nextTimestamp + 60
      @sut.findAndDeploySoldier @currentTimestamp, (error) =>
        return done error if error?
        @soldier.get done

    beforeEach (done) ->
      @seconds.getSeconds {@currentTimestamp,@recordId,@intervalTime,processNow:true}, (error, @secondList) =>
        done error

    it 'should have the 1st second equal to the current timestamp', ->
      expect(@secondList.first).to.equal @currentTimestamp

    it 'should have the 2nd second equal to one intervalSeconds later', ->
      expect(@secondList.second - @secondList.first).to.equal @intervalSeconds

    it 'should have the last second equal to one intervalSeconds before the next timestamp', ->
      expect(@secondList.last).to.equal (@nextTimestamp - @intervalSeconds)

    it 'should have the lastRunAt equal to the last second', ->
      expect(@soldier.getMetadata().lastRunAt).to.equal @secondList.last

    it 'should have the processAt set to the next window', ->
      expect(@soldier.getMetadata().processAt).to.equal @currentTimestamp + 60

    it 'should have the lastProcessAt set to the last processAt', ->
      expect(@soldier.getMetadata().lastProcessAt).to.equal @soldier.getPrevMetadata().processAt

    it 'should set processing to be false', ->
      expect(@soldier.getMetadata().processing).to.be.false

    it 'should set processNow to be false', ->
      expect(@soldier.getMetadata().processNow).to.be.false

    describe 'wait 0 seconds and run again', ->
      beforeEach (done) ->
        @client.flushall done
        return # redis

      beforeEach (done) ->
        @nextTimestamp = @currentTimestamp + 60
        @nextNextTimestamp = @nextTimestamp + 60
        @sut.findAndDeploySoldier @currentTimestamp, (@error) =>
          @soldier.get done

      beforeEach (done) ->
        @seconds.getSeconds {@currentTimestamp,@recordId,@intervalTime}, (error, @secondList) =>
          done error

      it 'should have a 404 error', ->
        expect(@error.code).to.equal 404

      it 'should not have a 1st second', ->
        expect(@secondList.first).to.not.exist

      it 'should not have a 2nd second', ->
        expect(@secondList.second).to.not.exist

      it 'should not have a last second', ->
        expect(@secondList.last).to.not.exist

      it 'should have the same metadata', ->
        expect(@soldier.getMetadata()).to.deep.equal @soldier.getPrevMetadata()

      describe 'wait 60 seconds and run again', ->
        beforeEach (done) ->
          @client.flushall done
          return # redis

        beforeEach (done) ->
          @nextTimestamp = @currentTimestamp + 60
          @nextNextTimestamp = @nextTimestamp + 60
          @sut.findAndDeploySoldier @currentTimestamp, (@error) =>
            @soldier.get done

        beforeEach (done) ->
          @seconds.getSeconds {@currentTimestamp,@recordId,@intervalTime}, (error, @secondList) =>
            done error

        it 'should have a 404 error', ->
          expect(@error.code).to.equal 404

        it 'should not have a 1st second', ->
          expect(@secondList.first).to.not.exist

        it 'should not have a 2nd second', ->
          expect(@secondList.second).to.not.exist

        it 'should not have a last second', ->
          expect(@secondList.last).to.not.exist

        it 'should have the same metadata', ->
          expect(@soldier.getMetadata()).to.deep.equal @soldier.getPrevMetadata()

    describe 'wait 2 minutes and run again', ->
      beforeEach (done) ->
        @client.flushall done
        return # redis

      beforeEach (done) ->
        @currentTimestamp += 120
        @nextTimestamp = @currentTimestamp + 60
        @nextNextTimestamp = @nextTimestamp + 60
        @sut.findAndDeploySoldier @currentTimestamp, (error) =>
          return done error if error?
          @soldier.get done

      beforeEach (done) ->
        @seconds.getSeconds {@currentTimestamp,@recordId,@intervalTime}, (error, @secondList) =>
          done error

      it 'should have the 1st second equal to the next timestamp', ->
        expect(@secondList.first).to.equal @nextTimestamp

      it 'should have the 2nd second equal to one intervalSeconds later', ->
        expect(@secondList.second - @secondList.first).to.equal @intervalSeconds

      it 'should have the last second equal to one intervalSeconds before the next next timestamp', ->
        expect(@secondList.last).to.equal (@nextNextTimestamp - @intervalSeconds)

      it 'should have the lastRunAt equal to the last second', ->
        expect(@soldier.getMetadata().lastRunAt).to.equal @secondList.last

      it 'should have the processAt set to the next window', ->
        expect(@soldier.getMetadata().processAt).to.equal @currentTimestamp + 60

      it 'should have the lastProcessAt set to the last processAt', ->
        expect(@soldier.getMetadata().lastProcessAt).to.equal @soldier.getPrevMetadata().processAt

      it 'should set processing to be false', ->
        expect(@soldier.getMetadata().processing).to.be.false

      it 'should set processNow to be false', ->
        expect(@soldier.getMetadata().processNow).to.be.false

  describe 'when intervalTime is every other second', ->
    beforeEach (done) ->
      @intervalSeconds = 2
      @intervalTime = @intervalSeconds * 1000
      @sut.getTime (error, @currentTimestamp) =>
        @soldier = new Soldier { @database, @currentTimestamp }
        done error

    beforeEach (done) ->
      metadata = {
        @intervalTime,
        processNow: true,
        processAt: @currentTimestamp
      }
      @soldier.create metadata, done

    beforeEach (done) ->
      @recordId = @soldier.getRecordId()
      @nextTimestamp = @currentTimestamp + 120
      @nextNextTimestamp = @nextTimestamp + 60
      @sut.findAndDeploySoldier @currentTimestamp, (error) =>
        return done error if error?
        @soldier.get done

    beforeEach (done) ->
      @seconds.getSeconds {@currentTimestamp,@recordId,@intervalTime,processNow:true}, (error, @secondList) =>
        done error

    it 'should have the 1st second equal to the current timestamp', ->
      expect(@secondList.first).to.equal @currentTimestamp

    it 'should have the 2nd second equal to one intervalSeconds later', ->
      expect(@secondList.second - @secondList.first).to.equal @intervalSeconds

    it 'should have the last second equal to one intervalSeconds before the next timestamp', ->
      expect(@secondList.last).to.equal (@nextTimestamp - @intervalSeconds)

    it 'should have the lastRunAt equal to the last second', ->
      expect(@soldier.getMetadata().lastRunAt).to.equal @secondList.last

    it 'should have the processAt set to the next window', ->
      expect(@soldier.getMetadata().processAt).to.equal @currentTimestamp + 60

    it 'should have the lastProcessAt set to the last processAt', ->
      expect(@soldier.getMetadata().lastProcessAt).to.equal @soldier.getPrevMetadata().processAt

    it 'should set processing to be false', ->
      expect(@soldier.getMetadata().processing).to.be.false

    it 'should set processNow to be false', ->
      expect(@soldier.getMetadata().processNow).to.be.false

    describe 'wait 0 seconds and run again', ->
      beforeEach (done) ->
        @client.flushall done
        return # redis

      beforeEach (done) ->
        @nextTimestamp = @currentTimestamp + 60
        @nextNextTimestamp = @nextTimestamp + 60
        @sut.findAndDeploySoldier @currentTimestamp, (@error) =>
          @soldier.get done

      beforeEach (done) ->
        @seconds.getSeconds {@currentTimestamp,@recordId,@intervalTime}, (error, @secondList) =>
          done error

      it 'should have a 404 error', ->
        expect(@error.code).to.equal 404

      it 'should not have a 1st second', ->
        expect(@secondList.first).to.not.exist

      it 'should not have a 2nd second', ->
        expect(@secondList.second).to.not.exist

      it 'should not have a last second', ->
        expect(@secondList.last).to.not.exist

      it 'should have the same metadata', ->
        expect(@soldier.getMetadata()).to.deep.equal @soldier.getPrevMetadata()

      describe 'wait 60 seconds and run again', ->
        beforeEach (done) ->
          @client.flushall done
          return # redis

        beforeEach (done) ->
          @nextTimestamp = @currentTimestamp + 60
          @nextNextTimestamp = @nextTimestamp + 60
          @sut.findAndDeploySoldier @currentTimestamp, (@error) =>
            @soldier.get done

        beforeEach (done) ->
          @seconds.getSeconds {@currentTimestamp,@recordId,@intervalTime}, (error, @secondList) =>
            done error

        it 'should have a 404 error', ->
          expect(@error.code).to.equal 404

        it 'should not have a 1st second', ->
          expect(@secondList.first).to.not.exist

        it 'should not have a 2nd second', ->
          expect(@secondList.second).to.not.exist

        it 'should not have a last second', ->
          expect(@secondList.last).to.not.exist

        it 'should have the same metadata', ->
          expect(@soldier.getMetadata()).to.deep.equal @soldier.getPrevMetadata()

    describe 'wait 2 minutes and run again', ->
      beforeEach (done) ->
        @client.flushall done
        return # redis

      beforeEach (done) ->
        @currentTimestamp += 120
        @nextTimestamp = @currentTimestamp + 60
        @nextNextTimestamp = @nextTimestamp + 60
        @sut.findAndDeploySoldier @currentTimestamp, (error) =>
          return done error if error?
          @soldier.get done

      beforeEach (done) ->
        @seconds.getSeconds {@currentTimestamp,@recordId,@intervalTime}, (error, @secondList) =>
          done error

      it 'should have the 1st second equal to the next timestamp', ->
        expect(@secondList.first).to.equal @nextTimestamp

      it 'should have the 2nd second equal to one intervalSeconds later', ->
        expect(@secondList.second - @secondList.first).to.equal @intervalSeconds

      it 'should have the last second equal to one intervalSeconds before the next next timestamp', ->
        expect(@secondList.last).to.equal (@nextNextTimestamp - @intervalSeconds)

      it 'should have the lastRunAt equal to the last second', ->
        expect(@soldier.getMetadata().lastRunAt).to.equal @secondList.last

      it 'should have the processAt set to the next window', ->
        expect(@soldier.getMetadata().processAt).to.equal @currentTimestamp + 60

      it 'should have the lastProcessAt set to the last processAt', ->
        expect(@soldier.getMetadata().lastProcessAt).to.equal @soldier.getPrevMetadata().processAt

      it 'should set processing to be false', ->
        expect(@soldier.getMetadata().processing).to.be.false

      it 'should set processNow to be false', ->
        expect(@soldier.getMetadata().processNow).to.be.false

  describe 'when intervalTime is every minute', ->
    beforeEach (done) ->
      @intervalSeconds = 60
      @intervalTime = @intervalSeconds * 1000
      @sut.getTime (error, @currentTimestamp) =>
        @soldier = new Soldier { @database, @currentTimestamp }
        done error

    beforeEach (done) ->
      metadata = {
        @intervalTime,
        processNow: true,
        processAt: @currentTimestamp
      }
      @soldier.create metadata, done

    beforeEach (done) ->
      @recordId = @soldier.getRecordId()
      @nextTimestamp = @currentTimestamp + 120
      @nextNextTimestamp = @nextTimestamp + 60
      @sut.findAndDeploySoldier @currentTimestamp, (error) =>
        return done error if error?
        @soldier.get done

    beforeEach (done) ->
      @seconds.getSeconds {@currentTimestamp,@recordId,@intervalTime,processNow:true}, (error, @secondList) =>
        done error

    it 'should have the 1st second equal to the current timestamp', ->
      expect(@secondList.first).to.equal @currentTimestamp

    it 'should have the 2nd second equal to one intervalSeconds later', ->
      expect(@secondList.second - @secondList.first).to.equal @intervalSeconds

    it 'should have the last second equal to one intervalSeconds before the next timestamp', ->
      expect(@secondList.last).to.equal (@nextTimestamp - @intervalSeconds)

    it 'should have the lastRunAt equal to the last second', ->
      expect(@soldier.getMetadata().lastRunAt).to.equal @secondList.last

    it 'should have the processAt set to the next window', ->
      expect(@soldier.getMetadata().processAt).to.equal @currentTimestamp + 60

    it 'should have the lastProcessAt set to the last processAt', ->
      expect(@soldier.getMetadata().lastProcessAt).to.equal @soldier.getPrevMetadata().processAt

    it 'should set processing to be false', ->
      expect(@soldier.getMetadata().processing).to.be.false

    it 'should set processNow to be false', ->
      expect(@soldier.getMetadata().processNow).to.be.false

    describe 'wait 0 seconds and run again', ->
      beforeEach (done) ->
        @client.flushall done
        return # redis

      beforeEach (done) ->
        @nextTimestamp = @currentTimestamp + 60
        @nextNextTimestamp = @nextTimestamp + 60
        @sut.findAndDeploySoldier @currentTimestamp, (@error) =>
          @soldier.get done

      beforeEach (done) ->
        @seconds.getSeconds {@currentTimestamp,@recordId,@intervalTime}, (error, @secondList) =>
          done error

      it 'should have a 404 error', ->
        expect(@error.code).to.equal 404

      it 'should not have a 1st second', ->
        expect(@secondList.first).to.not.exist

      it 'should not have a 2nd second', ->
        expect(@secondList.second).to.not.exist

      it 'should not have a last second', ->
        expect(@secondList.last).to.not.exist

      it 'should have the same metadata', ->
        expect(@soldier.getMetadata()).to.deep.equal @soldier.getPrevMetadata()

    describe 'wait 1 minute and run again', ->
      beforeEach (done) ->
        @client.flushall done
        return # redis

      beforeEach (done) ->
        @nextTimestamp = @currentTimestamp + 60
        @nextNextTimestamp = @nextTimestamp + 60
        @sut.findAndDeploySoldier @currentTimestamp, (@error) =>
          @soldier.get done

      beforeEach (done) ->
        @seconds.getSeconds {@currentTimestamp,@recordId,@intervalTime}, (error, @secondList) =>
          done error

      it 'should have a 404 error', ->
        expect(@error.code).to.equal 404

      it 'should not have a 1st second', ->
        expect(@secondList.first).to.not.exist

      it 'should not have a 2nd second', ->
        expect(@secondList.second).to.not.exist

      it 'should not have a last second', ->
        expect(@secondList.last).to.not.exist

      it 'should have the same metadata', ->
        expect(@soldier.getMetadata()).to.deep.equal @soldier.getPrevMetadata()

    describe 'wait 2 minutes and run again', ->
      beforeEach (done) ->
        @client.flushall done
        return # redis

      beforeEach (done) ->
        @currentTimestamp += 120
        @nextTimestamp = @currentTimestamp + 60
        @nextNextTimestamp = @nextTimestamp + 60
        @sut.findAndDeploySoldier @currentTimestamp, (error) =>
          return done error if error?
          @soldier.get done

      beforeEach (done) ->
        @seconds.getSeconds {@currentTimestamp,@recordId,@intervalTime}, (error, @secondList) =>
          done error

      it 'should have the 1st second equal to the next timestamp', ->
        expect(@secondList.first).to.equal @nextTimestamp

      it 'should have not have a 2nd second', ->
        expect(@secondList.second).to.not.exist

      it 'should have the last equal to the first', ->
        expect(@secondList.last).to.equal @secondList.first

      it 'should have the lastRunAt equal to the last second', ->
        expect(@soldier.getMetadata().lastRunAt).to.equal @secondList.last

      it 'should have the processAt set to the next window', ->
        expect(@soldier.getMetadata().processAt).to.equal @currentTimestamp + 60

      it 'should have the lastProcessAt set to the last processAt', ->
        expect(@soldier.getMetadata().lastProcessAt).to.equal @soldier.getPrevMetadata().processAt

      it 'should set processing to be false', ->
        expect(@soldier.getMetadata().processing).to.be.false

      it 'should set processNow to be false', ->
        expect(@soldier.getMetadata().processNow).to.be.false
