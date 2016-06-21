var DEBUG = true;
if (!DEBUG) {
  console['log'] = function () {};
}

var RPSIM_VIEW_URI = RPSIM_HTTP_BASE_URI + 'view';
var RPSIM_LOGIN_URI = RPSIM_HTTPS_BASE_URI + 'bml_login';
var RPSIM_LOGOUT_URI = RPSIM_HTTPS_BASE_URI + 'bml_logout';
var RPSIM_EDIT_URI = RPSIM_HTTPS_BASE_URI + 'bml_edit';
var RPSIM_POINT_URI = RPSIM_HTTPS_BASE_URI + 'bml_point';
var RPSIM_UPDATE_MASTER_URI = RPSIM_HTTPS_BASE_URI + 'bml_update_master';

var JQUERY_UI_SCRIPT_URI = 'https://code.jquery.com/ui/1.11.4/jquery-ui.min.js';
var JQUERY_DIALOG_SCRIPT_URI = 'https://marines.sakura.ne.jp/script/jquery.dialog.js';
var JQUERY_RETRYAJAX_SCRIPT_URI = 'https://marines.sakura.ne.jp/script/jquery.retryAjax.js';
var JQUERY_UI_STYLE_URI = 'https://code.jquery.com/ui/1.11.4/themes/eggplant/jquery-ui.css';

var MESSAGE_SESSION_IS_DEAD = '処理の途中でセッションが終了しました。最初からやり直してください';

var MUSIC_DIFFS = ['esy', 'std', 'hrd', 'mas', 'unl'];
var GRADES = ['S++', 'S+', 'S', 'A+', 'A', 'B+', 'B', 'C', 'D', 'E'];
var WAIT_MSEC = 1000;
var DIALOG_TITLE = 'REV. RankPoint Simulator';
var DIALOG_FONT_SIZE = '12pt';
var PROGRESS_OPTIONS = {
  title: DIALOG_TITLE, cancelable: false, width: 300, font_size: DIALOG_FONT_SIZE, detail_height: '3.2em'
};
var ALERT_OPTIONS = {
  title: DIALOG_TITLE, width: 300, height: 210, font_size: DIALOG_FONT_SIZE
};
var MUSIC_BANNERS = [
	'bnr_difficulty_ea.png', 'bnr_difficulty_st.png', 'bnr_difficulty_ha.png',
	'bnr_difficulty_ms.png', 'bnr_difficulty_un.png'
];

// MY DATAページのセッションが継続しているか確認
function isMyDataSessionAlive(document) {
  // ログインフォームがあればセッション切断されたと判断
  if ($(document).find('#login').length > 0) {
    console.log('MY DATAページセッション無効');
    return false;
  }
  return true;
}

// 指定された時間だけ待つ
function wait(msec) {
  var deferred = $.Deferred();
  setTimeout(function () {
    deferred.resolve(msec);
  }, msec);
  return deferred.promise();
}

// jQueryライブラリの読み込み
function loadJQueryLibrary(callback) {
  var deferred = $.Deferred();
  var deferred_script = $.Deferred();
  $('head').append($('<link/>', {
    type: 'text/css', rel: 'stylesheet', href: JQUERY_UI_STYLE_URI
  }));
  console.log('読み込み完了: ' + JQUERY_UI_STYLE_URI);
  $.ajaxSetup({
    cache: false
  });
  deferred_script.then(function () {
    return $.getScript(JQUERY_UI_SCRIPT_URI).done(function () {
      console.log('読み込み完了: ' + JQUERY_UI_SCRIPT_URI);
    });
  }).then(function () {
    return $.getScript(JQUERY_DIALOG_SCRIPT_URI).done(function () {
      console.log('読み込み完了: ' + JQUERY_DIALOG_SCRIPT_URI);
    });
  }).then(function () {
    return $.getScript(JQUERY_RETRYAJAX_SCRIPT_URI).done(function () {
      console.log('読み込み完了: ' + JQUERY_RETRYAJAX_SCRIPT_URI);
    });
  }).done(function () {
    if (callback) {
      callback();
    }
    deferred.resolve();
  });
  deferred_script.resolve();
  return deferred.promise();
}

// ユーザの情報を取得する
function getUserData(progress, userData) {
  var deferred = $.Deferred();
  // プロフィールページから情報を取得する
  $.getWithRetries('/profile', function (document) {
    if (!isMyDataSessionAlive(document)) {
      console.log('ミュージックRP: セッション無効');
      deferred.reject(MESSAGE_SESSION_IS_DEAD);
    } else {
      userData.revUserId = $(document).find('.mb20 dl dd')[0].textContent.trim();
      console.log('REV.ユーザID: ' + userData.revUserId);
      deferred.resolve();
    }
  });
  return deferred.promise();
}

// RPシミュレータにログインする
function loginToRpSim(progress, userData) {
  var deferred = $.Deferred();
  // REV.ユーザIDの登録確認
  progress.setMessage1('ユーザー登録を確認中です');
  progress.setMessage2('');
  $.post(RPSIM_LOGIN_URI, 'game_id=' + userData.revUserId, function (response) {
    if (response.status != 200) {
      console.log('REV. RankPoint Simulator ユーザ未登録');
      deferred.reject('REV. RankPoint SimulatorにREV.ユーザーIDが登録されていません');
    } else {
      console.log('REV. RankPoint Simulator ユーザ登録確認');
      userData.key = response.key;
      userData.user_id = response.user_id;
      deferred.resolve();
    }
  });
  return deferred.promise();
}

// ミュージックデータの取得
function parseMusicItem(document) {
  var item = {};
  // ミュージックRPページから取得する
  if ($(document).find('.pdm-jkt')[0] != undefined) {
  	item.jacket = /\/([^\/]*.png)/.exec($(document).find('.pdm-jkt')[0].src)[1];
    item.text_id = /([^\/]*).png/.exec(item.jacket)[1];
    item.text_id = item.text_id.toLowerCase();
    item.text_id = item.text_id.replace(/[\_\-\(\)]/g, '');
    item.sort_key = /([^\/]*).png/.exec(item.jacket)[1];
    item.sort_key = item.sort_key.toLowerCase();
    item.sort_key = item.sort_key.replace(/[\_\-\(\)]/g, ' ');
  }
  item.title = $(document).find('.title')[0].textContent.trim();
  $.each($(document).find('.pdm-result'), function (i, element) {
    var itemDiff = {};
    itemDiff.level = parseInt(/Lv.\s*(\d+)/.exec($(element).find('.lv')[0].textContent)[1].trim());
    itemDiff.notes = parseInt(/Note:\s*(\d+)/.exec($(element).find('.note')[0].textContent)[1].trim());
    item[MUSIC_DIFFS[i]] = itemDiff;
  });
  return item;
}

// チャレンジデータの取得
function parseClassItem(document) {
  var item = {};
  // チャレンジRPページから取得する
  if ($(document).find('.c-event')[0] != undefined) {
    item.text_id = /\/([^\/]*).png/.exec($(document).find('.c-event__banner img')[0].src)[1];
    item.text_id = item.text_id.toLowerCase();
    item.text_id = item.text_id.replace(/[\_\-\(\)]/g, '');
    item.sort_key = item.text_id;
    item.title = $(document).find('.c-event__ttl--big')[0].textContent.trim();
  }
  item.musics = [];
  $.each($(document).find('.chMissionBlock'), function (i, element) {
    var music = {};
    music.jacket = /\/([^\/]*.png)/.exec($(element).find('.chJk')[0].src)[1].trim();
    if ($(element).find('.chmdiff').length > 0) {
      diff_banner = /\/([^\/]*.png)/.exec($(element).find('.chmdiff')[0].src)[1].trim();
      $.each(MUSIC_BANNERS, function (i, banner) {
        if (diff_banner == banner) {
          music.diff = MUSIC_DIFFS[i];
          return true;
        }
      });
    }
    item.musics[item.musics.length] = music;
  });
  return item;
}

// マスタデータの登録
function updateMasterData(sessionKey, type, item) {
  var deferred = $.Deferred();
  var postData = {
    'key': sessionKey, 'type': type, 'body': item
  };
  $.postWithRetries(RPSIM_UPDATE_MASTER_URI, JSON.stringify(postData), function (response) {
    if (postData.type == 'music') {
      var logLabel = 'ミュージック [' + item.title + ']';
    } else {
      var logLabel = 'チャレンジ [' + item.title + ']';
    }
    switch (response.status) {
    case 401: case 500:
      console.log(logLabel + ': 更新失敗');
      deferred.reject('マスタデータの更新に失敗しました。最初から操作をやり直してください');
      break;
    default:
      console.log(logLabel + ': 更新成功');
      deferred.resolve();
      break;
    }
  });
  return deferred.promise();
}

// RPの更新
function updateRp(progress, postData, item) {
  if (progress.isCanceled()) {
    return $.Deferred().reject('処理がキャンセルされました').promise();
  } else {
    var deferred = $.Deferred();
    $.postWithRetries(RPSIM_EDIT_URI, JSON.stringify(postData), function (response) {
      if (postData.type == 'music') {
        var logLabel = 'ミュージックRP [' + item.title + ']';
      } else {
        var logLabel = 'チャレンジRP [' + item.title + ']';
      }
      switch (response.status) {
      case 401:
        console.log(logLabel + ': セッション無効');
        deferred.reject(MESSAGE_SESSION_IS_DEAD);
        break;
      case 400:
        console.log(logLabel + ': マスタ未登録');
        updateMasterData(postData.key, postData.type, item).then(function () {
          return updateRp(progress, postData, item);
        }).done(function () {
          deferred.resolve();
        }).fail(function (e) {
          deferred.reject(e);
        });
        break;
      case 500:
        console.log(logLabel + ': 更新失敗');
        alert('データベースの処理エラーが発生したため、チャレンジRPの更新をスキップします');
        deferred.resolve();
        break;
      default:
        console.log(logLabel + ': 更新成功');
        deferred.resolve();
        break;
      }
    });
    return deferred.promise();
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

// ミュージックRPの更新（単曲）
function updateMusicRp(progress, userData, musicItem) {
  var deferred = $.Deferred();
  progress.setMessage2(musicItem.title);
  $.getWithRetries(musicItem.uri, function (document) {
    if (!isMyDataSessionAlive(document)) {
      console.log('ミュージックRP: セッション無効');
      deferred.reject(MESSAGE_SESSION_IS_DEAD);
    } else {
      var postData = parseMusicRp(document);
      postData.key = userData.key;
      postData.lookup_key = /playdatamusic\/(.+)/.exec(musicItem.uri)[1];
      musicItem = parseMusicItem(document);
      musicItem.lookup_key = postData.lookup_key; 
      updateRp(progress, postData, musicItem).done(function () {
        deferred.resolve();
      }).fail(function (e) {
        deferred.reject(e);
      });
    }
  });
  return deferred.promise();
}

// ミュージックRPの取得
function parseMusicRp(document) {
  var body = {};
  // ミュージックRPの取得
  $.each($(document).find('.pdm-result'), function (i, element) {
    var bodyDiff = {};
    // クリアランク + クリア状況
    var grade = parseInt(/grade_(\d+).png/.exec($(element).find('.grade img')[0].src)[1]) + 1;
    if (grade == GRADES.length + 2) {
      bodyDiff.stat = 0;      // プレイなし
    } else if (grade == GRADES.length + 1) {
      bodyDiff.stat = 2;      // クリア失敗
    } else {
      bodyDiff.stat = 1;      // クリア
      bodyDiff.rank = grade;
    }
    // スコア
    var score = parseInt($(element).find('.pdResultList dd')[0].textContent.trim());
    bodyDiff.score = score;
    // 以下はクリアしている譜面のみ取得
    if (bodyDiff.stat == 1) {
      // RP
      var point = parseFloat($(element).find('.pdResultList dd')[2].textContent.trim());
      bodyDiff.point = point;
      // クリアレート
      var rate = parseFloat($(element).find('.pdResultList dd')[1].textContent.trim());
      bodyDiff.rate = rate;
      // ゲージタイプ
      var gaugeSrc = ($(element).find('.clear p').length == 1 ? $(element).find('.clear p img')[0].src : 'bnr_dummy_CLEAR.png'); 
      var gauge = /bnr_(\w+)_CLEAR.png/.exec(gaugeSrc)[1];
      if (gauge == 'SURVIVAL') {
        bodyDiff.gauge = 1;   // SURVIVAL
      } else if (gauge == 'ULTIMATE') {
        bodyDiff.gauge = 2;   // ULTIMATE
      } else {
        bodyDiff.gauge = 0;   // ゲージオプションなし
      }
      // フルコンボ
      if ($(element).find('.fullcombo').length == 1) {
        var notes = parseInt(/Note:\s*(\d+)/.exec($(element).find('.note')[0].textContent)[1].trim());
        var score = parseInt($(element).find('.pdResultList dd')[0].textContent);
        if (notes * 100 == score) {
          bodyDiff.combo = 2; // フルコンボ（All Flawless）
        } else {
          bodyDiff.combo = 1; // フルコンボ
        }
      } else {
        bodyDiff.combo = 0;   // フルコンボなし
      }
    }
    body[MUSIC_DIFFS[i]] = bodyDiff;
  });
  return {
    'type': 'music',
    'body': body
  };
}

// チャレンジRPの更新（入口）
function updateClassRps(progress, userData, classList) {
  var deferred = $.Deferred();
  var deferred_each = $.Deferred();
  var chain = deferred_each;
  progress.setMessage1('チャレンジRPを更新中です');
  progress.setMessage2('');
  $.each(classList, function (i, classItem) {
    chain = chain.then(function () {
      return updateClassRp(progress, userData, classItem);
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
function updateClassRp(progress, userData, classItem) {
  var deferred = $.Deferred();
  progress.setMessage2(classItem.title);
  $.getWithRetries(classItem.uri, function (document) {
    if (!isMyDataSessionAlive(document)) {
      console.log('チャレンジRP: セッション無効');
      deferred.reject(MESSAGE_SESSION_IS_DEAD);
    } else {
      var postData = parseClassRp(document);
      postData.key = userData.key;
      postData.lookup_key = /playdatachallenge\/(.+)/.exec(classItem.uri)[1];
      classItem = parseClassItem(document);
      classItem.lookup_key = postData.lookup_key; 
      updateRp(progress, postData, classItem).done(function () {
        deferred.resolve();
      }).fail(function (e) {
        deferred.reject(e);
      });
    }
  });
  return deferred.promise();
}

// チャレンジRPの取得
function parseClassRp(document) {
  var body = {};
  // プレイ状況
  // 1曲目が未プレイならコース全部未プレイ、4曲目が未プレイか失敗でなければ完走とみなす
  var grade = parseInt(/grade_(\d+).png/.exec($(document).find('.chMissionBlock .chmGrade img')[0].src)[1]) + 1;
  if (grade == GRADES.length + 2) {
  	body.stat = 0;          // プレイなし
  } else {
    grade = parseInt(/grade_(\d+).png/.exec($(document).find('.chMissionBlock .chmGrade img')[3].src)[1]) + 1;
    if (grade >= GRADES.length + 1) {
      body.stat = 2;        // クリア失敗
    } else {
      body.stat = 1;        // クリア成功
    }
  }
  // 以下はプレイしているクラスのみ取得
  if (body.stat != 0) {
    // RP
    var point = parseFloat(/(\d+\.\d+)/.exec($(document).find('.eventResult dd')[3].textContent.trim())[1]);
     body.point = point;
    // クリアレート
    var rate = parseFloat(/(\d+\.\d+)/.exec($(document).find('.eventResult dd')[2].textContent.trim())[1]);
    body.rate = rate;
  }

  return {
    'type': 'course',
    'body': body
  };
}

// 総合RPの更新
function updateTotalRp(progress, userData) {
  if (progress.isCanceled()) {
    return $.Deferred().reject('処理がキャンセルされました').promise();
  } else {
    var deferred = $.Deferred();
    $.getWithRetries('/profile', function (document) {
      if (!isMyDataSessionAlive(document)) {
        console.log('総合RP: セッション無効');
        deferred.reject(MESSAGE_SESSION_IS_DEAD);
      } else {
        progress.setMessage1('総合RPを更新中です');
        progress.setMessage2('');
        var postData = parseTotalRp(document);
        postData.key = userData.key;
        $.postWithRetries(RPSIM_POINT_URI, JSON.stringify(postData), function (response) {
          switch (response.status) {
          case 401:
            console.log('総合RP: セッション無効');
            deferred.reject(MESSAGE_SESSION_IS_DEAD);
            break;
          case 500:
            console.log('総合RP: 更新失敗');
            alert('データベースの処理エラーが発生したため、総合RPの更新をスキップします');
            progress.incProgressbarValue();
            deferred.resolve();
            break;
          default:
            console.log('総合RP: 更新成功');
            progress.incProgressbarValue();
            deferred.resolve();
            break;
          }
        });
      }
    });
    return deferred.promise();
  }
}

// 総合RPの取得
function parseTotalRp(document) {
  body = {};
  pointParts = /(\d+).*(\.\d+)/.exec($(document).find('.m-profile__rp')[0].textContent.trim());
  body.point = parseFloat(pointParts[1] + pointParts[2]);
  return {
    'body': body
  };
}

// RPシミュレータからログアウトする
function logoutFromRpSim(progress, userData) {
  var deferred = $.Deferred();
  var postData = {
    'key': userData.key
  };
  progress.setMessage1('終了処理をしています');
  progress.setMessage2('');
  $.postWithRetries(RPSIM_LOGOUT_URI, JSON.stringify(postData), function (response) {
    switch (response.status) {
    case 401: case 500:
      console.log('ログアウト異常発生');
      break;
    default:
      console.log('ログアウト');
      break;
    }
    deferred.resolve();
  });
  return deferred.promise();
}

// 取得できる楽曲とクラスの件数を進捗件数に反映する
function setProgressbarMax(progress, musicList, classList, isForRpUpdate) {
  var deferred = $.Deferred();
  if (isForRpUpdate) {
    progress.setProgressbarMax(musicList.length + classList.length + 1);
  } else {
    progress.setProgressbarMax(musicList.length + classList.length);
  }
  deferred.resolve();
  return deferred.promise();
}
