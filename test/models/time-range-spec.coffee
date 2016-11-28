_         = require 'lodash'
TimeRange = require '../../src/models/time-range'
moment    = require 'moment'

describe 'TimeRange', ->
  describe '->max', ->
    describe 'when processNow is true', ->
      beforeEach ->
        @sut = new TimeRange { timestamp: 1478033340, offsetSeconds: 60, processNow: true }

      it 'should be set to the min + 120', ->
        expect(@sut.max()).to.equal @sut.min() + 120

    describe 'when processNow is false', ->
      beforeEach ->
        @sut = new TimeRange { timestamp: 1478033340, offsetSeconds: 60, processNow: false }

      it 'should be set to the min time + 60', ->
        expect(@sut.max()).to.equal @sut.min() + 60

  describe '->min', ->
    describe 'when processNow is true', ->
      beforeEach ->
        @sut = new TimeRange { timestamp: 1478033340, offsetSeconds: 60, processNow: true }

      it 'should be set to the current timestamp', ->
        expect(@sut.min()).to.equal 1478033340

    describe 'when processNow is false', ->
      beforeEach ->
        @sut = new TimeRange { timestamp: 1478033340, offsetSeconds: 60, processNow: false }

      it 'should be set to current timestamp + 60', ->
        expect(@sut.min()).to.equal 1478033340 + 60

  describe '->start', ->
    describe 'when lastRunAt is set', ->
      beforeEach ->
        @sut = new TimeRange { timestamp: 1478033340, offsetSeconds: 60, lastRunAt: 1478033300 }

      it 'should be set to the lastRunAt', ->
        expect(@sut.start()).to.equal 1478033300

    describe 'when lastRunAt is not set', ->
      beforeEach ->
        @sut = new TimeRange { timestamp: 1478033340, offsetSeconds: 60 }

      it 'should be set to the lastRunAt', ->
        expect(@sut.start()).to.equal 1478033340

  describe '->nextWindow', ->
    beforeEach ->
      @sut = new TimeRange { timestamp: 1478033340, offsetSeconds: 60 }

    it 'should be set to the current timestamp + 60', ->
      expect(@sut.nextWindow()).to.equal 1478033340 + 60
