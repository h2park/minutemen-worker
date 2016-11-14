_          = require 'lodash'
Redis      = require 'ioredis'
RedisNS    = require '@octoblu/redis-ns'
mongojs    = require 'mongojs'
uuid       = require 'uuid'
Soldier    = require '../helpers/soldier'
Seconds    = require '../helpers/seconds'
PaulRevere = require '../../src/controllers/paul-revere'

describe 'Imported Record', ->
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

  describe 'when there is no intervalTime or cronString', ->
    beforeEach (done) ->
      @sut.getTime (error, @currentTimestamp) =>
        done error

    beforeEach (done) ->
      metadata = {
        fireOnce: true,
        intervalUuid: 'some-interval-uuid',
        nonce: 'some-nonce'
        ownerUuid: 'owner-uuid'
      }
      @soldier.create metadata, done

    beforeEach (done) ->
      @recordId = @soldier.getRecordId()
      @sut.findAndDeploySoldier @currentTimestamp, (@error) =>
        done()

    it 'should have a 404 error', ->
      expect(@error?.code).to.equal 404

  describe 'when there is no processAt', ->
    beforeEach (done) ->
      @sut.getTime (error, @currentTimestamp) =>
        done error

    beforeEach (done) ->
      metadata = {
        fireOnce: true,
        intervalUuid: 'some-interval-uuid',
        nonce: 'some-nonce'
        ownerUuid: 'owner-uuid'
        intervalTime: 10000
      }
      @soldier.create metadata, done

    beforeEach (done) ->
      @recordId = @soldier.getRecordId()
      @sut.findAndDeploySoldier @currentTimestamp, (@error) =>
        done()

    it 'should have 404 error', ->
      expect(@error?.code).to.equal 404
