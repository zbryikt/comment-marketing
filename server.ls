require! <[LiveScript fs ./secret]>
require! './backend/main': {backend, aux}
require! './backend/dummy': driver
require! <[google-trends]>
require! <[google-search]>

config = {debug: true, name: \servlet}
config <<< secret
backend.init config, driver, ->

backend.app.get \/trends/:keyword, (req, res) ->
  keywords = req.params.keyword.split(\,)
  google-trends.getAll keywords .then (result) -> res.json result

searchlist = (keywords, res, data = {}) ->
  if keywords.length == 0 => return res.json data
  keyword = keywords.splice(0,1).0
  google-search.getPages(keyword, [i for i from 1 to 3]).then (result) ->
    console.log ">>>", keyword, result.length
    data[keyword] = result
    searchlist keywords, res, data

backend.app.get \/search/:keyword, (req, res) ->
  #res.json JSON.parse(fs.read-file-sync \search-result.json .toString!)
  searchlist req.params.keyword.split(\,), res

relatedlist = (keywords, res, data = {}) ->
  if keywords.length == 0 => return res.json data
  keyword = keywords.splice(0,1).0
  google-trends.recursiveRelated keyword .then (result) ->
    data := data <<< result
    relatedlist keywords, res, data

backend.app.get \/expand/:keyword, (req, res) ->
  relatedlist req.params.keyword.split(\,), res

backend.app.get \/keywords, (req, res) ->
  if !fs.exists-sync \keywords.json => return res.json {}
  res.json JSON.parse(fs.read-file-sync \keywords.json .toString!)

backend.app.post \/keywords/save, (req, res) ->
  fs.write-file-sync \keywords.json, JSON.stringify(req.body)
  res.json {}

backend.app.get \/global, aux.type.json, (req, res) -> res.render \global.ls, {user: req.user, global: true}

# remove after forked
backend.app.get \/sample, (req, res) -> res.render 'sample/index.jade', {word1: "hello", context: {word2: "world"}}
backend.app.get \/sample.js, aux.type.json, (req, res) -> res.render 'sample/index.ls', {word: "hello world"}
# if serve static file via express 
# backend.app.use express.static __dirname + '/static'

backend.app.get \/, (req, res) -> res.render 'index.jade'

backend.start ->

