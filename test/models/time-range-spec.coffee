_         = require 'lodash'
TimeRange = require '../../src/models/time-range'
moment    = require 'moment'

describe 'TimeRange', ->
  describe 'no timestamp', ->
    it 'should throw an error', ->
      expect(() =>
        new TimeRange {}
      ).to.throw

  describe 'fixed timestamp', ->
    beforeEach ->
      @sut = new TimeRange { timestamp: 1478033340 }

    describe '->current', ->
      it 'should be set the current time', ->
        expect(@sut.current().valueOf()).to.equal moment.unix(1478033340).valueOf()

    describe '->max', ->
      it 'should be set to the next minute after the currentTime', ->
        maxMinute = moment.unix(1478033340).add(1, 'minute')
        expect(@sut.max().valueOf()).to.equal maxMinute.valueOf()

    describe '->min', ->
      it 'should be set to the same minute as the currentTime', ->
        minMinute = moment.unix(1478033340)
        expect(@sut.min().valueOf()).to.equal minMinute.valueOf()

    describe '->offset', ->
      it 'should be set to 60 seconds', ->
        expect(@sut.offset()).to.equal 60

    describe '->sampleSize', ->
      it 'should be set to 120 seconds', ->
        expect(@sut.sampleSize()).to.equal 120
