angular.module \main, <[]>
  ..controller \main, <[$scope $http]> ++ ($scope, $http) ->
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
        for k,v of d =>
          idx = 1
          for item in v =>
            item.trend = $scope.trends[k]
            item.key = k
            item.idx = (60 - idx) * $scope.trends[k]
            $scope.sites.push item
            idx++
        $scope.sites.sort((a,b) -> b.idx - a.idx)
    $scope.color = color = d3.scale.category20!
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
    $scope.$watch 'trends', -> $scope.bubble!
    $scope.init!
    $scope.trends = {'Comment': 1, 'Marketing': 1, 'Tool': 1}
