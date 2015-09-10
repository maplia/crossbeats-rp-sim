var DEBUG = false;
if (!DEBUG) {
  console['log'] = function () {};
}

var MAPLIA_BASE_URI = 'https://secure508.sakura.ne.jp/revbeta.maplia.jp/';
var MUSIC_DIFFS = ['esy', 'std', 'hrd', 'mas', 'unl'];
var GRADES = ['S++', 'S+', 'S', 'A+', 'A', 'B+', 'B', 'C', 'D', 'E'];
var WAIT_MSEC = 1500;

var MESSAGE_SESSION_IS_DEAD = '処理の途中でセッションが終了しました。最初からやり直してください。';

var revUserId = null;
var response = null;
var lookupKey = null;
var body = null;
var playdataUris = [];
var title = null;

// セッションが継続しているか確認
function isSessionAlive(document) {
  // ログインフォームがなければセッション継続と判断
  return $(document).find('#login').length == 0;
}

$('body').css('cursor', 'wait');
var deferred = $.Deferred();
deferred.then(function () {
  // jQuery UIでのダイアログ表示準備
  var deferred = $.Deferred();
  $.getScript('https://revrank.maplia.jp/script/jquery-ui.1.14.1.min.js', function () {
    $('body').append('<div id="dialog"><table id="dialog-table"><tbody><tr><td id="proc_type"></td></tr><tr><td id="proc_title"></td></tr><tr><td><div id="progressbar"></div></td></tr></tbody></table>');
    $('#dialog').dialog({
      title: 'REV. SkillPoint Simulator',
      modal: true, width: 450, height: 160,
      draggable: false, resizable: false,
      open: function (event, ui) {
        $('.ui-dialog').css('z-index', '30000');
        $('.ui-widget-overlay').css('z-index', '25000');
        $('.ui-dialog-title').css('font-size', '2.0em');
        $('.ui-dialog-titlebar-close').hide();
        $('#dialog-table').css('width', '100%');
        $('#dialog-table').css('font-size', '1.8em');
        $('#dialog-table tr td').css('height', '2.0em');
      }
    });
    $('#progressbar').progressbar({
      value: false
    });
  });
  $('head').append($('<link/>', {
    type: 'text/css', rel: 'stylesheet',
    href: 'https://revrank.maplia.jp/style/jquery-ui.min.css'
  }));
  $('head').append($('<link/>', {
    type: 'text/css', rel: 'stylesheet',
    href: 'https://revrank.maplia.jp/style/jquery-ui.theme.min.css'
  }));
  deferred.resolve();
  return deferred.promise();
}).then(function () {
  var deferred = $.Deferred();
  // REV.ユーザーIDの取得
  revUserId = $('.u-profList li dl dd')[0].textContent;
  console.log('REV.ユーザID: ' + revUserId);
  deferred.resolve();
  return deferred.promise();
}).then(function () {
  $('#proc_type').text('ユーザー登録を確認中です');
  // RPシミュのユーザIDの取得
  return $.getJSON(MAPLIA_BASE_URI + 'api/user/' + revUserId, function (data) {
    response = data;
  });
}).then(function () {
  var deferred = $.Deferred();  
  // RPシミュにユーザ登録がなければエラー
  if (response.user_id == undefined) {
    console.log('ユーザ未登録');
    deferred.reject('REV. RankPoint SimulatorにREV.ユーザーIDが登録されていません。');
  } else {
    console.log('REV. RankPoint Simulator ユーザID: ' + response.user_id);
    deferred.resolve();
  }
  return deferred.promise();
}).then(function () {
  // ミュージックRPが載っているページURLが載っているページの取得
  return $.get('playdatamusic', function (document) {
    response = document;
  });
}).then(function () {
  var deferred = $.Deferred();
  // ミュージックRPが載っているページURLの取得
  if (!isSessionAlive(response)) {
    deferred.reject(MESSAGE_SESSION_IS_DEAD);
  } else {
    $.each($(response).find('.pdMusicList a'), function (i, element) {
      playdataUris.push(element.href);
    });
    $('#progressbar').progressbar('option', 'max', playdataUris.length + 1);
    $('#progressbar').progressbar('value', 0);
    deferred.resolve();
  }
  return deferred.promise();
}).then(function () {
  // チャレンジRPが載っているページの取得
  $('#proc_type').text('チャレンジRPを更新中です');
  return $.get('rplist', function (document) {
    response = document;
  });
}).then(function () {
  var deferred = $.Deferred();  
  // クリアクラスとチャレンジRPの取得
  if (!isSessionAlive(response)) {
    deferred.reject(MESSAGE_SESSION_IS_DEAD);
  } else if ($(response).find('.rpc-image').length == 0) {
    lookupKey = null;
    deferred.resolve();
  } else {
    // 画像URLからクリアクラスに当てられた画像ファイル名を取得
    var classRe = /challenge\/([^\?]+)/;
    lookupKey = classRe.exec($(response).find('.rpc-image')[0].src)[1];
    // テキストからチャレンジRPを取得
    var pointRe = /(\d+\.\d+)/;
    var point = parseFloat(pointRe.exec($(response).find('.rpc-cTxt')[0].textContent)[1]);
    body = {
      'stat': 1, 'point': point
    };
    deferred.resolve();
  }
  return deferred.promise();
}).then(function () {
  // チャレンジRPデータの更新
  if (lookupKey == null) {
    var deferred = $.Deferred();
    console.log('チャレンジRP: 成績登録なし');
    $('#progressbar').progressbar('value', $('#progressbar').progressbar('value') + 1);
    deferred.resolve();
    return deferred.promise();
  } else {
    var postData = {
      'game_id': revUserId, 'type': 'course', 'lookup_key': lookupKey,
      'body': body
    };
    return $.post(MAPLIA_BASE_URI + 'edit_direct', JSON.stringify(postData), function (data) {
      response = data;
    }).then(function () {
      var deferred = $.Deferred();
      switch (response.status) {
      case 400:
        console.log('チャレンジRP: コース未対応');
        alert('対象コースがREV. RankPoint Simulator未登録のため、チャレンジRPの更新をスキップします。');
        break;
      case 500:
        console.log('チャレンジRP: 更新失敗');
        alert('データベースの処理エラーが発生したため、チャレンジRPの更新をスキップします。');
        break;
      default:
        console.log('チャレンジRP: 更新成功');
        break;
      }
      $('#progressbar').progressbar('value', $('#progressbar').progressbar('value') + 1);
      deferred.resolve();
      return deferred.promise();
    });
  }
}).then(function () {
  // ミュージックRPデータの更新
  var deferred = (new $.Deferred()).resolve();
  $('#proc_type').text('ミュージックRPを更新中です');
  $.each(playdataUris, function (i, uri) {
    deferred = deferred.then(function () {
      // ミュージックRPが載っているページの取得
      var musicRe = /playdatamusic\/(.+)/;
      lookupKey = musicRe.exec(uri)[1];
      return $.get('playdatamusic/' + lookupKey, function (document) {
        title = $(document).find('.title').first().text();
        $('#proc_title').text(title);
        response = document;
      });
    }).then(function () {
      var deferred = $.Deferred();
      if (!isSessionAlive(response)) {
        deferred.reject(MESSAGE_SESSION_IS_DEAD);
      } else {
        body = {};
        // ミュージックRPの取得
        $.each($(response).find('.pdm-result'), function (i, element) {
          var bodyDiff = {};
          // クリアランク + クリア状況
          var gradeSrc = $(element).find('.grade img')[0].src;
          var gradeRe = /grade_(\d+).png/;
          var grade = parseInt(gradeRe.exec(gradeSrc)[1]) + 1;
          if (grade == GRADES.length + 2) {
            bodyDiff.stat = 0;      // プレイなし
          } else if (grade == GRADES.length + 1) {
            bodyDiff.stat = 2;      // クリア失敗
          } else {
            bodyDiff.stat = 1;      // クリア
            bodyDiff.rank = grade;
          }
          // 以下はクリアしている譜面のみ取得
          if (bodyDiff.stat == 1) {
            // RP
            var point = parseFloat($(element).find('.pdResultList dd')[2].textContent);
            bodyDiff.point = point;
            // クリアレート
            var rate = parseInt($(element).find('.pdResultList dd')[1].textContent);
            bodyDiff.rate = rate;
            // ゲージタイプ
            var gaugeSrc = ($(element).find('.clear p').length == 1 ? $(element).find('.clear p img')[0].src : 'bnr_dummy_CLEAR.png'); 
            var gaugeRe = /bnr_(\w+)_CLEAR.png/;
            var gauge = gaugeRe.exec(gaugeSrc)[1];
            if (gauge == 'SURVIVAL') {
              bodyDiff.gauge = 1;   // SURVIVAL
            } else if (gauge == 'ULTIMATE') {
              bodyDiff.gauge = 2;   // ULTIMATE
            } else {
              bodyDiff.gauge = 0;   // ゲージオプションなし
            }
            // フルコンボ
            if ($(element).find('.fullcombo').length == 1) {
              var notesRe = /Note:(\d+)/;
              var notes = parseInt(notesRe.exec($(element).find('.note')[0].textContent)[1]);
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
        deferred.resolve();
      }
      return deferred.promise();
    }).then(function () {
      // ミュージックRPデータの更新
      var postData = {
        'game_id': revUserId, 'type': 'music', 'lookup_key': lookupKey,
        'body': body
      };
      return $.post(MAPLIA_BASE_URI + 'edit_direct', JSON.stringify(postData), function (data) {
        response = data;
      }).then(function () {
        var deferred = $.Deferred();
        switch (response.status) {
        case 400:
          console.log('ミュージックRP [' + title + ']: 楽曲未対応');
          alert('「' + title + '」がREV. RankPoint Simulator未登録のため、この曲のミュージックRPの更新をスキップします。');
          break;
        case 500:
          console.log('ミュージックRP [' + title + ']: 更新失敗');
          alert('「' + title + '」でデータベースの処理エラーが発生したため、この曲のミュージックRPの更新をスキップします。');
          break;
        default:
          console.log('ミュージックRP [' + title + ']: 更新成功');
          break;
        }
        $('#progressbar').progressbar('value', $('#progressbar').progressbar('value') + 1);
        deferred.resolve();
        return deferred.promise();
      }).then(function () {
        var deferred = $.Deferred();
        setTimeout(function () {
          deferred.resolve();
        }, WAIT_MSEC);
        return deferred.promise();
      });
    });
  });
  return deferred.promise();  
}).done(function () {
  $('body').css('cursor', 'auto');
  $('#dialog').dialog('destroy');
  $('#dialog').css('display', 'none');
  alert('REV. RankPoint Simulatorの更新が完了しました。');
}).fail(function (e) {
  $('body').css('cursor', 'auto');
  $('#dialog').dialog('destroy');
  $('#dialog').css('display', 'none');
  alert(e);
});
deferred.resolve();
