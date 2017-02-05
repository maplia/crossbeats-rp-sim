var VERSION = '20170205';

var HOSTNAME = 'http://cxbrank.maplia.jp';
var AUTHORIZE_URI = HOSTNAME + '/api/authorize';
var GET_SKILLS_URI = HOSTNAME + '/api/skills/:user_id';
var SKILL_EDIT_URI = HOSTNAME + '/api/edit';
var EDIT_FIX_URI = HOSTNAME + '/api/edit_fix';

var INPUT_SHEET = SpreadsheetApp.getActiveSpreadsheet().getSheetByName('入力シート');
var TEMPLATE_SHEET = SpreadsheetApp.getActiveSpreadsheet().getSheetByName('入力テンプレート');
var CURRENT_SHEET = SpreadsheetApp.getActiveSpreadsheet().getSheetByName('登録データ');
var UPDATE_SHEET = SpreadsheetApp.getActiveSpreadsheet().getSheetByName('更新データ');

var MUSIC_DIFFS = ['std', 'hrd', 'mas'];

var STATS = ['プレイなし', 'クリア', 'クリア失敗'];
var RANKS = ['', 'S++', 'S+', 'S', 'A+', 'A', 'B+', 'B', 'C', 'D', 'E'];
var COMBO_STATUSES = ['', 'FC', 'EXC'];
var CHECK_STATUSES = ['', '✔'];

var UNIT_SIZE = 30;
var INPUT_SHEET_COLS = 20;
var INPUT_DIFF_COLS = 9;

function onOpen() {
  var spread = SpreadsheetApp.getActiveSpreadsheet();
  var menuItems = [
    {name: 'データ取得', functionName: 'getData'},
    {name: 'データ更新', functionName: 'updateData'}
  ];
  spread.addMenu('スクリプト', menuItems);
}

function getValueFromName(names, name) {
  for (var i = 0; i < names.length; i++) {
    if (name == names[i]) {
      return i;
    }
  }
  return -1;
}

function getPulldownText(cell, value) {
  var validation = cell.getDataValidation();
  return validation.getCriteriaValues()[0][value];
}

function setPulldownValue(cell, value) {
  cell.setValue(getPulldownText(cell, value));
}

function getPulldownValue(cell, text) {
  var validation = cell.getDataValidation();
  for (var i = 0; i < validation.getCriteriaValues()[0].length; i++) {
    if (text == validation.getCriteriaValues()[0][i]) {
      return i;
    }
  }
  return -1;
}

function getA1Notation(range) {
  return range.getSheet().getName() + '!' + range.getA1Notation();
}

function getUserId() {
  return INPUT_SHEET.getRange('G1').getValue();
}

function getPassword() {
  return INPUT_SHEET.getRange('J1').getValue();
}

function authorize() {
  // ユーザーID
  var user_id = getUserId();
  if (user_id.length == 0) {
    Browser.msgBox('ユーザーIDが入力されていません');
    return null;
  }
  // パスワード
  var password = getPassword();
  if (password.length == 0) {
    Browser.msgBox('パスワードが入力されていません');
    return null;
  }
  // ユーザー認証
  var payload = {'user_id': user_id, 'password': password, 'version': VERSION};
  var response = UrlFetchApp.fetch(AUTHORIZE_URI, {
    'method': 'post', 'payload': JSON.stringify(payload)
  });
  var result = JSON.parse(response.getContentText('utf-8'));
  if (!result) {
    Browser.msgBox('ユーザーIDかパスワードが間違っています');
    return null;
  }
  return user_id;
}

function getData() {
  // --------------
  // ユーザ情報取得
  // --------------
  var user_id = authorize();
  if (user_id == null) {
    return;
  }

  // --------------
  // 登録データ取得
  // --------------
  var response = UrlFetchApp.fetch(GET_SKILLS_URI.replace(/:user_id/, user_id));
  var skillData = JSON.parse(response.getContentText('utf-8'));
  for (var i = 0; i < skillData.length; i++) {
    skillData[i].music.full_title = skillData[i].music.full_title.replace(/&times;/g, '×');
    skillData[i].music.full_title = skillData[i].music.full_title.replace(/&infin;/g, '∞');
    skillData[i].music.full_title = skillData[i].music.full_title.replace(/&#x2661;/g, '♡');
  }
  
  // -----------------------------
  // 入力シート作成/隠しシート準備
  // -----------------------------

  // 初期化
  INPUT_SHEET.deleteRows(2, INPUT_SHEET.getLastRow()-2);
  INPUT_SHEET.insertRowsBefore(2, skillData.length*5-1);
  CURRENT_SHEET.clear();
  UPDATE_SHEET.clear();

  // 書式設定
  TEMPLATE_SHEET.getRange(1, 1, skillData.length*5, INPUT_SHEET_COLS).copyTo(INPUT_SHEET.getRange(2, 1));

  var INPUT_FOCUS_COLS = INPUT_SHEET_COLS;
  var CURRENT_FOCUS_COLS = INPUT_DIFF_COLS*MUSIC_DIFFS.length + 3;
  var UPDATE_FOCUS_COLS = CURRENT_FOCUS_COLS + 3;

  var musicCount = 0;

  for (var i = 0; i < skillData.length; i += UNIT_SIZE) {
    var inputFocusTopRow = 1 + i*5 + 1;
    var updateFocusTopRow = i + 1;
    var inputFocusRows = 0;
    var inputFocusRows = (Math.min(UNIT_SIZE, skillData.length-i)) * 5;
    var updateFocusRows = (Math.min(UNIT_SIZE, skillData.length-i));

    var inputSheetValues = INPUT_SHEET.getRange(inputFocusTopRow, 1, inputFocusRows, INPUT_FOCUS_COLS).getValues();
    var inputSheetFormats = INPUT_SHEET.getRange(inputFocusTopRow, 1, inputFocusRows, INPUT_FOCUS_COLS).getNumberFormats();
    var currentSheetValues = CURRENT_SHEET.getRange(updateFocusTopRow, 1, updateFocusRows, CURRENT_FOCUS_COLS).getValues();
    var updateSheetFormulas = UPDATE_SHEET.getRange(updateFocusTopRow, 1, updateFocusRows, UPDATE_FOCUS_COLS).getFormulas();

    for (var j = 0; j < UNIT_SIZE; j++) {
      var index = i + j;
      if (index >= skillData.length) {
        break;
      }
      var skill = skillData[index];
      var music = skill.music;

      // タイトル
      inputSheetValues[j*5+0][0] = music.full_title;
      currentSheetValues[j][0] = music.full_title;
      updateSheetFormulas[j][0] = getA1Notation(CURRENT_SHEET.getRange(index+1, 0+1));
      // テキストID
      currentSheetValues[j][1] = music.text_id;
      updateSheetFormulas[j][1] = getA1Notation(CURRENT_SHEET.getRange(index+1, 1+1));

      // 譜面別データ
      for (var k = 0; k < MUSIC_DIFFS.length; k++) {
        var diff_chart = music[MUSIC_DIFFS[k]];
        var diff_skill = skill[MUSIC_DIFFS[k]];
        var diff_data_col_min = 2 + INPUT_DIFF_COLS*k;
        // レベル
        inputSheetValues[j*5+k+1][1] = diff_chart.level;
        // RP入力範囲
        var rp_rule = SpreadsheetApp.newDataValidation().requireNumberBetween(0, diff_chart.level*1.2).setAllowInvalid(false).build();
        INPUT_SHEET.getRange(1+index*5+(k+1)+1, 6).setDataValidation(rp_rule);
        // スコア入力範囲
        var score_rule = SpreadsheetApp.newDataValidation().requireNumberBetween(0, diff_chart.notes*100).setAllowInvalid(false).build();
        INPUT_SHEET.getRange(1+index*5+(k+1)+1, 18).setDataValidation(score_rule);
        // プレイ状態
        inputSheetValues[j*5+k+1][3] = STATS[diff_skill.stat];
        currentSheetValues[j][diff_data_col_min+0] = STATS[diff_skill.stat];
        // 以下はクリアのデータがあるときのみ反映
        if (diff_skill.stat == 1) {
          // RP
          inputSheetValues[j*5+k+1][5] = diff_skill.point;
          if (diff_skill.point) {
            currentSheetValues[j][diff_data_col_min+1] = "'" + new Number(diff_skill.point).toFixed(2);
          }
          // クリアレート
          inputSheetValues[j*5+k+1][7] = diff_skill.rate/100.00;
          currentSheetValues[j][diff_data_col_min+2] = diff_skill.rate/100.00;
          // ランク
          inputSheetValues[j*5+k+1][9] = RANKS[diff_skill.rank];
          currentSheetValues[j][diff_data_col_min+3] = RANKS[diff_skill.rank];
          // コンボ
          inputSheetValues[j*5+k+1][11] = COMBO_STATUSES[diff_skill.combo];
          currentSheetValues[j][diff_data_col_min+4] = COMBO_STATUSES[diff_skill.combo];
          // ゲージ
          inputSheetValues[j*5+k+1][13] = CHECK_STATUSES[diff_skill.gauge];
          currentSheetValues[j][diff_data_col_min+5] = CHECK_STATUSES[diff_skill.gauge];
        }
        // 未所持
        inputSheetValues[j*5+k+1][15] = CHECK_STATUSES[(diff_skill.locked ? 1 : 0)];
        currentSheetValues[j][diff_data_col_min+6] = CHECK_STATUSES[(diff_skill.locked ? 1 : 0)];
        // スコア
        inputSheetValues[j*5+k+1][17] = diff_skill.score;
        currentSheetValues[j][diff_data_col_min+7] = diff_skill.score;
        // 旧譜面
        inputSheetValues[j*5+k+1][19] = CHECK_STATUSES[(diff_skill.legacy ? 1 : 0)];
        currentSheetValues[j][diff_data_col_min+8] = CHECK_STATUSES[(diff_skill.legacy ? 1 : 0)];
        updateSheetFormulas[j][diff_data_col_min+0] = getA1Notation(INPUT_SHEET.getRange(2+index*5+k+1, 4));
        updateSheetFormulas[j][diff_data_col_min+1] = getA1Notation(INPUT_SHEET.getRange(2+index*5+k+1, 6));
        updateSheetFormulas[j][diff_data_col_min+2] = 'IF('+ getA1Notation(INPUT_SHEET.getRange(2+index*5+k+1, 8)) + '<>"",VALUE(' + getA1Notation(INPUT_SHEET.getRange(2+index*5+k+1, 8)) + '),"")';
        updateSheetFormulas[j][diff_data_col_min+3] = getA1Notation(INPUT_SHEET.getRange(2+index*5+k+1, 10));
        updateSheetFormulas[j][diff_data_col_min+4] = getA1Notation(INPUT_SHEET.getRange(2+index*5+k+1, 12));
        updateSheetFormulas[j][diff_data_col_min+5] = getA1Notation(INPUT_SHEET.getRange(2+index*5+k+1, 14));
        updateSheetFormulas[j][diff_data_col_min+6] = getA1Notation(INPUT_SHEET.getRange(2+index*5+k+1, 16));
        updateSheetFormulas[j][diff_data_col_min+7] = getA1Notation(INPUT_SHEET.getRange(2+index*5+k+1, 18));
        updateSheetFormulas[j][diff_data_col_min+8] = getA1Notation(INPUT_SHEET.getRange(2+index*5+k+1, 20));
      }

      var common_data_col_min = 2+INPUT_DIFF_COLS*MUSIC_DIFFS.length;
      // コメント
      inputSheetValues[j*5+4][2] = skillData[index].comment;
      inputSheetFormats[j*5+4][2] = '@';
      currentSheetValues[j][common_data_col_min] = skillData[index].comment;
      updateSheetFormulas[j][common_data_col_min] = getA1Notation(INPUT_SHEET.getRange(1+index*5+4+1, 3));
      
      // 変更検出用
      updateSheetFormulas[j][common_data_col_min+1] = 'JOIN(",",' + getA1Notation(CURRENT_SHEET.getRange(index+1, 1, 1, common_data_col_min+1)) + ')';
      updateSheetFormulas[j][common_data_col_min+2] = 'JOIN(",",' + getA1Notation(UPDATE_SHEET.getRange(index+1, 1, 1, common_data_col_min+1)) + ')';
      updateSheetFormulas[j][common_data_col_min+3] = getA1Notation(UPDATE_SHEET.getRange(index+1, common_data_col_min+1+1)) + '<>' + getA1Notation(UPDATE_SHEET.getRange(index+1, common_data_col_min+2+1));
      
      musicCount++;
      skillData[index] = null;
    }

    INPUT_SHEET.getRange(inputFocusTopRow, 1, inputFocusRows, INPUT_FOCUS_COLS).setValues(inputSheetValues);
    INPUT_SHEET.getRange(inputFocusTopRow, 1, inputFocusRows, INPUT_FOCUS_COLS).setNumberFormats(inputSheetFormats);
    CURRENT_SHEET.getRange(updateFocusTopRow, 1, updateFocusRows, CURRENT_FOCUS_COLS).setValues(currentSheetValues);
    UPDATE_SHEET.getRange(updateFocusTopRow, 1, updateFocusRows, UPDATE_FOCUS_COLS).setFormulas(updateSheetFormulas);

    SpreadsheetApp.getActiveSpreadsheet().toast(musicCount + ' / ' + skillData.length, '入力シート反映状況', 1);
  }

  Browser.msgBox('登録データの取得が完了しました');
}

function updateData() {
  // --------------
  // ユーザ情報取得
  // --------------
  var user_id = authorize();
  if (user_id == null) {
    return;
  }
  var password = getPassword();

  // ----------
  // データ登録
  // ----------
  var data = UPDATE_SHEET.getRange(1, 1, UPDATE_SHEET.getLastRow(), UPDATE_SHEET.getLastColumn()).getValues();
  for (var i = 0; i < data.length; i++) {
    var isUpdate = data[i][2+INPUT_DIFF_COLS*MUSIC_DIFFS.length+1+3-1];
    if (isUpdate) {
      var payload = {
        'user_id': user_id, 'password': password, 'text_id': data[i][2-1],
        'body': {
          'comment': encodeURIComponent(data[i][2+INPUT_DIFF_COLS*MUSIC_DIFFS.length+1-1])
        }
      };
      for (var j = 0; j < MUSIC_DIFFS.length; j++) {
        var stat = getValueFromName(STATS, data[i][2+INPUT_DIFF_COLS*j+0]);
        if (stat == 1) {
          var point = parseFloat(data[i][2+INPUT_DIFF_COLS*j+1]);
          var rate = parseFloat(data[i][2+INPUT_DIFF_COLS*j+2]);
          var gauge = getValueFromName(CHECK_STATUSES, data[i][2+INPUT_DIFF_COLS*j+5]);
          var bonus_rate = ((gauge == 1) ? 1.2 : 1.0);
          if (isNaN(point) && !isNaN(rate)) {
            // RPを補完
            var level = INPUT_SHEET.getRange(2+i*5+j+1, 2).getValue();
            point = Math.multiply(Math.multiply(level, rate), bonus_rate);
            point = Math.floor(Math.multiply(point, 100)) / 100.0;
            INPUT_SHEET.getRange(2+i*5+j+1, 6).setValue(point);
            rate = Math.multiply(rate, 100);
          } else if (!isNaN(point) && isNaN(rate)) {
            // クリアレートを補完
            var level = INPUT_SHEET.getRange(2+i*5+j+1, 2).getValue();
            rate = Math.floor(Math.multiply(point / bonus_rate / level, 10000) / 100.0);
            INPUT_SHEET.getRange(2+i*5+j+1, 8).setValue(rate/100);
          } else {
            rate = Math.multiply(rate, 100);
          }
          payload.body[MUSIC_DIFFS[j]] = {
            'stat': stat, 'point': point, 'rate': rate, 'gauge': gauge,
            'rank': getValueFromName(RANKS, data[i][2+INPUT_DIFF_COLS*j+3]),
            'combo': getValueFromName(COMBO_STATUSES, data[i][2+INPUT_DIFF_COLS*j+4]),
            'locked': getValueFromName(CHECK_STATUSES, data[i][2+INPUT_DIFF_COLS*j+6]),
            'score': data[i][2+INPUT_DIFF_COLS*j+7],
            'legacy': getValueFromName(CHECK_STATUSES, data[i][2+INPUT_DIFF_COLS*j+8]),
          };
        } else if (stat == 2) {
          payload.body[MUSIC_DIFFS[j]] = {
            'stat': stat, 'score': data[i][2+INPUT_DIFF_COLS*j+7],
            'legacy': getValueFromName(CHECK_STATUSES, data[i][2+INPUT_DIFF_COLS*j+8]),
          };
        } else if (stat == 0) {
          payload.body[MUSIC_DIFFS[j]] = {
            'stat': stat
          };
        }
      }
      var response = UrlFetchApp.fetch(SKILL_EDIT_URI, {
        'method': 'post', 'payload': JSON.stringify(payload)
      });
      var result = JSON.parse(response.getContentText('utf-8'));
      if (result) {
        SpreadsheetApp.getActiveSpreadsheet().toast(data[i][0], '更新成功', 1);
        var updateData = UPDATE_SHEET.getRange(i+1, 1, 1, 2+INPUT_DIFF_COLS*MUSIC_DIFFS.length+1).getValues();
        for (var j = 0; j < MUSIC_DIFFS.length; j++) {
          if (updateData[0][2+INPUT_DIFF_COLS*j+1]) {
            updateData[0][2+INPUT_DIFF_COLS*j+1] = "'" + new Number(updateData[0][2+INPUT_DIFF_COLS*j+1]).toFixed(2);
          }
        }
        CURRENT_SHEET.getRange(i+1, 1, 1, 2+INPUT_DIFF_COLS*MUSIC_DIFFS.length+1).setValues(updateData);
        isUpdate = true;
      }
    }
    // 待ち時間設定もしくは終了処理
    if (isUpdate && (i < data.length)) {
      Utilities.sleep(500);
      isUpdate = false;
    } else if (i == (data.length-1)) {
      var payload = {'user_id': user_id, 'password': password};
      var response = UrlFetchApp.fetch(EDIT_FIX_URI, {
        'method': 'post', 'payload': JSON.stringify(payload)
      });
    }
  }

  Browser.msgBox('登録データの更新が完了しました');
}
