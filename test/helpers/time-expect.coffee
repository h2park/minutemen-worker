class TimeExpect
  shouldBeGreaterThan: (key, actual, expected) =>
    return if actual.unix() <= expected.unix()
    offBy = actual.unix() - expected.unix()
    message = "expected #{key} (#{actual.unix()}) to be greater than #{expected.unix()} #{@offBy(actual, expected)}"
    assert.fail actual.unix(), expected.unix(), message

  shouldEqual: (key, actual, expected) =>
    return if actual.unix() == expected.unix()
    offBy = actual.unix() - expected.unix()
    message = "expected #{key} (#{actual.unix()}) to equal #{expected.unix()} #{@offBy(actual, expected)}"
    assert.fail actual.unix(), expected.unix(), message

  shouldNotEqual: (key, actual, expected) =>
    return unless actual.unix() == expected.unix()
    message = "expected #{key} (#{actual.unix()}) to not equal #{expected.unix()} #{@offBy(actual, expected)}"
    assert.fail actual.unix(), expected.unix(), message

  shouldInclude: (key, list, time) =>
    return if time.unix() in list
    assert.fail(list, time.unix(), "expected #{key} to include #{time.unix()} (#{time.toString()})")

  shouldNotInclude: (key, list, time) =>
    return unless time.unix() in list
    assert.fail(list, time.unix(), "expected #{key} to not include #{time.unix()} (#{time.toString()})")

  offBy: (actual, expected) =>
    offBy = actual.unix() - expected.unix()
    return  "[#{offBy} seconds]"

module.exports = new TimeExpect
