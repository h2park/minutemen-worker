_             = require 'lodash'
TimeGenerator = require '../../src/models/time-generator'
TimeRange     = require '../../src/models/time-range'
moment        = require 'moment'

describe 'TimeGenerator (Cron)', ->
  describe '->getIntervalsForTimeRange', ->
    describe 'when set every second', ->
      beforeEach ->
        @timeRange = new TimeRange {
          timestamp: 1478033400,
          processNow: true,
          offsetSeconds: 60
        }
        @sut = new TimeGenerator { @timeRange, cronString: '* * * * * *' }

      it 'should have correct list of seconds', ->
        seconds = _.map _.range(1, 121), (n) => @timeRange.timestamp + n
        expect(@sut.getIntervalsForTimeRange()).to.deep.equal seconds

    describe 'when set every 10 seconds', ->
      beforeEach ->
        @timeRange = new TimeRange {
          timestamp: 1478033400,
          processNow: true,
          offsetSeconds: 60
        }
        @sut = new TimeGenerator { @timeRange, cronString: '*/10 * * * * *' }

      it 'should have correct list of seconds', ->
        expect(@sut.getIntervalsForTimeRange()).to.deep.equal [
          1478033400,
          1478033410,
          1478033420,
          1478033430,
          1478033440,
          1478033450,
          1478033460,
        ]

    describe 'when set every minute', ->
      beforeEach ->
        @timeRange = new TimeRange {
          timestamp: 1478033400,
          processNow: true,
          offsetSeconds: 60
        }
        @sut = new TimeGenerator { @timeRange, cronString: '* * * * *' }

      it 'should have the correct second in the list', ->
        expect(@sut.getIntervalsForTimeRange()).to.deep.equal [1478033460]

    describe 'when set every 10 minute', ->
      beforeEach ->
        @timeRange = new TimeRange {
          timestamp: 1478034590,
          lastRunAt: 1478034600 - (10 * 60),
          processNow: true,
          offsetSeconds: 60
        }
        @sut = new TimeGenerator { @timeRange, cronString: '10 * * * *' }

      it 'should have the correct second in the list', ->
        expect(@sut.getIntervalsForTimeRange()).to.deep.equal [1478034600]

  describe '->getNextProcessAt', ->
    describe 'when set to 1 second', ->
      beforeEach ->
        @timeRange = new TimeRange {
          timestamp: 1478033400,
          processNow: true,
          offsetSeconds: 60
        }
        @sut = new TimeGenerator { @timeRange, cronString: '* * * * * *' }

      it 'should have the correct next second', ->
        expect(@sut.getNextProcessAt()).to.equal @timeRange.nextMax() + 1

    describe 'when set to 2 second', ->
      beforeEach ->
        @timeRange = new TimeRange {
          timestamp: 1478033400,
          processNow: true,
          offsetSeconds: 60
        }
        @sut = new TimeGenerator { @timeRange, cronString: '*/2 * * * * *' }

      it 'should have the correct next second', ->
        expect(@sut.getNextProcessAt()).to.equal @timeRange.nextMax() + 2

    describe 'when set to 30 second', ->
      beforeEach ->
        @timeRange = new TimeRange {
          timestamp: 1478033400,
          processNow: true,
          offsetSeconds: 60
        }
        @sut = new TimeGenerator { @timeRange, cronString: '*/30 * * * * *' }

      it 'should have the correct next second', ->
        expect(@sut.getNextProcessAt()).to.equal @timeRange.nextMax() + 30

    describe 'when set to 1 minute', ->
      beforeEach ->
        @timeRange = new TimeRange {
          timestamp: 1478033400,
          processNow: true,
          offsetSeconds: 60
        }
        @sut = new TimeGenerator { @timeRange, cronString: '* * * * *' }

      it 'should have the correct next second', ->
        expect(@sut.getNextProcessAt()).to.equal @timeRange.nextMax() + 60

    describe 'when set to 10 minute', ->
      beforeEach ->
        @timeRange = new TimeRange {
          timestamp: 1478033400,
          processNow: true,
          offsetSeconds: 60
        }
        @sut = new TimeGenerator { @timeRange, cronString: '*/10 * * * *' }

      it 'should have the correct next second', ->
        expect(@sut.getNextProcessAt()).to.equal @timeRange.start() + (10 * 60)
