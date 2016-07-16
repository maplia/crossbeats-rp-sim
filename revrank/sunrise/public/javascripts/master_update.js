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

// ミュージックデータの更新（入口）
function updateMusicData(progress, userData, musicList) {
  var deferred = $.Deferred();
  var deferred_each = $.Deferred();
  var chain = deferred_each;
  progress.setMessage1('ミュージックデータを更新中です');
  progress.setMessage2('');
  $.each(musicList, function (i, musicItem) {
    chain = chain.then(function () {
      return updateMusicItem(progress, userData, musicItem);
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

// ミュージックデータの更新（単曲）
function updateMusicItem(progress, userData, musicItem) {
  var deferred = $.Deferred();
  progress.setMessage2(musicItem.title);
  $.getWithRetries(musicItem.uri, function (document) {
    if (!isMyDataSessionAlive(document)) {
      console.log('ミュージックデータ: セッション無効');
      deferred.reject(MESSAGE_SESSION_IS_DEAD);
    } else {
      lookup_key = /playdatamusic\/(.+)/.exec(musicItem.uri)[1];
      musicItem = parseMusicItem(document);
      musicItem.lookup_key = lookup_key;
      updateMasterData(userData.key, 'music', musicItem).done(function () {
        deferred.resolve();
      }).fail(function (e) {
        deferred.reject(e);
      });
    }
  });
  return deferred.promise();
}

// チャレンジデータの更新（入口）
function updateClassData(progress, userData, classList) {
  var deferred = $.Deferred();
  var deferred_each = $.Deferred();
  var chain = deferred_each;
  progress.setMessage1('チャレンジデータを更新中です');
  progress.setMessage2('');
  $.each(classList, function (i, classItem) {
    chain = chain.then(function () {
      return updateClassItem(progress, userData, classItem);
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

// チャレンジRPの更新（単体）
function updateClassItem(progress, userData, classItem) {
  var deferred = $.Deferred();
  progress.setMessage2(classItem.title);
  $.getWithRetries(classItem.uri, function (document) {
    if (!isMyDataSessionAlive(document)) {
      console.log('チャレンジRP: セッション無効');
      deferred.reject(MESSAGE_SESSION_IS_DEAD);
    } else {
      lookup_key = /playdatachallenge\/(.+)/.exec(classItem.uri)[1];
      classItem = parseClassItem(document);
      classItem.lookup_key = lookup_key;
      updateMasterData(userData.key, 'course', classItem).done(function () {
        deferred.resolve();
      }).fail(function (e) {
        deferred.reject(e);
      });
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
    return getClassList(classList);
  }).then(function () {
    return setProgressbarMax(progress, musicList, classList, false);
//  }).then(function () {
//    return updateMusicData(progress, userData, musicList);
  }).then(function () {
    return updateClassData(progress, userData, classList);
  }).then(function () {
    return logoutFromRpSim(progress, userData);
  }).done(function () {
    $('body').css('cursor', 'auto');
    progress.close();
    progress = undefined;
    return $.alert('REV. RankPoint Simulatorの更新が完了しました。', ALERT_OPTIONS);
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
