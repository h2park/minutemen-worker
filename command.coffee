_              = require 'lodash'
chalk          = require 'chalk'
dashdash       = require 'dashdash'
Redis          = require 'ioredis'
mongojs        = require 'mongojs'
RedisNS        = require '@octoblu/redis-ns'
Worker         = require './src/worker'
SigtermHandler = require 'sigterm-handler'

packageJSON    = require './package.json'

OPTIONS = [
  {
    names: ['redis-uri', 'r']
    type: 'string'
    env: 'REDIS_URI'
    help: 'Redis URI'
  },
  {
    names: ['redis-namespace', 'n']
    type: 'string'
    env: 'REDIS_NAMESPACE'
    help: 'Redis namespace for redis-ns'
  },
  {
    names: ['queue-name', 'q']
    type: 'string'
    env: 'QUEUE_NAME'
    help: 'Name of Redis work queue'
  },
  {
    names: ['timestamp-redis-key', 't']
    type: 'string'
    env: 'TIMESTAMP_REDIS_KEY'
    default: 'timestamp'
    help: 'The redis key for the timestamp'
  },
  {
    names: ['mongodb-uri']
    type: 'string'
    env: 'MONGODB_URI'
    help: 'MongoDB connection URI'
  },
  {
    names: ['help', 'h']
    type: 'bool'
    help: 'Print this help and exit.'
  },
  {
    names: ['version', 'v']
    type: 'bool'
    help: 'Print the version and exit.'
  }
]

class Command
  constructor: ->
    process.on 'uncaughtException', @die
    @parser = dashdash.createParser({options: OPTIONS})
    options = @parseOptions()
    @redisUri = options.redis_uri
    @redisNamespace = options.redis_namespace
    @queueName = options.queue_name
    @mongoDBUri = options.mongodb_uri
    @timestampRedisKey = options.timestamp_redis_key
    @validateOptions()

  printHelp: =>
    options = { includeEnv: true, includeDefaults:true }
    console.log "usage: minute-man-worker [OPTIONS]\noptions:\n#{@parser.help(options)}"

  parseOptions: =>
    options = @parser.parse(process.argv)

    if options.help
      @printHelp()
      process.exit 0

    if options.version
      console.log packageJSON.version
      process.exit 0

    return options

  validateOptions: =>
    return if @redisUri? && @redisNamespace? && @queueName? && @timestampRedisKey? && @mongoDBUri?
    @printHelp()
    console.error chalk.red 'Missing required parameter --redis-uri, -r, or env: REDIS_URI' unless @redisUri?
    console.error chalk.red 'Missing required parameter --redis-namespace, -n, or env: REDIS_NAMESPACE' unless @redisNamespace?
    console.error chalk.red 'Missing required parameter --queue-name, -q, or env: QUEUE_NAME' unless @queueName?
    console.error chalk.red 'Missing required parameter --timestamp-redis-key, -t, or env: TIMESTAMP_REDIS_KEY' unless @timestampRedisKey?
    console.error chalk.red 'Missing required parameter --mongodb-uri, or env: MONGODB_URI' unless @mongoDBUri?
    process.exit 1

  run: =>
    @getDatabaseClient (error, database) =>
      return @die error if error?
      @getWorkerClient (error, client) =>
        return @die error if error?

        worker = new Worker { client, database, @queueName, @timestampRedisKey }
        worker.run @die

        sigtermHandler = new SigtermHandler { events: ['SIGINT', 'SIGTERM']}
        sigtermHandler.register worker.stop

  getDatabaseClient: (callback) =>
    database = mongojs @mongoDBUri
    database.runCommand {ping: 1}, (error) =>
      return callback error if error?

      setInterval =>
        @database.runCommand {ping: 1}, @die
      , (10 * 1000)

      callback null, database

  getWorkerClient: (callback) =>
    @getRedisClient @redisUri, (error, client) =>
      return callback error if error?
      clientNS  = new RedisNS @redisNamespace, client
      callback null, clientNS

  getRedisClient: (redisUri, callback) =>
    callback = _.once callback
    client = new Redis redisUri, dropBufferSupport: true
    client.once 'ready', =>
      client.on 'error', @die
      callback null, client

    client.once 'error', callback

  die: (error) =>
    return process.exit(0) unless error?
    console.error 'ERROR'
    console.error error.stack
    process.exit 1

module.exports = Command
