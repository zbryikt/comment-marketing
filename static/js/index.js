var x$;
x$ = angular.module('main', []);
x$.controller('main', ['$scope', '$http'].concat(function($scope, $http){
  var color;
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
      var k, v, idx, i$, len$, item;
      console.log("search list: ", d);
      $scope.dim = false;
      $scope.sites = [];
      for (k in d) {
        v = d[k];
        idx = 1;
        for (i$ = 0, len$ = v.length; i$ < len$; ++i$) {
          item = v[i$];
          item.trend = $scope.trends[k];
          item.key = k;
          item.idx = (60 - idx) * $scope.trends[k];
          $scope.sites.push(item);
          idx++;
        }
      }
      return $scope.sites.sort(function(a, b){
        return b.idx - a.idx;
      });
    });
  };
  $scope.color = color = d3.scale.category20();
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
