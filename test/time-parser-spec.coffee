_          = require 'lodash'
TimeParser = require '../src/time-parser'
moment     = require 'moment'

describe.only 'TimeParser', ->
  describe 'no timestamp', ->
    beforeEach ->
      @timestamp = moment().unix()
      @sut = new TimeParser { @timestamp }

    it 'should throw an error', ->
      expect(() =>
        new TimeParser {}
      ).to.throw

  describe 'fixed timestamp', ->
    beforeEach ->
      @sut = new TimeParser { timestamp: 1478033340 }

    describe '->getCurrentTime', ->
      it 'should be set to the next minute', ->
        console.log @sut.getCurrentTime().unix()
        nextMinute = moment.unix(1478033340).add(1, 'minute')
        expect(@sut.getCurrentTime().valueOf()).to.deep.equal nextMinute.valueOf()

    describe '->getMaxRangeTime', ->
      it 'should be set to the next minute after the currentTime', ->
        maxMinute = moment.unix(1478033340).add(2, 'minute')
        expect(@sut.getMaxRangeTime().valueOf()).to.deep.equal maxMinute.valueOf()

    describe '->getMinRangeTime', ->
      it 'should be set to the same minute as the currentTime', ->
        minMinute = moment.unix(1478033340).add(1, 'minute')
        expect(@sut.getMinRangeTime().valueOf()).to.deep.equal minMinute.valueOf()

    describe '->getSecondsList', ->
      describe 'when using intervalTime', ->
        describe 'when set to every 1000', ->
          describe 'when the processAt is the timestamp', ->
            beforeEach ->
              @secondsList = @sut.getSecondsList { intervalTime: 1000, processAt: 1478033400 }

            it 'should have all 60 seconds in the list', ->
              _.times 60, (n) =>
                expect(@secondsList).to.include 1478033400 + n

          describe 'when the processAt is 5 seconds in the future', ->
            beforeEach ->
              @secondsList = @sut.getSecondsList { intervalTime: 1000, processAt: 1478033405 }

            it 'should have all 55 seconds in the list', ->
              seconds = _.times 55, (n) => 1478033405 + n
              expect(@secondsList).to.deep.equal seconds

          describe 'when the processAt is 5 seconds in the past', ->
            beforeEach ->
              @secondsList = @sut.getSecondsList { intervalTime: 1000, processAt: 1478033395 }

            it 'should have 55 seconds in the list', ->
              seconds = _.times 55, (n) => 1478033400 + n
              expect(@secondsList).to.deep.equal seconds

        describe 'when set to every 1499', ->
          beforeEach ->
            @secondsList = @sut.getSecondsList { intervalTime: 1499, processAt: 1478033400 }

          it 'should have all 60 seconds in the list', ->
            seconds = _.times 60, (n) => 1478033400 + n
            expect(@secondsList).to.deep.equal seconds

        describe 'when set to every 2000', ->
          beforeEach ->
            @secondsList = @sut.getSecondsList { intervalTime: 2000, processAt: 1478033400 }

          it 'should have 30 seconds in the list', ->
            seconds = _.times 30, (n) => 1478033400 + (n * 2)
            expect(@secondsList).to.deep.equal seconds

        describe 'when set to every 1500', ->
          beforeEach ->
            @secondsList = @sut.getSecondsList { intervalTime: 1500, processAt: 1478033400 }

          it 'should have 30 seconds in the list', ->
            seconds = _.times 30, (n) => 1478033400 + (n * 2)
            expect(@secondsList).to.deep.equal seconds

        describe 'when set to every 30 seconds', ->
          beforeEach ->
            @secondsList = @sut.getSecondsList { intervalTime: 30000, processAt: 1478033400 }

          it 'should have 30 seconds in the list', ->
            expect(@secondsList).to.deep.equal [1478033400, 1478033430]

        describe 'when set to every 10 minutes and should not be processed', ->
          beforeEach ->
            processAt = @sut.getCurrentTime().add(2, 'minutes').unix()
            @secondsList = @sut.getSecondsList { intervalTime: (10 * 60 * 1000), processAt }

          it 'should have a length of 0', ->
            expect(@secondsList.length).to.equal 0

        describe 'when set to every 10 minutes and should be processed', ->
          beforeEach ->
            @secondsList = @sut.getSecondsList { intervalTime: (10 * 60 * 1000), processAt: 1478033400 }

          it 'should have second for the processAt', ->
            expect(@secondsList).to.deep.equal [1478033400]

      describe 'when using cron', ->
        describe 'when set every second', ->
          beforeEach ->
            @secondsList = @sut.getSecondsList { cronString: '* * * * * *' }

          it 'should have 60 seconds in the list', ->
            seconds = _.times 60, (n) => 1478033400 + n
            expect(@secondsList).to.deep.equal seconds

        describe 'when set every 10 seconds', ->
          beforeEach ->
            @secondsList = @sut.getSecondsList { cronString: '*/10 * * * * *' }

          it 'should have 6 seconds in the list', ->
            expect(@secondsList).to.deep.equal [
              1478033400,
              1478033410,
              1478033420,
              1478033430,
              1478033440,
              1478033450,
            ]

        describe 'when set every minute', ->
          beforeEach ->
            @secondsList = @sut.getSecondsList { cronString: '* * * * *' }

          it 'should have the correct second in the list', ->
            expect(@secondsList).to.deep.equal [1478033400]

        describe 'when set every 10 minute', ->
          beforeEach ->
            @secondsList = @sut.getSecondsList { cronString: '*/10 * * * *' }

          it 'should have the correct second in the list', ->
            expect(@secondsList).to.deep.equal [1478033400]

    describe '->getNextProcessAt', ->
      describe 'when using intervalTime', ->
        describe 'when set to 1 second', ->
          beforeEach ->
            @currentProcessAt = @sut.getCurrentTime().add(30, 'seconds')
            @nextProcessAt = @sut.getNextProcessAt { processAt: @currentProcessAt.unix(), intervalTime: 1000 }

          it 'should have the correct nextProcessAt', ->
            expect(@nextProcessAt).to.equal 1478033491

        describe 'when set to 2 second', ->
          beforeEach ->
            @currentProcessAt = @sut.getCurrentTime().add(30, 'seconds')
            @nextProcessAt = @sut.getNextProcessAt { processAt: @currentProcessAt.unix(), intervalTime: 2 * 1000 }

          it 'should have the correct nextProcessAt', ->
            expect(@nextProcessAt).to.equal 1478033492

        describe 'when set to 30 second', ->
          beforeEach ->
            @currentProcessAt = @sut.getCurrentTime().add(30, 'seconds')
            @nextProcessAt = @sut.getNextProcessAt { processAt: @currentProcessAt.unix(), intervalTime: 30 * 1000 }

          it 'should have the correct nextProcessAt', ->
            expect(@nextProcessAt).to.equal 1478033520

        describe 'when set to 1 minute', ->
          beforeEach ->
            @currentProcessAt = @sut.getCurrentTime().add(30, 'seconds')
            @nextProcessAt = @sut.getNextProcessAt { processAt: @currentProcessAt.unix(), intervalTime: 60 * 1000 }

          it 'should have the correct nextProcessAt', ->
            expect(@nextProcessAt).to.equal 1478033550

        describe 'when set to 10 minute', ->
          beforeEach ->
            @currentProcessAt = @sut.getCurrentTime().add(30, 'seconds')
            @nextProcessAt = @sut.getNextProcessAt { processAt: @currentProcessAt.unix(), intervalTime: 10 * 60 * 1000 }

          it 'should have the correct nextProcessAt', ->
            expect(@nextProcessAt).to.equal 1478034090

      describe 'when using cronString', ->
        beforeEach ->
          @baseTime = @sut.getCurrentTime().add(1, 'minute')

        describe 'when set to 1 second', ->
          beforeEach ->
            @nextProcessAt = @sut.getNextProcessAt { cronString: '* * * * * *' }

          it 'should have the correct nextProcessAt', ->
            expect(@nextProcessAt).to.equal 1478033461

        describe 'when set to 2 second', ->
          beforeEach ->
            @nextProcessAt = @sut.getNextProcessAt { cronString: '*/2 * * * * *' }

          it 'should have the correct nextProcessAt', ->
            expect(@nextProcessAt).to.equal 1478033462

        describe 'when set to 30 second', ->
          beforeEach ->
            @nextProcessAt = @sut.getNextProcessAt { cronString: '*/30 * * * * *' }

          it 'should have the correct nextProcessAt', ->
            expect(@nextProcessAt).to.equal 1478033490

        describe 'when set to 1 minute', ->
          beforeEach ->
            @nextProcessAt = @sut.getNextProcessAt { cronString: '* * * * *' }

          it 'should have the correct nextProcessAt', ->
            expect(@nextProcessAt).to.equal 1478033520

        describe 'when set to 10 minute', ->
          beforeEach ->
            @nextProcessAt = @sut.getNextProcessAt { cronString: '*/10 * * * *' }

          it 'should have the correct nextProcessAt', ->
            expect(@nextProcessAt).to.equal 1478034000
