#!/usr/bin/env coffee
cheerio = require 'cheerio'
utils = require './utils'

stats = {}

median = (xs) ->
    return null if (xs.length == 0)
    sorted = xs.filter((x) -> x > 0).slice().sort((a,b) -> a-b)
    if (sorted.length % 2 == 1)
        sorted[(sorted.length-1)/2]
    else
        (sorted[(sorted.length/2)-1]+sorted[(sorted.length/2)])/2

getStats = (html, url) ->
  $ = cheerio.load html
  byProp = (field) -> $("[itemprop='#{field}']")
  getInt = (text) -> parseInt text.replace ',', ''
  getOrgName = (item) -> $(item).attr('aria-label')

  badgeCount = (selector) ->
    text = $(selector).text().trim()
    multiplier = if text.indexOf('k') > 0 then 1000 else 1
    (parseFloat text) * multiplier

  getFollowers = (login) ->
    badgeCount("a[href='/#{login}?tab=followers'] > span")
  getRepositories = (login) ->
    badgeCount("a[href='/#{login}?tab=repositories'] > span")
  getStars = (login) ->
    badgeCount("a[href='/#{login}?tab=stars'] > span")
  getFollowing = (login) ->
    badgeCount("a[href='/#{login}?tab=following'] > span")
  getProjects = (login) ->
    badgeCount("a[href='/#{login}?tab=projects'] > span")
  pageDesc = $('meta[name="description"]').attr('content')
  login = byProp('additionalName').text().trim()

  userStats =
    name: byProp('name').text().trim()
    login: login
    location: byProp('homeLocation').text().trim()
    language: (/\sin ([\w-+#\s\(\)]+)/.exec(pageDesc)?[1] ? '')
    gravatar: byProp('image').attr('href')
    followers: getFollowers(login)
    repositories: getRepositories(login)
    stars: getStars(login)
    following: getFollowing(login)
    projects: getProjects(login)
    organizations: $("[itemprop='worksFor'] > span").text().trim()
    contributions: getInt $('.js-yearly-contributions > div > h2').text()
    dayMedian: median($("rect.day").map((i,day) ->
        getInt day['attribs']['data-count']))
  stats[userStats.login] = userStats
  userStats

sortStats = (stats) ->
  minContributions = 1
  Object.keys(stats)
    .filter (login) ->
      stats[login].contributions >= minContributions
    .sort (a, b) ->
      stats[b].contributions - stats[a].contributions
    .map (login) ->
      stats[login]

saveStats = ->
  logins = require './temp-logins.json'
  urls = logins.map (login) -> "https://github.com/#{login}"
  utils.batchGet urls, getStats, ->
    utils.writeStats './raw/github-users-stats.json', sortStats stats

saveStats()
