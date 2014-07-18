#!/usr/bin/env coffee
fs = require 'fs'
utils = require './utils'

DISQUALIFIED = [
  'gugod'         # 7K commits in 4 days.
  'sindresorhus'  # Asked to remove himself from the list.
  'funkenstein'   # Appears in the list even though he has 30 followers (bug).
  'scottgonzalez' # Contribution graffiti.
  'beberlei' # 1.7K contribs every day
]

saveTopLogins = ->
  MIN_FOLLOWERS = 255
  MAX_PAGES = 10
  urls = utils.range(1, MAX_PAGES + 1).map (page) ->
    "https://api.github.com/legacy/user/search/location:Guatemala?sort=followers&order=desc&start_page=#{page}"

  parse = (text) ->
    JSON.parse(text).users.map (_) -> _.username

  utils.batchGet urls, parse, (all) ->
    logins = [].concat.apply [], all
    filtered = logins.filter (name) ->
      name not in DISQUALIFIED
    utils.writeStats './temp-logins.json', filtered

saveTopLogins()
