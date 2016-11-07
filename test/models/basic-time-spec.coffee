_             = require 'lodash'
TimeGenerator = require '../../src/models/time-generator'
TimeRange     = require '../../src/models/time-range'
moment        = require 'moment'

describe 'Basic Time', ->
  beforeEach ->
    timeRange = new TimeRange { timestamp: 100 }
    @sut = new TimeGenerator { timeRange, intervalTime: 1000, processAt: 100 }

  describe 'when it gets the current seconds', ->
    it 'should have a list of the seconds 100-159', ->
      expect(@sut.getCurrentSeconds()).to.deep.equal _.range(100, 160)

    it 'should set the processAt to 160', ->
      expect(@sut.getNextSecond()).to.equal 160

    describe 'when processed again', ->
      beforeEach ->
        timeRange = new TimeRange { timestamp: 160 }
        @sut = new TimeGenerator { timeRange, intervalTime: 1000, processAt: 160 }

      it 'should have a list of the seconds 160-219', ->
        expect(@sut.getCurrentSeconds()).to.deep.equal _.range(160, 220)

      it 'should set the processAt to 220', ->
        expect(@sut.getNextSecond()).to.equal 220
