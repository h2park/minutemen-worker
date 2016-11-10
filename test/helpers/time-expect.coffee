_      = require 'lodash'
moment = require 'moment'

class TimeExpect
  shouldBeAtLeast: (key, actual, expected) =>
    offBy = actual.unix() - expected.unix()
    message = "expected #{key} (#{actual.unix()}) to be greater than #{expected.unix()} #{@offBy(actual, expected)}"
    assert.isAtLeast actual.unix(), expected.unix(), message

  shouldEqual: (key, actual, expected) =>
    offBy = actual.unix() - expected.unix()
    message = "expected #{key} (#{actual.unix()}) to equal #{expected.unix()} #{@offBy(actual, expected)}"
    assert.equal actual.unix(), expected.unix(), message

  shouldNotEqual: (key, actual, expected) =>
    message = "expected #{key} (#{actual.unix()}) to not equal #{expected.unix()} #{@offBy(actual, expected)}"
    assert.notEqual actual.unix(), expected.unix(), message

  shouldMatchMembers: (key, actual, expected) =>
    _.each expected, (second) =>
      @shouldInclude key, actual, moment.unix(second)

  shouldNotContainMembers: (key, actual, expected) =>
    _.each expected, (second) =>
      @shouldNotInclude key, actual, moment.unix(second)

  shouldInclude: (key, list, time) =>
    assert.include(list, time.unix(), "expected #{key} to include #{time.unix()} (#{time.toString()})")

  shouldNotInclude: (key, list, time) =>
    assert.include(list, time.unix(), "expected #{key} to not include #{time.unix()} (#{time.toString()})")

  offBy: (actual, expected) =>
    offBy = actual.unix() - expected.unix()
    return  "[#{offBy} seconds]"

module.exports = new TimeExpect
