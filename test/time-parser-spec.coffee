_          = require 'lodash'
TimeParser = require '../src/time-parser'
moment     = require 'moment'

describe.only 'TimeParser', ->
  describe 'no timestamp', ->
    it 'should throw an error', ->
      expect(() =>
        new TimeParser {}
      ).to.throw

  describe 'current timestamp', ->
    beforeEach ->
      @timestamp = moment().unix()
      @sut = new TimeParser { @timestamp }

    describe '->getCurrentTime', ->
      it 'should be set to the next minute', ->
        nextMinute = moment.unix(@timestamp).add(1, 'minute')
        expect(@sut.getCurrentTime().valueOf()).to.deep.equal nextMinute.valueOf()

    describe '->getMaxRangeTime', ->
      it 'should be set to the next minute after the currentTime', ->
        maxMinute = moment.unix(@timestamp).add(2, 'minute')
        expect(@sut.getMaxRangeTime()).to.deep.equal maxMinute.unix()

    describe '->getMinRangeTime', ->
      it 'should be set to the same minute as the currentTime', ->
        minMinute = moment.unix(@timestamp).add(1, 'minute')
        expect(@sut.getMinRangeTime()).to.deep.equal minMinute.unix()

    describe '->getSecondsList', ->
      describe 'when the intervalTime is 1000', ->
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

      describe 'when the intervalTime is 1499', ->
        beforeEach ->
          @secondsList = @sut.getSecondsList { intervalTime: 1499, processAt: @sut.getCurrentTime().unix() }

        it 'should have a length of 60', ->
          expect(@secondsList.length).to.equal 60

        it 'should have all 60 seconds in the list', ->
          _.times 60, (n) =>
            expect(@secondsList).to.include @sut.getCurrentTime().unix() + n

      describe 'when the intervalTime is 2000', ->
        beforeEach ->
          @secondsList = @sut.getSecondsList { intervalTime: 2000, processAt: @sut.getCurrentTime().unix() }

        it 'should have a length of 30', ->
          expect(@secondsList.length).to.equal 30

        it 'should have 30 seconds in the list', ->
          _.times 30, (n) =>
            expect(@secondsList).to.include @sut.getCurrentTime().unix() + (n * 2)

      describe 'when the intervalTime is 1500', ->
        beforeEach ->
          @secondsList = @sut.getSecondsList { intervalTime: 1500, processAt: @sut.getCurrentTime().unix() }

        it 'should have a length of 30', ->
          expect(@secondsList.length).to.equal 30

        it 'should have 30 seconds in the list', ->
          _.times 30, (n) =>
            expect(@secondsList).to.include @sut.getCurrentTime().unix() + (n * 2)

      describe 'when the cronString is every second', ->
        beforeEach ->
          @secondsList = @sut.getSecondsList { cronString: '* * * * * *' }

        it 'should have 60 seconds in the list', ->
          baseTime = @sut.getCurrentTime()
          _.times 60, (n) =>
            expect(@secondsList).to.include baseTime.unix() + n

        it 'should have a length of 60', ->
          expect(@secondsList.length).to.equal 60

      describe 'when the cronString is every 10 seconds', ->
        beforeEach ->
          @secondsList = @sut.getSecondsList { cronString: '*/10 * * * * *' }

        it 'should have 6 seconds in the list', ->
          baseTime = @sut.getCurrentTime()
          _.times 6, (n) =>
            roundedTime = _.ceil baseTime.unix(), -1
            expect(@secondsList).to.include roundedTime + (n * 10)

        it 'should have a length of 6', ->
          expect(@secondsList.length).to.equal 6

      describe 'when the cronString is every minute', ->
        beforeEach ->
          @secondsList = @sut.getSecondsList { cronString: '* * * * *' }

        it 'should have a length of 1', ->
          expect(@secondsList.length).to.equal 1

        it 'should have 1 seconds in the list', ->
          roundedTime = _.ceil @sut.getCurrentTime().seconds(0).unix(), -1
          expect(@secondsList).to.include roundedTime
