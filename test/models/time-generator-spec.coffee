_             = require 'lodash'
TimeGenerator = require '../../src/models/time-generator'
TimeRange     = require '../../src/models/time-range'
moment        = require 'moment'

describe.only 'TimeGenerator', ->
  describe 'no timeRange', ->
    it 'should throw an error', ->
      expect(() =>
        new TimeGenerator {}
      ).to.throw

  beforeEach ->
    @timeRange = new TimeRange { timestamp: 1478033400 }

  describe '->getCurrentSeconds', ->
    describe 'when using intervalTime', ->
      describe 'when set to 1 second', ->
        describe 'when the processAt is the timestamp', ->
          beforeEach ->
            @sut = new TimeGenerator { @timeRange, intervalTime: 1000, processAt: 1478033400, processNow: true }

          it 'should have all 60 seconds in the list', ->
            seconds = _.map _.range(1, 60), (n) => 1478033400 + n
            expect(@sut.getCurrentSeconds()).to.deep.equal seconds

        describe 'when the processAt is 5 seconds in the future', ->
          beforeEach ->
            @sut = new TimeGenerator { @timeRange, intervalTime: 1000, processAt: 1478033405, processNow: true }

          it 'should have all 55 seconds in the list', ->
            seconds = _.map _.range(1, 55), (n) => 1478033405 + n
            expect(@sut.getCurrentSeconds()).to.deep.equal seconds

        describe 'when the processAt is 5 seconds in the past', ->
          beforeEach ->
            @sut = new TimeGenerator { @timeRange, intervalTime: 1000, processAt: 1478033395, processNow: true }

          it 'should have 60 seconds in the list', ->
            seconds = _.map _.range(1, 60), (n) => 1478033400 + n
            expect(@sut.getCurrentSeconds()).to.deep.equal seconds

      describe 'when set to every 1499', ->
        beforeEach ->
          @sut = new TimeGenerator { @timeRange, intervalTime: 1499, processAt: 1478033400, processNow: true }

        it 'should have all 60 seconds in the list', ->
          seconds =  _.map _.range(1, 60), (n) => 1478033400 + n
          expect(@sut.getCurrentSeconds()).to.deep.equal seconds

      describe 'when set to every 2000', ->
        beforeEach ->
          @sut = new TimeGenerator { @timeRange, intervalTime: 2000, processAt: 1478033400, processNow: true }

        it 'should have 30 seconds in the list', ->
          seconds = _.map _.range(1, 30), (n) => 1478033400 + (n * 2)
          expect(@sut.getCurrentSeconds()).to.deep.equal seconds

      describe 'when set to every 1500', ->
        beforeEach ->
          @sut = new TimeGenerator { @timeRange, intervalTime: 1500, processAt: 1478033400, processNow: true }

        it 'should have 30 seconds in the list', ->
          seconds = _.map _.range(1, 30), (n) => 1478033400 + (n * 2)
          expect(@sut.getCurrentSeconds()).to.deep.equal seconds

      describe 'when set to every 30 seconds', ->
        beforeEach ->
          @sut = new TimeGenerator { @timeRange, intervalTime: 30000, processAt: 1478033400, processNow: true }

        it 'should have 30 seconds in the list', ->
          expect(@sut.getCurrentSeconds()).to.deep.equal [1478033430]

      describe 'when set to every 10 minutes and should not be processed', ->
        beforeEach ->
          processAt = @timeRange.current().add(2, 'minutes').unix()
          @sut = new TimeGenerator { @timeRange, intervalTime: (10 * 60 * 1000), processAt, processNow: true }

        it 'should have a length of 0', ->
          expect(@sut.getCurrentSeconds().length).to.equal 0

      describe 'when set to every 10 minutes and should be processed', ->
        beforeEach ->
          @sut = new TimeGenerator { @timeRange, intervalTime: (10 * 60 * 1000), processAt: 147803300, processNow: true }

        it 'should have second for the processAt', ->
          expect(@sut.getCurrentSeconds()).to.deep.equal [1478033400]

    describe 'when using cron', ->
      describe 'when set every second', ->
        beforeEach ->
          @sut = new TimeGenerator { @timeRange, cronString: '* * * * * *', processAt: 1478033400, processNow: true }

        it 'should have 60 seconds in the list', ->
          seconds = _.times 60, (n) => 1478033400 + n
          expect(@sut.getCurrentSeconds()).to.deep.equal seconds

      describe 'when set every 10 seconds', ->
        beforeEach ->
          @sut = new TimeGenerator { @timeRange, cronString: '*/10 * * * * *', processAt: 1478033400, processNow: true }

        it 'should have 6 seconds in the list', ->
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
          @sut = new TimeGenerator { @timeRange, cronString: '* * * * *', processAt: 1478033400, processNow: true }

        it 'should have the correct second in the list', ->
          expect(@sut.getCurrentSeconds()).to.deep.equal [1478033400]

      describe 'when set every 10 minute', ->
        beforeEach ->
          @sut = new TimeGenerator { @timeRange, cronString: '*/10 * * * *', processAt: 1478033400, processNow: true }

        it 'should have the correct second in the list', ->
          expect(@sut.getCurrentSeconds()).to.deep.equal [1478033400]

  describe '->getNextProcessAt', ->
    describe 'when using intervalTime', ->
      describe 'when set to 1 second', ->
        beforeEach ->
          @currentProcessAt = @timeRange.current().add(30, 'seconds')
          @sut = new TimeGenerator { @timeRange, processAt: @currentProcessAt.unix(), intervalTime: 1000, processNow: true }
          @nextProcessAt = @sut.getNextSecond()

        it 'should have the correct nextProcessAt', ->
          expect(@nextProcessAt).to.not.equal @currentProcessAt.unix()
          expect(@nextProcessAt).to.equal 1478033460

      describe 'when set to 2 second', ->
        beforeEach ->
          @currentProcessAt = @timeRange.current().add(30, 'seconds')
          @sut = new TimeGenerator { @timeRange, processAt: @currentProcessAt.unix(), intervalTime: 2 * 1000, processNow: true }
          @nextProcessAt = @sut.getNextSecond()

        it 'should have the correct nextProcessAt', ->
          expect(@nextProcessAt).to.not.equal @currentProcessAt.unix()
          expect(@nextProcessAt).to.equal 1478033460

      describe 'when set to 30 second', ->
        beforeEach ->
          @currentProcessAt = @timeRange.current().add(30, 'seconds')
          @sut = new TimeGenerator { @timeRange, processAt: @currentProcessAt.unix(), intervalTime: 30 * 1000, processNow: true }
          @nextProcessAt = @sut.getNextSecond()

        it 'should have the correct nextProcessAt', ->
          expect(@nextProcessAt).to.not.equal @currentProcessAt.unix()
          expect(@nextProcessAt).to.equal 1478033460

      describe 'when set to 1 minute', ->
        beforeEach ->
          @currentProcessAt = @timeRange.current().add(30, 'seconds')
          @sut = new TimeGenerator { @timeRange, processAt: @currentProcessAt.unix(), intervalTime: 60 * 1000, processNow: true }
          @nextProcessAt = @sut.getNextSecond()

        it 'should have the correct nextProcessAt', ->
          expect(@nextProcessAt).to.not.equal @currentProcessAt.unix()
          expect(@nextProcessAt).to.equal 1478033460

      describe 'when set to 10 minute', ->
        beforeEach ->
          @currentProcessAt = @timeRange.current().add(30, 'seconds')
          @sut = new TimeGenerator { @timeRange, processAt: @currentProcessAt.unix(), intervalTime: 10 * 60 * 1000, processNow: true }
          @nextProcessAt = @sut.getNextSecond()

        it 'should have the correct nextProcessAt', ->
          expect(@nextProcessAt).to.not.equal @currentProcessAt.unix()
          expect(@nextProcessAt).to.equal 1478034000

    describe 'when using cronString', ->
      beforeEach ->
        @baseTime = @timeRange.current().add(1, 'minute')

      describe 'when set to 1 second', ->
        beforeEach ->
          @sut = new TimeGenerator { @timeRange, cronString: '* * * * * *', processAt: 1478033400, processNow: true }
          @nextProcessAt = @sut.getNextSecond()

        it 'should have the correct nextProcessAt', ->
          expect(@nextProcessAt).to.not.equal 1478033400
          expect(@nextProcessAt).to.equal 1478033460

      describe 'when set to 2 second', ->
        beforeEach ->
          @sut = new TimeGenerator { @timeRange, cronString: '*/2 * * * * *', processAt: 1478033400, processNow: true }
          @nextProcessAt = @sut.getNextSecond()

        it 'should have the correct nextProcessAt', ->
          expect(@nextProcessAt).to.not.equal 1478033400
          expect(@nextProcessAt).to.equal 1478033460

      describe 'when set to 30 second', ->
        beforeEach ->
          @sut = new TimeGenerator { @timeRange, cronString: '*/30 * * * * *', processAt: 1478033400, processNow: true }
          @nextProcessAt = @sut.getNextSecond()

        it 'should have the correct nextProcessAt', ->
          expect(@nextProcessAt).to.not.equal 1478033400
          expect(@nextProcessAt).to.equal 1478033460

      describe 'when set to 1 minute', ->
        beforeEach ->
          @sut = new TimeGenerator { @timeRange, cronString: '* * * * *', processAt: 1478033400, processNow: true }
          @nextProcessAt = @sut.getNextSecond()

        it 'should have the correct nextProcessAt', ->
          expect(@nextProcessAt).to.not.equal 1478033400
          expect(@nextProcessAt).to.equal 1478033460

      describe 'when set to 10 minute', ->
        beforeEach ->
          @sut = new TimeGenerator { @timeRange, cronString: '*/10 * * * *', processAt: 1478033400, processNow: true }
          @nextProcessAt = @sut.getNextSecond()

        it 'should have the correct nextProcessAt', ->
          expect(@nextProcessAt).to.not.equal 1478033400
          expect(@nextProcessAt).to.equal 1478034000
