var RPSIM_HTTP_BASE_URI = 'http://revrank.maplia.jp/sunrise/';
var RPSIM_HTTPS_BASE_URI = 'https://revrank.maplia.jp/sunrise/';

var COMMON_SCRIPT_URI = RPSIM_HTTPS_BASE_URI + 'javascripts/revrank_common.js';

var progress = null;
var userData = {};
var classList = [];

// 取得するクラスの情報を取得する
function getClassItem(classList) {
  var deferred = $.Deferred();
  // 現在のページから情報を取得する
  var classItem = {};
  classItem.title = $('.c-event__ttl--big')[0].textContent.trim();
  classItem.uri = $(location).attr('href');
  classList.push(classItem);
  console.log('クラス件数: ' + 1);
  deferred.resolve();
  return deferred.promise();
}

$('body').css('cursor', 'wait');
$.getScript(COMMON_SCRIPT_URI).done(function () {
  loadJQueryLibrary(function () {
    progress = $.progress(PROGRESS_OPTIONS);
    progress.open();
    console.log('ダイアログ初期化完了');
  }).then(function () {
    return getClassItem(classList);
  }).then(function () {
    return setProgressbarMax(progress, [], classList, true);
  }).then(function () {
    return getUserData(progress, userData);
  }).then(function () {
    return loginToRpSim(progress, userData);
  }).then(function () {
    return updateClassRps(progress, userData, classList);
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
