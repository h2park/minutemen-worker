class LegacyRedis
  constructor: ({ @client }) ->
    throw new Error 'LegacyRedis: requires client' unless @client?

  disable: ({ ownerId, nodeId, data }, callback) =>
    { transactionId } = data ? {}
    redisNodeId = transactionId ? nodeId
    console.log 'disable old', {redisNodeId,ownerId}
    throw new Error 'LegacyRedis.disable: requires redisNodeId' unless redisNodeId?
    throw new Error 'LegacyRedis.disable: requires ownerId' unless ownerId?
    @client.del "interval/active/#{ownerId}/#{redisNodeId}", callback

  enable: ({ ownerId, nodeId, data }, callback) =>
    { transactionId } = data ? {}
    redisNodeId = transactionId ? nodeId
    console.log 'enable old', {redisNodeId,ownerId}
    throw new Error 'LegacyRedis.enable: requires redisNodeId' unless redisNodeId?
    throw new Error 'LegacyRedis.enable: requires ownerId' unless ownerId?
    @client.set "interval/active/#{ownerId}/#{redisNodeId}", "true", callback

module.exports = LegacyRedis
