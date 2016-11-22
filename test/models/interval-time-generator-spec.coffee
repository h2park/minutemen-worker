_             = require 'lodash'
TimeGenerator = require '../../src/models/time-generator'
TimeRange     = require '../../src/models/time-range'
moment        = require 'moment'

describe 'TimeGenerator (Interval)', ->
  describe '->getIntervalsForTimeRange', ->
    describe 'when set to 1 second', ->
      beforeEach ->
        @timeRange = new TimeRange {
          timestamp: 1478033400,
          processNow: true,
          offsetSeconds: 60
        }
        @sut = new TimeGenerator { @timeRange, intervalTime: 1000 }

      it 'should have the correct seconds list', ->
        seconds = _.map _.range(1, 61), (n) => @timeRange.timestamp + n
        expect(@sut.getIntervalsForTimeRange()).to.deep.equal seconds

    describe 'when set to every 1499', ->
      beforeEach ->
        @timeRange = new TimeRange {
          timestamp: 1478033400,
          processNow: true,
          offsetSeconds: 60
        }
        @sut = new TimeGenerator { @timeRange, intervalTime: 1499 }

      it 'should have the correct seconds list', ->
        seconds = _.map _.range(1, 61), (n) => @timeRange.timestamp + n
        expect(@sut.getIntervalsForTimeRange()).to.deep.equal seconds

    describe 'when set to every 2000', ->
      beforeEach ->
        @timeRange = new TimeRange {
          timestamp: 1478033400,
          processNow: true,
          offsetSeconds: 60
        }
        @sut = new TimeGenerator { @timeRange, intervalTime: 2000 }

      it 'should have the correct seconds list', ->
        seconds = _.map _.range(1, 31), (n) => 1478033400 + (n * 2)
        expect(@sut.getIntervalsForTimeRange()).to.deep.equal seconds

    describe 'when set to every 1500', ->
      beforeEach ->
        @timeRange = new TimeRange {
          timestamp: 1478033400,
          processNow: true,
          offsetSeconds: 60
        }
        @sut = new TimeGenerator { @timeRange, intervalTime: 1500 }

      it 'should have the correct seconds list', ->
        seconds = _.map _.range(1, 31), (n) => @timeRange.timestamp + (n * 2)
        expect(@sut.getIntervalsForTimeRange()).to.deep.equal seconds

    describe 'when set to every 30 seconds', ->
      beforeEach ->
        @timeRange = new TimeRange {
          timestamp: 1478033400,
          processNow: true,
          offsetSeconds: 60
        }
        @sut = new TimeGenerator { @timeRange, intervalTime: 30000 }

      it 'should have the correct seconds list', ->
        expect(@sut.getIntervalsForTimeRange()).to.deep.equal [1478033430,1478033460]

    describe 'when set to every 10 minutes', ->
      beforeEach ->
        @timeRange = new TimeRange {
          timestamp: 1478033400,
          lastRunAt: 1478033400 - (9 * 60) - 10,
          processNow: true,
          offsetSeconds: 60
        }
        @sut = new TimeGenerator { @timeRange, intervalTime: (10 * 60 * 1000) }

      it 'should have the correct seconds list', ->
        expect(@sut.getIntervalsForTimeRange()).to.deep.equal [1478033450]

  describe '->getNextProcessAt', ->
    describe 'when set to 1 second', ->
      beforeEach ->
        @timeRange = new TimeRange {
          timestamp: 1478033400,
          processNow: true,
          offsetSeconds: 60
        }
        @sut = new TimeGenerator { @timeRange, intervalTime: 1000}

      it 'should have the correct next second', ->
        expect(@sut.getNextProcessAt()).to.equal @timeRange.nextMax() + 1

    describe 'when set to 2 second', ->
      beforeEach ->
        @timeRange = new TimeRange {
          timestamp: 1478033400,
          processNow: true,
          offsetSeconds: 60
        }
        @sut = new TimeGenerator { @timeRange, intervalTime: 2 * 1000, processNow: true }

      it 'should have the correct next second', ->
        expect(@sut.getNextProcessAt()).to.equal @timeRange.nextMax() + 2

    describe 'when set to 30 second', ->
      beforeEach ->
        @timeRange = new TimeRange {
          timestamp: 1478033400,
          processNow: true,
          offsetSeconds: 60
        }
        @sut = new TimeGenerator { @timeRange, intervalTime: 30 * 1000, processNow: true }

      it 'should have the correct next second', ->
        expect(@sut.getNextProcessAt()).to.equal @timeRange.nextMax() + 30

    describe 'when set to 1 minute', ->
      beforeEach ->
        @timeRange = new TimeRange {
          timestamp: 1478033400,
          processNow: true,
          offsetSeconds: 60
        }
        @sut = new TimeGenerator { @timeRange, intervalTime: 60 * 1000 }

      it 'should have the correct next second', ->
        expect(@sut.getNextProcessAt()).to.equal  @timeRange.max()

    describe 'when set to 10 minute', ->
      beforeEach ->
        @timeRange = new TimeRange {
          timestamp: 1478033400,
          processNow: true,
          offsetSeconds: 60
        }
        @sut = new TimeGenerator { @timeRange, intervalTime: 10 * 60 * 1000 }

      it 'should have the correct next second', ->
        expect(@sut.getNextProcessAt()).to.equal @timeRange.start() + (10 * 60)
