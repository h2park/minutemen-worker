class Intervals
  constructor: ({ database }) ->
    throw new Error 'Intervals: requires database' unless database?
    @collection = database.collection 'intervals'
    @totalProcessed = 0

  getBatch: (callback) =>
    @collection
      .find()
      .sort({_id: -1})
      .limit(10)
      .skip(@totalProcessed)
      .toArray (error, records) =>
        return callback error if error?
        @totalProcessed += records.length
        callback null, records

module.exports = Intervals
