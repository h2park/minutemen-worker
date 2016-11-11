class LegacyRedis
  constructor: ({ @client }) ->
    throw new Error 'LegacyRedis: requires client' unless @client?

  disable: ({ sendTo, nodeId, transactionId }, callback) =>
    redisNodeId = transactionId ? nodeId
    @client.del "interval/active/#{sendTo}/#{redisNodeId}", callback

  enable: ({ sendTo, nodeId, transactionId }, callback) =>
    redisNodeId = transactionId ? nodeId
    @client.set "interval/active/#{sendTo}/#{redisNodeId}", "true", callback

module.exports = LegacyRedis
