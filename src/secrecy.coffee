class Secrecy
  constructor: ({ database }) ->
    @collection = database.collection 'secrecy'

  get: ({ uuid, nodeId }, callback) =>
    @collection.findOne { uuid, nodeId }, callback

module.exports = Secrecy
