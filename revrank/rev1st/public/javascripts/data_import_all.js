var RPSIM_HTTP_BASE_URI = 'http://revrank.maplia.jp/rev1st/';
var RPSIM_HTTPS_BASE_URI = 'https://revrank.maplia.jp/rev1st/';

var COMMON_SCRIPT_URI = RPSIM_HTTPS_BASE_URI + 'javascripts/revrank_common.js';

var progress = null;
var userData = {};
var musicList = [];

// ユーザの情報を取得する
function getUserData(progress, userData) {
  var deferred = $.Deferred();
  userData.revUserId = $('.u-profList li dl dd')[0].textContent;
  console.log('REV.ユーザID: ' + userData.revUserId);
  deferred.resolve();
  return deferred.promise();
}

// 取得できる楽曲の情報を取得する
function getMusicList(progress, musicList, isForRpUpdate) {
  var deferred = $.Deferred();
  // ミュージックデータのリンクリストから情報を取得する
  $.getWithRetries('playdatamusic', function (document) {
    if (!isMyDataSessionAlive(document)) {
      deferred.reject(MESSAGE_SESSION_IS_DEAD);
    } else {
      $.each($(document).find('.pdMusicData'), function (i, element) {
        if ($(element).find('a').length > 0) {
          href = $(element).find('a')[0].href;
          if ((href.split('/').length > 3) && (href.split('/')[2] != location.hostname)) {
            return false;
          }
          var musicItem = {};
          musicItem.title = $(element).find('.pdMtitle').first().text();
          musicItem.uri = href;
          musicList.push(musicItem);
        }
      });
      console.log('楽曲件数: ' + musicList.length);
      if (isForRpUpdate) {
        progress.setProgressbarMax(musicList.length + 2);
      } else {
        progress.setProgressbarMax(musicList.length);
      }
      deferred.resolve();
    }
  });
  return deferred.promise();
}

// チャレンジRPの更新
function updateChallengeRp(progress, userData) {
  var deferred = $.Deferred();
  progress.setMessage1('チャレンジRPを更新中です');
  progress.setMessage2('');
  // RP対象曲一覧のチャレンジRP部分を参照する
  $.getWithRetries('rplist', function (document) {
    if (!isMyDataSessionAlive(document)) {
      console.log('チャレンジRP: セッション無効');
      deferred.reject(MESSAGE_SESSION_IS_DEAD);
    } else {
      var postData = parseChallengeRp(document);
      if (!postData) {
        console.log('チャレンジRP: 対象なし');
        progress.incProgressbarValue();
        deferred.resolve();
      } else {
        postData.key = userData.key;
        var item = {
          'lookup_key': postData.lookup_key
        };
        updateRp(progress, postData, item).then(function () {
          progress.incProgressbarValue();
          deferred.resolve();
        }, function (e) {
          deferred.reject(e);
        });
      }
    }
  });
  return deferred.promise();
}

// チャレンジRPの取得
function parseChallengeRp(document) {
  if ($(document).find('.rpc-image').length == 0) {
    return null;
  } else {
    // 対象クラスとチャレンジRPを取得して、post用データを作成する
    var lookupKey = /(Class_\d\d\.png)/.exec($(document).find('.rpc-image')[0].src)[1];
    var point = parseFloat(/(\d+\.\d+)/.exec($(document).find('.rpc-cTxt')[0].textContent)[1]);
    return {
      'type': 'course', 'lookup_key': lookupKey,
      'body': {
        'stat': 1, 'point': point
      }
    };
  }
}

// ミュージックRPの更新（入口）
function updateMusicRps(progress, userData, musicList) {
  var deferred = $.Deferred();
  var deferred_each = $.Deferred();
  var chain = deferred_each;
  progress.setMessage1('ミュージックRPを更新中です');
  progress.setMessage2('');
  $.each(musicList, function (i, musicItem) {
    chain = chain.then(function () {
      return updateMusicRp(progress, userData, musicItem);
    }).then(function () {
      return wait(WAIT_MSEC);
    }).then(function () {
      progress.incProgressbarValue();
      return $.Deferred().resolve().promise();
    });
  });
  chain.done(function () {
    deferred.resolve();
  }).fail(function (e) {
    deferred.reject(e);
  });
  deferred_each.resolve();
  return deferred.promise();
}

$('body').css('cursor', 'wait');
$.getScript(COMMON_SCRIPT_URI).done(function () {
  loadJQueryLibrary(function () {
    progress = $.progress(PROGRESS_OPTIONS);
    progress.open();
    console.log('ダイアログ初期化完了');
  }).then(function () {
    return getUserData(progress, userData);
  }).then(function () {
    return loginToRpSim(progress, userData);
  }).then(function () {
    return getMusicList(progress, musicList, true);
  }).then(function () {
    return updateChallengeRp(progress, userData);
  }).then(function () {
    return updateMusicRps(progress, userData, musicList);
  }).then(function () {
    return updateTotalRp(progress, userData);
  }).then(function () {
    return logoutFromRpSim(progress, userData);
  }).done(function () {
    $('body').css('cursor', 'auto');
    progress.close();
    progress = undefined;
    return $.confirm('REV. RankPoint Simulatorの更新が完了しました。ランクポイント表へ移動しますか?', ALERT_OPTIONS,
      function () {
        location.href = RPSIM_VIEW_URI + '/' + userData.user_id;
      });
  }).fail(function (e) {
    if (userData.key) {
      logoutFromRpSim(progress, userData);
    }
    $('body').css('cursor', 'auto');
    if (progress) {
      progress.close();
      progress = undefined;
    }
    if (e) {
      return $.alert(e, ALERT_OPTIONS);
    }
  });
});
