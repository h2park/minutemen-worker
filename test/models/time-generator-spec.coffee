_             = require 'lodash'
TimeGenerator = require '../../src/models/time-generator'
TimeRange     = require '../../src/models/time-range'
moment        = require 'moment'

describe 'TimeGenerator', ->
  describe '->getCurrentSeconds', ->
    describe 'when using intervalTime', ->
      describe 'when set to 1 second', ->
        beforeEach ->
          @timeRange = new TimeRange {
            timestamp: 1478033400,
            processNow: true,
            offsetSeconds: 60
          }
          @sut = new TimeGenerator { @timeRange, intervalTime: 1000 }

        it 'should have the correct seconds list', ->
          seconds = _.map _.range(0, 60), (n) => @timeRange.current() + n
          expect(@sut.getCurrentSeconds()).to.deep.equal seconds

      describe 'when set to every 1499', ->
        beforeEach ->
          @timeRange = new TimeRange {
            timestamp: 1478033400,
            processNow: true,
            offsetSeconds: 60
          }
          @sut = new TimeGenerator { @timeRange, intervalTime: 1499 }

        it 'should have the correct seconds list', ->
          seconds = _.map _.range(0, 60), (n) => @timeRange.current() + n
          expect(@sut.getCurrentSeconds()).to.deep.equal seconds

      describe 'when set to every 2000', ->
        beforeEach ->
          @timeRange = new TimeRange {
            timestamp: 1478033400,
            processNow: true,
            offsetSeconds: 60
          }
          @sut = new TimeGenerator { @timeRange, intervalTime: 2000 }

        it 'should have the correct seconds list', ->
          seconds = _.map _.range(0, 30), (n) => 1478033400 + (n * 2)
          expect(@sut.getCurrentSeconds()).to.deep.equal seconds

      describe 'when set to every 1500', ->
        beforeEach ->
          @timeRange = new TimeRange {
            timestamp: 1478033400,
            processNow: true,
            offsetSeconds: 60
          }
          @sut = new TimeGenerator { @timeRange, intervalTime: 1500 }

        it 'should have the correct seconds list', ->
          seconds = _.map _.range(0, 30), (n) => @timeRange.current() + (n * 2)
          expect(@sut.getCurrentSeconds()).to.deep.equal seconds

      describe 'when set to every 30 seconds', ->
        beforeEach ->
          @timeRange = new TimeRange {
            timestamp: 1478033400,
            processNow: true,
            offsetSeconds: 60
          }
          @sut = new TimeGenerator { @timeRange, intervalTime: 30000 }

        it 'should have the correct seconds list', ->
          expect(@sut.getCurrentSeconds()).to.deep.equal [1478033400,1478033430]

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
          expect(@sut.getCurrentSeconds()).to.deep.equal [1478033400]

    describe 'when using cron', ->
      describe 'when set every second', ->
        beforeEach ->
          @timeRange = new TimeRange {
            timestamp: 1478033400,
            processNow: true,
            offsetSeconds: 60
          }
          @sut = new TimeGenerator { @timeRange, cronString: '* * * * * *' }

        it 'should have correct list of seconds', ->
          seconds = _.map _.range(0, 60), (n) => @timeRange.current() + n
          expect(@sut.getCurrentSeconds()).to.deep.equal seconds

      describe 'when set every 10 seconds', ->
        beforeEach ->
          @timeRange = new TimeRange {
            timestamp: 1478033400,
            processNow: true,
            offsetSeconds: 60
          }
          @sut = new TimeGenerator { @timeRange, cronString: '*/10 * * * * *' }

        it 'should have correct list of seconds', ->
          expect(@sut.getCurrentSeconds()).to.deep.equal [
            1478033400,
            1478033410,
            1478033420,
            1478033430,
            1478033440,
            1478033450,
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
          expect(@sut.getCurrentSeconds()).to.deep.equal [1478033400]

      describe 'when set every 10 minute', ->
        beforeEach ->
          @timeRange = new TimeRange {
            timestamp: 1478033400,
            processNow: true,
            offsetSeconds: 60
          }
          @sut = new TimeGenerator { @timeRange, cronString: '*/10 * * * *' }

        it 'should have the correct second in the list', ->
          expect(@sut.getCurrentSeconds()).to.deep.equal [1478033400]

  describe '->getNextSecond', ->
    describe 'when using intervalTime', ->
      describe 'when set to 1 second', ->
        beforeEach ->
          @timeRange = new TimeRange {
            timestamp: 1478033400,
            processNow: true,
            offsetSeconds: 60
          }
          @sut = new TimeGenerator { @timeRange, intervalTime: 1000}

        it 'should have the correct next second', ->
          expect(@sut.getNextSecond()).to.equal @timeRange.nextMax()

      describe 'when set to 2 second', ->
        beforeEach ->
          @timeRange = new TimeRange {
            timestamp: 1478033400,
            processNow: true,
            offsetSeconds: 60
          }
          @sut = new TimeGenerator { @timeRange, intervalTime: 2 * 1000, processNow: true }

        it 'should have the correct next second', ->
          expect(@sut.getNextSecond()).to.equal @timeRange.nextMax()

      describe 'when set to 30 second', ->
        beforeEach ->
          @timeRange = new TimeRange {
            timestamp: 1478033400,
            processNow: true,
            offsetSeconds: 60
          }
          @sut = new TimeGenerator { @timeRange, intervalTime: 30 * 1000, processNow: true }

        it 'should have the correct next second', ->
          expect(@sut.getNextSecond()).to.equal @timeRange.nextMax()

      describe 'when set to 1 minute', ->
        beforeEach ->
          @timeRange = new TimeRange {
            timestamp: 1478033400,
            processNow: true,
            offsetSeconds: 60
          }
          @sut = new TimeGenerator { @timeRange, intervalTime: 60 * 1000 }

        it 'should have the correct next second', ->
          expect(@sut.getNextSecond()).to.equal  @timeRange.nextMax()

      describe 'when set to 10 minute', ->
        beforeEach ->
          @timeRange = new TimeRange {
            timestamp: 1478033400,
            processNow: true,
            offsetSeconds: 60
          }
          @sut = new TimeGenerator { @timeRange, intervalTime: 10 * 60 * 1000 }

        it 'should have the correct next second', ->
          expect(@sut.getNextSecond()).to.equal @timeRange.start() + (10 * 60)

    describe 'when using cronString', ->
      describe 'when set to 1 second', ->
        beforeEach ->
          @timeRange = new TimeRange {
            timestamp: 1478033400,
            processNow: true,
            offsetSeconds: 60
          }
          @sut = new TimeGenerator { @timeRange, cronString: '* * * * * *' }

        it 'should have the correct next second', ->
          expect(@sut.getNextSecond()).to.equal @timeRange.nextMax()

      describe 'when set to 2 second', ->
        beforeEach ->
          @timeRange = new TimeRange {
            timestamp: 1478033400,
            processNow: true,
            offsetSeconds: 60
          }
          @sut = new TimeGenerator { @timeRange, cronString: '*/2 * * * * *' }

        it 'should have the correct next second', ->
          expect(@sut.getNextSecond()).to.equal @timeRange.nextMax()

      describe 'when set to 30 second', ->
        beforeEach ->
          @timeRange = new TimeRange {
            timestamp: 1478033400,
            processNow: true,
            offsetSeconds: 60
          }
          @sut = new TimeGenerator { @timeRange, cronString: '*/30 * * * * *' }

        it 'should have the correct next second', ->
          expect(@sut.getNextSecond()).to.equal @timeRange.nextMax()

      describe 'when set to 1 minute', ->
        beforeEach ->
          @timeRange = new TimeRange {
            timestamp: 1478033400,
            processNow: true,
            offsetSeconds: 60
          }
          @sut = new TimeGenerator { @timeRange, cronString: '* * * * *' }

        it 'should have the correct next second', ->
          expect(@sut.getNextSecond()).to.equal @timeRange.nextMax()

      describe 'when set to 10 minute', ->
        beforeEach ->
          @timeRange = new TimeRange {
            timestamp: 1478033400,
            processNow: true,
            offsetSeconds: 60
          }
          @sut = new TimeGenerator { @timeRange, cronString: '*/10 * * * *' }

        it 'should have the correct next second', ->
          expect(@sut.getNextSecond()).to.equal @timeRange.start() + (10 * 60)
