_        = require 'lodash'
mongojs  = require 'mongojs'
program  = require 'commander'
Redis    = require 'ioredis'
Transfer = require './src/transfer'

program
  .version '1.0.0'
  .usage '[options]'
  .option '-m, --mongodb-uri <string>', 'MongoDB URI'
  .option '-r, --redis-uri <string>', 'Redis URI'
  .option '-l, --limit <integer>', 'Limit number of records processed'
  .option '-s, --skip <integer>', 'Skip of number of records to be processed'
  .option '-f, --flow-id <string>', 'Migrate just one flow'

class IntervalToMinutemen
  constructor: (argv) ->
    process.on 'uncaughtException', @die
    program.parse argv
    { @mongodbUri, @redisUri, @limit, @skip, @flowId } = @getOptions()

  getOptions: =>
    { mongodbUri, redisUri, limit, skip, flowId } = program
    @dieHelp new Error 'Missing MongoDB URI' unless mongodbUri?
    @dieHelp new Error 'Missing Redis URI' unless redisUri?
    limit = parseInt(limit) if limit?
    skip = parseInt(skip) if skip?
    skip ?= 0
    limit ?= 10
    return { mongodbUri, redisUri, limit, skip, flowId }

  run: =>
    database = mongojs @mongodbUri
    database.runCommand {ping: 1}, (error) =>
      return @die error if error?
      client = new Redis @redisUri, dropBufferSupport: true
      client = _.bindAll client, _.functionsIn(client)
      client.on 'error', @die
      client.on 'ready', =>
        transfer = new Transfer { database, client, @limit, @skip, @flowId }
        transfer.setup (error) =>
          return @die error if error?
          transfer.processAll @die

  dieHelp: (error) =>
    program.outputHelp()
    return @die error

  die: (error) =>
    return process.exit(0) unless error?
    console.error error.stack
    process.exit 1

module.exports = IntervalToMinutemen
