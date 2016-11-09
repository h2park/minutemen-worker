_         = require 'lodash'
TimeRange = require '../../src/models/time-range'
moment    = require 'moment'

describe 'TimeRange', ->
  describe '->current', ->
    beforeEach ->
      @sut = new TimeRange { timestamp: 1478033340, offsetSeconds: 60 }

    it 'should be set the current time', ->
      expect(@sut.current()).to.equal 1478033340

  describe '->max', ->
    beforeEach ->
      @sut = new TimeRange { timestamp: 1478033340, offsetSeconds: 60 }

    it 'should be set to after the next time range', ->
      expect(@sut.max()).to.equal 1478033340 + 60

  describe '->min', ->
    describe 'when lastRunAt is not set', ->
      beforeEach ->
        @sut = new TimeRange { timestamp: 1478033340, offsetSeconds: 60 }

      it 'should be set to the same minute as the currentTime', ->
        expect(@sut.min()).to.equal 1478033340

    describe 'when lastRunAt is greater than the current time', ->
      beforeEach ->
        @sut = new TimeRange { timestamp: 1478033340, lastRunAt: 1478033370, offsetSeconds: 60 }

      it 'should be set to the same minute as lastRunAt', ->
        expect(@sut.min()).to.equal 1478033370

    describe 'when lastRunAt is less than the current time', ->
      beforeEach ->
        @sut = new TimeRange { timestamp: 1478033340, lastRunAt: 1478033300, offsetSeconds: 60 }

      it 'should be set to the same minute as the current time', ->
        expect(@sut.min()).to.equal 1478033340

  describe '->offset', ->
    beforeEach ->
      @sut = new TimeRange { timestamp: 1478033340, offsetSeconds: 60 }

    it 'should be set to 60 seconds', ->
      expect(@sut.offset()).to.equal 60

  describe '->sampleSize', ->
    describe 'fireOnce is false', ->
      beforeEach ->
        @sut = new TimeRange { timestamp: 1478033340, offsetSeconds: 60 }

      it 'should be set to 240 seconds', ->
        expect(@sut.sampleSize() > 60).to.be.true

    describe 'fireOnce is true', ->
      beforeEach ->
        @sut = new TimeRange { timestamp: 1478033340, offsetSeconds: 60, fireOnce: true }

      it 'should be set to 1 seconds', ->
        expect(@sut.sampleSize()).to.equal 1
