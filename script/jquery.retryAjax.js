// https://gist.github.com/cielavenir/69b27fd533f610c6695ad5ef727336dc

(function(jQuery) {
  jQuery.getWithRetries = function (uri, callback) {
    var callee = arguments.callee;
    jQuery.ajax({
      url: uri,
      type: 'get',
      timeout: 10000,
      success: (callback || (function () {})),
      error: function (xhr, status, e) {
        switch (xhr.status) {
        case 403: case 404: case 500:
          return jQuery.Deferred().reject(xhr.statusText).promise();
        default:
          console.log('読み込み失敗: ' + uri + ': リトライします');
          setTimeout(function(){callee(uri,callback);}, 2000);
        }
      }
    });
  };
  jQuery.postWithRetries = function (uri, data, callback) {
    var callee = arguments.callee;
    jQuery.ajax({
      url: uri,
      type: 'post',
      data: data,
      timeout: 10000,
      success: (callback || (function () {})),
      error: function (xhr, status, e) {
        switch (xhr.status) {
        case 403: case 404: case 500:
          return jQuery.Deferred().reject(xhr.statusText).promise();
        default:
          console.log('書き込み失敗: ' + uri + ': リトライします');
          setTimeout(function(){callee(uri,data,callback);}, 2000);
        }
      }
    });
  };
})(jQuery);
