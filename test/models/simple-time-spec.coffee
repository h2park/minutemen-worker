_             = require 'lodash'
TimeGenerator = require '../../src/models/time-generator'
TimeRange     = require '../../src/models/time-range'
moment        = require 'moment'

describe 'Simple Time Example', ->
  beforeEach ->
    timeRange = new TimeRange { timestamp: 100, offsetSeconds: 60, lastRunAt: 100, processNow: true }
    @sut = new TimeGenerator { timeRange, intervalTime: 1000 }

  describe 'when it gets the current seconds', ->
    it 'should have a list of the seconds 101-160', ->
      expect(@sut.getCurrentSeconds()).to.deep.equal _.range(101, 161)

    it 'should get the next second', ->
      expect(@sut.getNextSecond()).to.equal 221

    describe 'when processed again', ->
      beforeEach ->
        timeRange = new TimeRange { timestamp: 160, offsetSeconds: 60, lastRunAt: 100 }
        @sut = new TimeGenerator { timeRange, intervalTime: 1000 }

      it 'should have a list of the seconds 161-220', ->
        expect(@sut.getCurrentSeconds()).to.deep.equal _.range(161, 221)

      it 'should get the next second', ->
        expect(@sut.getNextSecond()).to.equal 281
