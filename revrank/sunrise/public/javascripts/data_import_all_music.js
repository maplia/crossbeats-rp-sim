var RPSIM_HTTP_BASE_URI = 'http://revrank.maplia.jp/sunrise/';
var RPSIM_HTTPS_BASE_URI = 'https://revrank.maplia.jp/sunrise/';

var COMMON_SCRIPT_URI = RPSIM_HTTPS_BASE_URI + 'javascripts/revrank_common.js';

var progress = null;
var userData = {};
var musicList = [];
var classList = [];

// 取得できる楽曲の情報を取得する
function getMusicList(musicList) {
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
          musicItem.title = $(element).find('.pdMtitle')[0].textContent.trim();
          musicItem.uri = href;
          musicList.push(musicItem);
        }
      });
      console.log('楽曲件数: ' + musicList.length);
      deferred.resolve();
    }
  });
  return deferred.promise();
}

// 取得できるクラスの情報を取得する
function getClassList(classList) {
  var deferred = $.Deferred();
  // チャレンジデータのリンクリストから情報を取得する
  $.getWithRetries('playdatachallenge', function (document) {
    if (!isMyDataSessionAlive(document)) {
      deferred.reject(MESSAGE_SESSION_IS_DEAD);
    } else {
      $.each($(document).find('.c-event__list li'), function (i, element) {
        if ($(element).find('a').length > 0) {
          href = $(element).find('a')[0].href;
          if ((href.split('/').length > 3) && (href.split('/')[2] != location.hostname)) {
            return false;
          }
          var classItem = {};
          classItem.title = $(element).find('.c-event__ttl')[0].textContent.trim();
          classItem.uri = href;
          classList.push(classItem);
        }
      });
      console.log('クラス件数: ' + classList.length);
      deferred.resolve();
    }
  });
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
    return getMusicList(musicList);
  }).then(function () {
    return setProgressbarMax(progress, musicList, [], true);
  }).then(function () {
    return updateMusicRps(progress, userData, musicList);
//  }).then(function () {
//    return updateTotalRp(progress, userData);
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
