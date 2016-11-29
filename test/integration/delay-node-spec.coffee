_          = require 'lodash'
Redis      = require 'ioredis'
RedisNS    = require '@octoblu/redis-ns'
mongojs    = require 'mongojs'
uuid       = require 'uuid'
Soldier    = require '../helpers/soldier'
Seconds    = require '../helpers/seconds'
PaulRevere = require '../../src/controllers/paul-revere'

describe 'Delay Node', ->
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

  describe 'when intervalTime is every 30 seconds', ->
    beforeEach (done) ->
      @intervalSeconds = 1
      @intervalTime = @intervalSeconds * 1000
      @sut.getTime (error, @currentTimestamp) =>
        @soldier = new Soldier { @database, @currentTimestamp }
        done error

    beforeEach (done) ->
      metadata = {
        @intervalTime,
        processNow: false,
        fireOnce: true,
        processAt: @currentTimestamp
      }
      @soldier.create metadata, done

    beforeEach (done) ->
      @recordId = @soldier.getRecordId()
      @currentTimestamp += 60
      @nextTimestamp = @currentTimestamp + 60
      @nextNextTimestamp = @nextTimestamp + 60
      @sut.findAndDeploySoldier @currentTimestamp, (error) =>
        return done error if error?
        @soldier.get done

    beforeEach (done) ->
      @seconds.getSeconds {@currentTimestamp,@recordId,@intervalTime}, (error, @secondList) =>
        done error

    it 'should have the 1st second equal to the current timestamp', ->
      expect(@secondList.first).to.equal @nextTimestamp

    it 'should have no 2nd second', ->
      expect(@secondList.second).to.not.exist

    it 'should have the last second equal to first one', ->
      expect(@secondList.last).to.equal @secondList.last

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
