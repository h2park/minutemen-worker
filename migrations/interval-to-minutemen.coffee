mongojs  = require 'mongojs'
program  = require 'commander'
Transfer = require './src/transfer'

program
  .version '1.0.0'
  .usage '[options]'
  .option '-m, --mongodb-uri <string>', 'MongoDB URI'

class IntervalToMinutemen
  constructor: (argv) ->
    process.on 'uncaughtException', @die
    program.parse argv
    { @mongodbUri } = @getOptions()

  getOptions: =>
    { mongodbUri } = program
    @dieHelp new Error 'Missing MongoDB URI' unless mongodbUri?
    return { mongodbUri }

  run: =>
    database = mongojs @mongodbUri
    database.runCommand {ping: 1}, (error) =>
      return @die error if error?
      transfer = new Transfer { database }
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
