angular.module 'supersnake.services'

.service 'score', () ->
  get: () ->
    parseMeta window.client.player.meta


# helper
parseMeta = (meta) ->
  meta.lossCount = meta.gameCount - meta.winCount || 0
  meta
