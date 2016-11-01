_          = require 'lodash'
TimeParser = require '../src/time-parser'
moment     = require 'moment'

describe.only 'TimeParser', ->
  beforeEach ->
    @timestamp = moment().unix()
    @sut = new TimeParser { @timestamp }

  it 'should throw an error', ->
    expect(() =>
      new TimeParser {}
    ).to.throw

  describe '->getCurrentTime', ->
    it 'should be set to the next minute', ->
      nextMinute = moment.unix(@timestamp).add(1, 'minute')
      expect(@sut.getCurrentTime().valueOf()).to.deep.equal nextMinute.valueOf()

  describe '->getMaxRangeTime', ->
    it 'should be set to the next minute after the currentTime', ->
      maxMinute = moment.unix(@timestamp).add(2, 'minute')
      expect(@sut.getMaxRangeTime().valueOf()).to.deep.equal maxMinute.valueOf()

  describe '->getMinRangeTime', ->
    it 'should be set to the same minute as the currentTime', ->
      minMinute = moment.unix(@timestamp).add(1, 'minute')
      expect(@sut.getMinRangeTime().valueOf()).to.deep.equal minMinute.valueOf()

  describe '->getSecondsList', ->
    describe 'when using intervalTime', ->
      describe 'when set to every 1000', ->
        describe 'when the processAt is the timestamp', ->
          beforeEach ->
            @secondsList = @sut.getSecondsList { intervalTime: 1000, processAt: @sut.getCurrentTime().unix() }

          it 'should have a length of 60', ->
            expect(@secondsList.length).to.equal 60

          it 'should have all 60 seconds in the list', ->
            _.times 60, (n) =>
              expect(@secondsList).to.include @sut.getCurrentTime().unix() + n

        describe 'when the processAt is 5 seconds in the future', ->
          beforeEach ->
            @secondsList = @sut.getSecondsList { intervalTime: 1000, processAt: @sut.getCurrentTime().add(5, 'seconds').unix() }

          it 'should have a length of 55', ->
            expect(@secondsList.length).to.equal 55

          it 'should have all 55 seconds in the list', ->
            _.times 55, (n) =>
              expect(@secondsList).to.include @sut.getCurrentTime().add(5, 'seconds').unix() + n

        describe 'when the processAt is 5 seconds in the past', ->
          beforeEach ->
            @secondsList = @sut.getSecondsList { intervalTime: 1000, processAt: @sut.getCurrentTime().subtract(5, 'seconds').unix() }

          it 'should have a length of 55', ->
            expect(@secondsList.length).to.equal 55

          it 'should have 55 seconds in the list', ->
            _.times 55, (n) =>
              expect(@secondsList).to.include @sut.getCurrentTime().unix() + n

      describe 'when set to every 1499', ->
        beforeEach ->
          @secondsList = @sut.getSecondsList { intervalTime: 1499, processAt: @sut.getCurrentTime().unix() }

        it 'should have a length of 60', ->
          expect(@secondsList.length).to.equal 60

        it 'should have all 60 seconds in the list', ->
          _.times 60, (n) =>
            expect(@secondsList).to.include @sut.getCurrentTime().unix() + n

      describe 'when set to every 2000', ->
        beforeEach ->
          @secondsList = @sut.getSecondsList { intervalTime: 2000, processAt: @sut.getCurrentTime().unix() }

        it 'should have a length of 30', ->
          expect(@secondsList.length).to.equal 30

        it 'should have 30 seconds in the list', ->
          _.times 30, (n) =>
            expect(@secondsList).to.include @sut.getCurrentTime().unix() + (n * 2)

      describe 'when set to every 1500', ->
        beforeEach ->
          @secondsList = @sut.getSecondsList { intervalTime: 1500, processAt: @sut.getCurrentTime().unix() }

        it 'should have a length of 30', ->
          expect(@secondsList.length).to.equal 30

        it 'should have 30 seconds in the list', ->
          _.times 30, (n) =>
            expect(@secondsList).to.include @sut.getCurrentTime().unix() + (n * 2)

      describe 'when set to every 30 seconds', ->
        beforeEach ->
          @secondsList = @sut.getSecondsList { intervalTime: 30000, processAt: @sut.getCurrentTime().unix() }

        it 'should have a length of 2', ->
          expect(@secondsList.length).to.equal 2

        it 'should have 30 seconds in the list', ->
          _.times 2, (n) =>
            expect(@secondsList).to.include @sut.getCurrentTime().unix() + (n * 30)

      describe 'when set to every 10 minutes and should not be processed', ->
        beforeEach ->
          processAt = @sut.getCurrentTime().add(2, 'minutes').unix()
          @secondsList = @sut.getSecondsList { intervalTime: (10 * 60 * 1000), processAt }

        it 'should have a length of 0', ->
          expect(@secondsList.length).to.equal 0

      describe 'when set to every 10 minutes and should be processed', ->
        beforeEach ->
          @secondsList = @sut.getSecondsList { intervalTime: (10 * 60 * 1000), processAt: @sut.getCurrentTime().unix() }

        it 'should have second for the processAt', ->

          expect(@secondsList).to.deep.equal [@sut.getCurrentTime().unix()]

        it 'should have a length of 1', ->
          expect(@secondsList.length).to.equal 1

    describe 'when using cron', ->
      describe 'when set every second', ->
        beforeEach ->
          @secondsList = @sut.getSecondsList { cronString: '* * * * * *' }

        it 'should have 60 seconds in the list', ->
          baseTime = moment.unix(_.ceil(@sut.getCurrentTime().unix(), 0))
          _.times 60, (n) =>
            expect(@secondsList).to.include baseTime.unix()
            baseTime = baseTime.add 1, 'seconds'

        it 'should have a length of 60', ->
          expect(@secondsList.length).to.equal 60

      describe 'when set every 10 seconds', ->
        beforeEach ->
          @secondsList = @sut.getSecondsList { cronString: '*/10 * * * * *' }

        it 'should have 6 seconds in the list', ->
          baseTime = moment.unix(_.ceil(@sut.getCurrentTime().unix(), -1))
          _.times 6, (n) =>
            expect(@secondsList).to.include baseTime.unix()
            baseTime = baseTime.add 10, 'seconds'

        it 'should have a length of 6', ->
          expect(@secondsList.length).to.equal 6

      describe 'when set every minute', ->
        describe 'when it is in the range', ->
          beforeEach ->
            @secondsList = new TimeParser({ timestamp: 1478022657 }).getSecondsList { cronString: '* * * * *' }

          it 'should have the correct second in the list', ->
            expect(@secondsList).to.deep.equal [1478022720]

          it 'should have a length of 1', ->
            expect(@secondsList.length).to.equal 1

      describe 'when set every 10 minute', ->
        describe 'when it is in the range', ->
          beforeEach ->
            @secondsList = new TimeParser({ timestamp: 1478023100 }).getSecondsList { cronString: '*/10 * * * *' }

          it 'should have the correct second in the list', ->
            expect(@secondsList).to.deep.equal [1478023200]

          it 'should have a length of 1', ->
            expect(@secondsList.length).to.equal 1

        describe 'when it is not in the range', ->
          beforeEach ->
            @secondsList = new TimeParser({ timestamp: 1478022657 }).getSecondsList { cronString: '*/10 * * * *' }

          it 'should have a length of 0', ->
            expect(@secondsList.length).to.equal 0

  describe '->getNextProcessAt', ->
    describe 'when using intervalTime', ->
      describe 'when set to 1 second', ->
        beforeEach ->
          @currentProcessAt = @sut.getCurrentTime().add(30, 'seconds')
          @nextProcessAt = @sut.getNextProcessAt { processAt: @currentProcessAt.unix(), intervalTime: 1000 }

        it 'should have the correct nextProcessAt', ->
          expect(@nextProcessAt).to.equal @currentProcessAt.add(1, 'minute').add(1, 'seconds').unix()

      describe 'when set to 2 second', ->
        beforeEach ->
          @currentProcessAt = @sut.getCurrentTime().add(30, 'seconds')
          @nextProcessAt = @sut.getNextProcessAt { processAt: @currentProcessAt.unix(), intervalTime: 2 * 1000 }

        it 'should have the correct nextProcessAt', ->
          expect(@nextProcessAt).to.equal @currentProcessAt.add(1, 'minute').add(2, 'seconds').unix()

      describe 'when set to 30 second', ->
        beforeEach ->
          @currentProcessAt = @sut.getCurrentTime().add(30, 'seconds')
          @nextProcessAt = @sut.getNextProcessAt { processAt: @currentProcessAt.unix(), intervalTime: 30 * 1000 }

        it 'should have the correct nextProcessAt', ->
          expect(@nextProcessAt).to.equal @currentProcessAt.add(1, 'minute').add(30, 'seconds').unix()

      describe 'when set to 1 minute', ->
        beforeEach ->
          @currentProcessAt = @sut.getCurrentTime().add(30, 'seconds')
          @nextProcessAt = @sut.getNextProcessAt { processAt: @currentProcessAt.unix(), intervalTime: 60 * 1000 }

        it 'should have the correct nextProcessAt', ->
          expect(@nextProcessAt).to.equal @currentProcessAt.add(1, 'minute').add(1, 'minute').unix()

      describe 'when set to 10 minute', ->
        beforeEach ->
          @currentProcessAt = @sut.getCurrentTime().add(30, 'seconds')
          @nextProcessAt = @sut.getNextProcessAt { processAt: @currentProcessAt.unix(), intervalTime: 10 * 60 * 1000 }

        it 'should have the correct nextProcessAt', ->
          expect(@nextProcessAt).to.equal @currentProcessAt.add(1, 'minute').add(10, 'minute').unix()

    describe 'when using cronString', ->
      describe 'when set to 1 second', ->
        beforeEach ->
          @nextProcessAt = @sut.getNextProcessAt { cronString: '* * * * * *' }

        it 'should have the correct nextProcessAt', ->
          expect(@nextProcessAt).to.equal @sut.getCurrentTime().add(1, 'minute').add(1, 'seconds').unix()

      describe 'when set to 2 second', ->
        beforeEach ->
          @nextProcessAt = @sut.getNextProcessAt { cronString: '*/2 * * * * *' }

        it 'should have the correct nextProcessAt', ->
          expect(@nextProcessAt).to.equal @sut.getCurrentTime().add(1, 'minute').add(2, 'seconds').unix()

      describe 'when set to 30 second', ->
        beforeEach ->
          @nextProcessAt = @sut.getNextProcessAt { cronString: '*/30 * * * * *' }

        it 'should have the correct nextProcessAt', ->
          expect(@nextProcessAt).to.equal @sut.getCurrentTime().add(1, 'minute').add(30, 'seconds').unix()

      describe 'when set to 1 minute', ->
        beforeEach ->
          @nextProcessAt = @sut.getNextProcessAt { cronString: '* * * * *' }

        it 'should have the correct nextProcessAt', ->
          expect(@nextProcessAt).to.equal @sut.getCurrentTime().add(1, 'minute').add(1, 'minute').unix()

      describe 'when set to 10 minute', ->
        beforeEach ->
          @nextProcessAt = @sut.getNextProcessAt { cronString: '*/10 * * * *' }

        it 'should have the correct nextProcessAt', ->
          expect(@nextProcessAt).to.equal @sut.getCurrentTime().add(1, 'minute').add(10, 'minute').unix()
