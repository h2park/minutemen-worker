_             = require 'lodash'
TimeGenerator = require '../../src/models/time-generator'
TimeRange     = require '../../src/models/time-range'
moment        = require 'moment'

describe 'Simple Time Example', ->
  describe 'when every second', ->
    beforeEach ->
      timeRange = new TimeRange { timestamp: 0, offsetSeconds: 60, processNow: true }
      sut = new TimeGenerator({ timeRange, intervalTime: 1000 })
      @secondsList = sut.getIntervalsForTimeRange()

      timeRange = new TimeRange {
        timestamp: sut.getNextProcessAt(),
        offsetSeconds: 60,
        lastRunAt: _.last(@secondsList)
      }
      seconds = new TimeGenerator({ timeRange, intervalTime: 1000 }).getIntervalsForTimeRange()
      @secondsList = _.union @secondsList, seconds

    it 'should have the correct seconds list', ->
      expect(@secondsList).to.deep.equal _.range 0, 180

  describe 'when every minute', ->
    beforeEach ->
      timeRange = new TimeRange { timestamp: 0, offsetSeconds: 60, processNow: true }
      sut = new TimeGenerator({ timeRange, intervalTime: 60000 })
      @secondsList = sut.getIntervalsForTimeRange()
      _.times 10, (n) =>
        timeRange = new TimeRange {
          timestamp: sut.getNextProcessAt(),
          offsetSeconds: 60,
          lastRunAt: _.last(@secondsList)
        }
        sut = new TimeGenerator({ timeRange, intervalTime: 60000 })
        seconds = sut.getIntervalsForTimeRange()
        @secondsList = _.union @secondsList, seconds

    it 'should have the correct seconds list', ->
      expect(@secondsList).to.deep.equal [
        0
        60
        120
        180
        240
        300
        360
        420
        480
        540
        600
        660
      ]
