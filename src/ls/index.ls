angular.module \main, <[]>
  ..controller \main, <[$scope $http $timeout]> ++ ($scope, $http, $timeout) ->
    base64p = -> btoa(it).replace /\//g, '-'
    $scope.keywords = {}
    $scope.trends = {}
    $scope.init = ->
      $http do
        url: \/keywords
        method: \GET
      .success (d) -> $scope.keywords = d
    $scope.doexpand = ->
      $scope.expand $scope.newkeyword
      $scope.newkeyword = ""
    $scope.expand = (keyword="") ->
      keyword = keyword.split(\,).filter(->it and !$scope.keywords[it]).join(',')
      if keyword =>
        $scope.dim = true
        $http do
          url: "/expand/#keyword"
          method: \GET
        .success (d) ->
          for k,v of d => if !$scope.keywords[k] => $scope.keywords[k] = 0
          for k in keyword.split(\,) => $scope.keywords[k] = 1
          $scope.save!
    $scope.save = ->
      $scope.dim = true
      $http do
        url: \/keywords/save
        method: \POST
        data: $scope.keywords
      .success (d) ->
        $scope.dim = false
    $scope.remove = ->
      delete $scope.keywords[it]
      $scope.save!
    $scope.add = ->
      if $scope.keywords[it] => return
      list = ($scope.newkeyword or "").split(\,)
      list.push(it)
      list = list.filter(->it and !$scope.keywords[it])
      $scope.newkeyword = list.join(\,)
    $scope.generate = ->
      keyword = [k for k of $scope.keywords].join(\,)
      if !keyword => return
      $scope.dim = true
      $http do
        url: "/trends/#keyword"
        method: \GET
      .success (d) -> 
        $scope.trends = d
        console.log "trends: ", $scope.trends
        $scope.dim = false
        $scope.getsites!
    $scope.getsites-stat = ->
      r = $scope.sites.filter(->!it.stat)
      if r.length == 0 => return
      item = r.0
      $http do
        url: "/content/#{base64p(item.href)}"
        method: \GET
      .success (d) -> 
        item.stat = d
        $timeout (-> $scope.getsites-stat!), 10
    $scope.sort-site = (type) ->
      switch type
      | 1 => $scope.sites.sort((a,b) -> b.idx - a.idx)
      | 2 => 
        e = -> it or {}
        $scope.sites.sort (a,b) -> 
          score-a = [(if e(a.stat).nofollow==false => 1 else 0), (if !e(a.stat).foundi => 1 else 0), (if e(a.stat).comment => 1 else 0)]
          score-b = [(if e(b.stat).nofollow==false => 1 else 0), (if !e(b.stat).foundi => 1 else 0), (if e(b.stat).comment => 1 else 0)]
          [score-a,score-b] = [score-a,score-b]map -> it.map((d,i) -> d * (2 ** i))reduce(((a,b) -> a + b),0)
          if score-b == score-a => return b.idx - a.idx
          return score-b - score-a

    $scope.getsites = ->
      keyword = [k for k of $scope.keywords].join(\,)
      if !keyword => return
      $scope.dim = true
      $http do
        url: "/search/#keyword"
        method: \GET
      .success (d) ->
        console.log "search list: ", d
        $scope.dim = false
        $scope.sites = []
        $scope.hosts = {}
        for k,v of d =>
          idx = 1
          for item in v =>
            item.trend = $scope.trends[k]
            item.key = k
            host = item.href.replace /^https?:\/\//, ""
            host = host.replace /\/.*$/, ""
            host = /(([^.]+)(.(edu|com|net|gov|idv|org))?\.[^/.]+)$/.exec host
            item.host = host.1
            item.idx = (60 - idx) * $scope.trends[k]
            item.idxstr = if item.idx >= 1000 => "#{parseInt(item.idx/1000)}K" else parseInt(item.idx)
            $scope.hosts[item.host] = ($scope.hosts[item.host] or 0) + item.idx
            $scope.sites.push item
            idx++
        $scope.sort-site 1
        $scope.hostbar!
        $scope.getsites-stat!
    $scope.color = color = d3.scale.category20!
    $scope.hostbar = ->
      data = [[k,v] for k,v of $scope.hosts]sort((a,b) -> b.1 - a.1)
      if data.length > 25 => data.splice(25)
      xmap = d3.scale.linear!domain [0 data.0.1] .range [0 500]
      $scope.barcolor = d3.scale.linear!domain [0 data.0.1/2 data.0.1] .range <[#0a0 #ff0 #d00]>
      h = 400 / data.length
      d3.select '#host g.bar' .selectAll \rect .data data
        ..enter!append \rect
        ..exit!remove!
      d3.select '#host g.text' .selectAll \text .data data
        ..enter!append \text
        ..exit!remove!
      d3.select '#host g.bar' .selectAll \rect
        ..attr do
          x: 0
          y: (d,i) -> i * h
          width: (d,i) -> xmap d.1
          height: h - 2
          fill: (d,i) -> $scope.barcolor d.1
      d3.select '#host g.text' .selectAll \text
        ..attr do
          x: (d,i) -> xmap d.1
          dx: 5
          y: (d,i) -> i * h
          dy: h/2 - 2
          "font-size": \12

          "dominant-baseline": \central
        ..text -> it.0

    $scope.bubble = ->
      root = {children: [{children: [], value: v, name: k} for k,v of $scope.trends]}
      nodes = d3.layout.pack!size([800 400]).nodes root
      nodes = nodes.filter -> it.name
      console.log nodes
      d3.select '#bubble g.circle' .selectAll \circle .data nodes
        ..enter!append \circle
        ..exit!remove!
      d3.select '#bubble g.text' .selectAll \text .data nodes
        ..enter!append \text
        ..exit!remove!
      d3.select '#bubble g.circle' .selectAll \circle
        ..attr do
          cx: -> it.x
          cy: -> it.y
          r: -> it.r
          fill: -> color it.name
      d3.select '#bubble g.text' .selectAll \text
        ..attr do
          x: -> it.x
          y: -> it.y
          opacity: -> if it.r == 0 => 0 else 1
        ..text -> it.name
    $scope.reload = (site, name) ->
      $http do
        url: "/content/#{base64p(site.href)}/force"
        method: \GET
      .success (d) -> site.stat <<< d
    $scope.toggle = (site, name) ->
      site.stat[name] = !!!site.stat[name]
      $http do
        url: "/content/#{base64p(site.href)}"
        method: \POST
        data: site.stat
      .success (d) ->
    $scope.$watch 'trends', -> $scope.bubble!
    $scope.init!
    $scope.trends = {'Comment': 1, 'Marketing': 1, 'Tool': 1}
    $('[data-toggle="tooltip"]').tooltip!
