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
        beforeEach ->
          @secondsList = @sut.getSecondsList { cronString: '* * * * *' }

        it 'should have a length of 1', ->
          expect(@secondsList.length).to.equal 1

        it 'should have 1 seconds in the list', ->
          baseTime = @sut.getCurrentTime().startOf('minute')
          baseTime = baseTime.add 60, 'seconds'
          expect(@secondsList).to.include baseTime.unix()

      describe 'when set every 10 minute', ->
        beforeEach ->
          @secondsList = @sut.getSecondsList { cronString: '*/10 * * * *' }

        it 'should have a length of 0', ->
          expect(@secondsList.length).to.equal 0
