require! <[LiveScript fs ./secret bluebird request util path]>
require! './backend/main': {backend, aux}
require! './backend/dummy': driver
require! <[google-trends]>
require! <[google-search]>

# specialized base64 encoder ( slash character escaped )
base64 = do
  encode: -> new Buffer(it).toString("base64").replace /\//g, "-"
  decode: -> new Buffer(it.replace(/-/g, "/"), \base64).toString!

store = do
  path: -> path.join \./data, base64.encode(it)
  read: -> 
    if !fs.exists-sync(@path(it)) => return {}
    JSON.parse(fs.read-file-sync @path(it) .toString!)
  write: (name, data) -> fs.write-file-sync @path(name), JSON.stringify(data)
  time: -> if fs.exists-sync @path(it) => fs.stat-sync(@path it).mtime.getTime! else 0
  age: -> new Date!getTime! - @time it
  still-young: -> @age(it) < @cache-time
  cache-time: 3 * 86400 * 1000
    
prequest = (config) -> new bluebird (res, rej) ->
  (e,r,b) <- request config, _
  if e or !b => return rej!
  return res b

config = {debug: true, name: \servlet}
config <<< secret
backend.init config, driver, ->

backend.app.get \/trends/:keyword, (req, res) ->
  if store.still-young "trends/#{req.params.keyword}" =>
    return res.json store.read "trends/#{req.params.keyword}"
  keywords = req.params.keyword.split(\,)
  google-trends.getAll keywords .then (result) -> 
    store.write "trends/#{req.params.keyword}", result
    res.json result

backend.app.post \/content/:url, (req, res) ->
  url = base64.decode(req.params.url)
  data = {} <<< req.body{foundi, comment, nofollow}
  store.write "content/custom/#url", data
  return res.json {}

get-content = (req, res, force=no) ->
  url = base64.decode(req.params.url)
  if !force and store.still-young("content/#url") =>
    return res.json store.read "content/#url"
  prequest {url, method: \GET, timeout: 5 * 1000} .then (body) ->
    foundi = !!/foundi/.exec(body)
    comment = (!!/留言|評論/.exec(body)) or (!!/fb-comments/.exec body)
    nofollow = !!/nofollow/.exec(body)
    ret = {foundi, comment, nofollow}
    store.write "content/#url", ret
    custom-ret = store.read "content/custom/#url"
    return res.json (ret <<< custom-ret)
  .catch -> return res.json null

backend.app.get \/content/:url, (req, res) -> get-content req, res
backend.app.get \/content/:url/force, (req, res) -> get-content req, res, true

searchlist = (keywords, res, data = {}) ->
  if keywords.length == 0 => return res.json data
  keyword = keywords.splice(0,1).0
  if store.still-young "search/#keyword" =>
    data[keyword] = store.read "search/#keyword"
    return setTimeout (->searchlist keywords, res, data), 0
  google-search.getPages(keyword, [i for i from 1 to 3]).then (result) ->
    console.log ">>>", keyword, result.length
    data[keyword] = result
    store.write "search/#keyword", result
    searchlist keywords, res, data

backend.app.get \/search/:keyword, (req, res) ->
  searchlist req.params.keyword.split(\,), res

relatedlist = (keywords, res, data = {}) ->
  if keywords.length == 0 => return res.json data
  keyword = keywords.splice(0,1).0
  if store.still-young "related/#keyword" =>
    data := data <<< store.read "related/#keyword"
    return setTimeout (->relatedlist keywords, res, data), 0
  google-trends.recursiveRelated keyword .then (result) ->
    store.write "related/#keyword", result
    data := data <<< result
    relatedlist keywords, res, data

backend.app.get \/expand/:keyword, (req, res) ->
  relatedlist req.params.keyword.split(\,), res

backend.app.get \/keywords, (req, res) -> res.json store.read "keywords"

backend.app.post \/keywords/save, (req, res) ->
  store.write "keywords", req.body
  res.json {}

backend.app.get \/global, aux.type.json, (req, res) -> res.render \global.ls, {user: req.user, global: true}

# remove after forked
backend.app.get \/sample, (req, res) -> res.render 'sample/index.jade', {word1: "hello", context: {word2: "world"}}
backend.app.get \/sample.js, aux.type.json, (req, res) -> res.render 'sample/index.ls', {word: "hello world"}
# if serve static file via express 
# backend.app.use express.static __dirname + '/static'

backend.app.get \/, (req, res) -> res.render 'index.jade'

backend.start ->

