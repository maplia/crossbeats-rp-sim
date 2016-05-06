var RPSIM_HTTP_BASE_URI = 'http://revrank.maplia.jp/sunrise/';
var RPSIM_HTTPS_BASE_URI = 'https://revrank.maplia.jp/sunrise/';

var COMMON_SCRIPT_URI = RPSIM_HTTPS_BASE_URI + 'javascripts/revrank_common.js';

var progress = null;
var userData = {};
var musicList = [];

// 取得する楽曲の情報を取得する
function getMusicItem(musicList) {
  var deferred = $.Deferred();
  // 現在のページから情報を取得する
  var musicItem = {};
  musicItem.title = $('.title')[0].textContent.trim();
  musicItem.uri = $(location).attr('href');
  musicList.push(musicItem);
  console.log('楽曲件数: ' + 1);
  deferred.resolve();
  return deferred.promise();
}

// ミュージックRPの更新（入口）
function updateMusicRps(progress, userData, musicItem) {
  var deferred = $.Deferred();
  var deferred_update = $.Deferred();
  progress.setMessage1('ミュージックRPを更新中です');
  progress.setMessage2('');
  deferred_update.then(function () {
    return updateMusicRp(progress, userData, musicItem);
  }).done(function () {
    progress.incProgressbarValue();
    deferred.resolve();
  }).fail(function (e) {
    deferred.reject(e);
  });
  deferred_update.resolve();
  return deferred.promise();
}

$('body').css('cursor', 'wait');
$.getScript(COMMON_SCRIPT_URI).done(function () {
  loadJQueryLibrary(function () {
    progress = $.progress(PROGRESS_OPTIONS);
    progress.open();
    console.log('ダイアログ初期化完了');
  }).then(function () {
    return getMusicItem(musicList);
  }).then(function () {
    return setProgressbarMax(progress, musicList, [], true);
  }).then(function () {
    return getUserData(progress, userData);
  }).then(function () {
    return loginToRpSim(progress, userData);
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
