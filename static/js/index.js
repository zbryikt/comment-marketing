var x$;
x$ = angular.module('main', []);
x$.controller('main', ['$scope', '$http', '$timeout'].concat(function($scope, $http, $timeout){
  var base64p, color;
  base64p = function(it){
    return btoa(it).replace(/\//g, '-');
  };
  $scope.keywords = {};
  $scope.trends = {};
  $scope.init = function(){
    return $http({
      url: '/keywords',
      method: 'GET'
    }).success(function(d){
      return $scope.keywords = d;
    });
  };
  $scope.doexpand = function(){
    $scope.expand($scope.newkeyword);
    return $scope.newkeyword = "";
  };
  $scope.expand = function(keyword){
    keyword == null && (keyword = "");
    keyword = keyword.split(',').filter(function(it){
      return it && !$scope.keywords[it];
    }).join(',');
    if (keyword) {
      $scope.dim = true;
      return $http({
        url: "/expand/" + keyword,
        method: 'GET'
      }).success(function(d){
        var k, v, i$, ref$, len$;
        for (k in d) {
          v = d[k];
          if (!$scope.keywords[k]) {
            $scope.keywords[k] = 0;
          }
        }
        for (i$ = 0, len$ = (ref$ = keyword.split(',')).length; i$ < len$; ++i$) {
          k = ref$[i$];
          $scope.keywords[k] = 1;
        }
        return $scope.save();
      });
    }
  };
  $scope.save = function(){
    $scope.dim = true;
    return $http({
      url: '/keywords/save',
      method: 'POST',
      data: $scope.keywords
    }).success(function(d){
      return $scope.dim = false;
    });
  };
  $scope.remove = function(it){
    delete $scope.keywords[it];
    return $scope.save();
  };
  $scope.add = function(it){
    var list;
    if ($scope.keywords[it]) {
      return;
    }
    list = ($scope.newkeyword || "").split(',');
    list.push(it);
    list = list.filter(function(it){
      return it && !$scope.keywords[it];
    });
    return $scope.newkeyword = list.join(',');
  };
  $scope.generate = function(){
    var keyword, k;
    keyword = (function(){
      var results$ = [];
      for (k in $scope.keywords) {
        results$.push(k);
      }
      return results$;
    }()).join(',');
    if (!keyword) {
      return;
    }
    $scope.dim = true;
    return $http({
      url: "/trends/" + keyword,
      method: 'GET'
    }).success(function(d){
      $scope.trends = d;
      console.log("trends: ", $scope.trends);
      $scope.dim = false;
      return $scope.getsites();
    });
  };
  $scope.getsitesStat = function(){
    var r, item;
    r = $scope.sites.filter(function(it){
      return !it.stat;
    });
    if (r.length === 0) {
      return;
    }
    item = r[0];
    return $http({
      url: "/content/" + base64p(item.href),
      method: 'GET'
    }).success(function(d){
      item.stat = d;
      return $timeout(function(){
        return $scope.getsitesStat();
      }, 10);
    });
  };
  $scope.getsites = function(){
    var keyword, k;
    keyword = (function(){
      var results$ = [];
      for (k in $scope.keywords) {
        results$.push(k);
      }
      return results$;
    }()).join(',');
    if (!keyword) {
      return;
    }
    $scope.dim = true;
    return $http({
      url: "/search/" + keyword,
      method: 'GET'
    }).success(function(d){
      var k, v, idx, i$, len$, item, host;
      console.log("search list: ", d);
      $scope.dim = false;
      $scope.sites = [];
      $scope.hosts = {};
      for (k in d) {
        v = d[k];
        idx = 1;
        for (i$ = 0, len$ = v.length; i$ < len$; ++i$) {
          item = v[i$];
          item.trend = $scope.trends[k];
          item.key = k;
          host = item.href.replace(/^https?:\/\//, "");
          host = host.replace(/\/.*$/, "");
          host = /(([^.]+)(.(edu|com|net|gov|idv|org))?\.[^/.]+)$/.exec(host);
          item.host = host[1];
          item.idx = (60 - idx) * $scope.trends[k];
          $scope.hosts[item.host] = ($scope.hosts[item.host] || 0) + item.idx;
          $scope.sites.push(item);
          idx++;
        }
      }
      $scope.sites.sort(function(a, b){
        return b.idx - a.idx;
      });
      $scope.hostbar();
      return $scope.getsitesStat();
    });
  };
  $scope.color = color = d3.scale.category20();
  $scope.hostbar = function(){
    var data, k, v, xmap, h, x$, y$, z$, z1$;
    data = (function(){
      var ref$, results$ = [];
      for (k in ref$ = $scope.hosts) {
        v = ref$[k];
        results$.push([k, v]);
      }
      return results$;
    }()).sort(function(a, b){
      return b[1] - a[1];
    });
    if (data.length > 25) {
      data.splice(25);
    }
    xmap = d3.scale.linear().domain([0, data[0][1]]).range([0, 500]);
    $scope.barcolor = d3.scale.linear().domain([0, data[0][1] / 2, data[0][1]]).range(['#0a0', '#ff0', '#d00']);
    h = 400 / data.length;
    x$ = d3.select('#host g.bar').selectAll('rect').data(data);
    x$.enter().append('rect');
    x$.exit().remove();
    y$ = d3.select('#host g.text').selectAll('text').data(data);
    y$.enter().append('text');
    y$.exit().remove();
    z$ = d3.select('#host g.bar').selectAll('rect');
    z$.attr({
      x: 0,
      y: function(d, i){
        return i * h;
      },
      width: function(d, i){
        return xmap(d[1]);
      },
      height: h - 2,
      fill: function(d, i){
        return $scope.barcolor(d[1]);
      }
    });
    z1$ = d3.select('#host g.text').selectAll('text');
    z1$.attr({
      x: function(d, i){
        return xmap(d[1]);
      },
      dx: 5,
      y: function(d, i){
        return i * h;
      },
      dy: h / 2 - 2,
      "font-size": '12',
      "dominant-baseline": 'central'
    });
    z1$.text(function(it){
      return it[0];
    });
    return z1$;
  };
  $scope.bubble = function(){
    var root, k, v, nodes, x$, y$, z$, z1$;
    root = {
      children: (function(){
        var ref$, results$ = [];
        for (k in ref$ = $scope.trends) {
          v = ref$[k];
          results$.push({
            children: [],
            value: v,
            name: k
          });
        }
        return results$;
      }())
    };
    nodes = d3.layout.pack().size([800, 400]).nodes(root);
    nodes = nodes.filter(function(it){
      return it.name;
    });
    console.log(nodes);
    x$ = d3.select('#bubble g.circle').selectAll('circle').data(nodes);
    x$.enter().append('circle');
    x$.exit().remove();
    y$ = d3.select('#bubble g.text').selectAll('text').data(nodes);
    y$.enter().append('text');
    y$.exit().remove();
    z$ = d3.select('#bubble g.circle').selectAll('circle');
    z$.attr({
      cx: function(it){
        return it.x;
      },
      cy: function(it){
        return it.y;
      },
      r: function(it){
        return it.r;
      },
      fill: function(it){
        return color(it.name);
      }
    });
    z1$ = d3.select('#bubble g.text').selectAll('text');
    z1$.attr({
      x: function(it){
        return it.x;
      },
      y: function(it){
        return it.y;
      },
      opacity: function(it){
        if (it.r === 0) {
          return 0;
        } else {
          return 1;
        }
      }
    });
    z1$.text(function(it){
      return it.name;
    });
    return z1$;
  };
  $scope.$watch('trends', function(){
    return $scope.bubble();
  });
  $scope.init();
  return $scope.trends = {
    'Comment': 1,
    'Marketing': 1,
    'Tool': 1
  };
}));
