var VERSION = '20180506';

// URL
var HOSTNAME = 'https://revtest.maplia.jp/sunrise';
var AUTHORIZE_URI = HOSTNAME + '/api/authorize';
var GET_SKILLS_URI = HOSTNAME + '/api/skills/:user_id';
var SKILL_EDIT_URI = HOSTNAME + '/api/edit';
var EDIT_FIX_URI = HOSTNAME + '/api/edit_fix';

// シート名
var INPUT_SHEET = SpreadsheetApp.getActiveSpreadsheet().getSheetByName('入力シート');
var TEMPLATE_SHEET = SpreadsheetApp.getActiveSpreadsheet().getSheetByName('入力テンプレート');
var CURRENT_SHEET = SpreadsheetApp.getActiveSpreadsheet().getSheetByName('登録データ');
var UPDATE_SHEET = SpreadsheetApp.getActiveSpreadsheet().getSheetByName('更新データ');

// 譜面種別
var MUSIC_DIFFS = ['esy', 'std', 'hrd', 'mas', 'unl'];
var ITEM_ROWS = MUSIC_DIFFS.length + 2;       // 曲名+譜面別成績+コメント

// プルダウン入力値
var STATS = ['プレイなし', 'クリア', 'クリア失敗'];
var RANKS = ['', 'S++', 'S+', 'S', 'A+', 'A', 'B+', 'B', 'C', 'D', 'E'];
var COMBO_STATUSES = ['', 'FC', 'EXC'];
var GAUGE_STATUSES = ['', 'SUV', 'ULT'];

// 入力シート列位置
var IDX_INP_TITLE    = 'A'.charCodeAt(0) - 'A'.charCodeAt(0);  // A列: タイトル
var IDX_INP_LEVEL    = 'B'.charCodeAt(0) - 'A'.charCodeAt(0);  // B列: レベル
var IDX_INP_STAT     = 'C'.charCodeAt(0) - 'A'.charCodeAt(0);  // C列: プレイ状況
var IDX_INP_RP       = 'E'.charCodeAt(0) - 'A'.charCodeAt(0);  // E列: RP
var IDX_INP_RATE     = 'G'.charCodeAt(0) - 'A'.charCodeAt(0);  // G列: クリアレート
var IDX_INP_RANK     = 'I'.charCodeAt(0) - 'A'.charCodeAt(0);  // I列: ランク
var IDX_INP_FC       = 'K'.charCodeAt(0) - 'A'.charCodeAt(0);  // K列: フルコンボ状況
var IDX_INP_GAUGE    = 'M'.charCodeAt(0) - 'A'.charCodeAt(0);  // M列: ゲージ種類
var IDX_INP_SCORE    = 'O'.charCodeAt(0) - 'A'.charCodeAt(0);  // O列: スコア
var IDX_INP_FLAWLESS = 'Q'.charCodeAt(0) - 'A'.charCodeAt(0);  // Q列: Flawless数
var IDX_INP_SUPER    = 'R'.charCodeAt(0) - 'A'.charCodeAt(0);  // R列: Super数
var IDX_INP_COOL     = 'S'.charCodeAt(0) - 'A'.charCodeAt(0);  // S列: Cool数
var IDX_INP_MAXCOMBO = 'T'.charCodeAt(0) - 'A'.charCodeAt(0);  // T列: MaxCombo数
var IDX_INP_COMMENT  = 'C'.charCodeAt(0) - 'A'.charCodeAt(0);  // C列: コメント

// 隠しシート列位置（基本: 曲情報）
var IDX_HDN_TITLE    = 'A'.charCodeAt(0) - 'A'.charCodeAt(0);  // A列: タイトル
var IDX_HDN_TEXTID   = 'B'.charCodeAt(0) - 'A'.charCodeAt(0);  // B列: 曲識別キー
// 隠しシート列位置（譜面別）
var IDX_HDN_STAT     = 'C'.charCodeAt(0) - 'C'.charCodeAt(0);  // C列: ESY プレイ状況
var IDX_HDN_RP       = 'D'.charCodeAt(0) - 'C'.charCodeAt(0);  // D列: ESY RP
var IDX_HDN_RATE     = 'E'.charCodeAt(0) - 'C'.charCodeAt(0);  // E列: ESY クリアレート
var IDX_HDN_RANK     = 'F'.charCodeAt(0) - 'C'.charCodeAt(0);  // F列: ESY ランク
var IDX_HDN_FC       = 'G'.charCodeAt(0) - 'C'.charCodeAt(0);  // G列: ESY フルコンボ状況
var IDX_HDN_GAUGE    = 'H'.charCodeAt(0) - 'C'.charCodeAt(0);  // H列: ESY ゲージ種類
var IDX_HDN_SCORE    = 'I'.charCodeAt(0) - 'C'.charCodeAt(0);  // I列: ESY スコア
var IDX_HDN_FLAWLESS = 'J'.charCodeAt(0) - 'C'.charCodeAt(0);  // J列: ESY Flawless数
var IDX_HDN_SUPER    = 'K'.charCodeAt(0) - 'C'.charCodeAt(0);  // K列: ESY Super数
var IDX_HDN_COOL     = 'L'.charCodeAt(0) - 'C'.charCodeAt(0);  // L列: ESY Cool数
var IDX_HDN_MAXCOMBO = 'M'.charCodeAt(0) - 'C'.charCodeAt(0);  // M列: ESY MaxCombo数
var HIDDEN_SHEET_DIFF_COLS = IDX_HDN_MAXCOMBO + 1;
// 隠しシート列位置（基本: コメント）
var IDX_HDN_COMMENT  = IDX_HDN_TEXTID + HIDDEN_SHEET_DIFF_COLS*MUSIC_DIFFS.length + 1;  // コメント

// 各シートの最大列数
var INPUT_SHEET_COLS = IDX_INP_MAXCOMBO + 1;      // 入力シート
var CURRENT_SHEET_COLS = IDX_HDN_COMMENT + 1;     // 登録データシートはコメント列が最後
var UPDATE_SHEET_COLS = CURRENT_SHEET_COLS + 3;   // 更新データシートは更新検出用の列を3つ追加

// ユーザ認証情報列位置
var IDX_USERID   = 'I'.charCodeAt(0) - 'A'.charCodeAt(0);       // ユーザID
var IDX_PASSWORD = 'L'.charCodeAt(0) - 'A'.charCodeAt(0);       // パスワード

// その他定数
var UNIT_SIZE = 30;               // 入力シート作成単位
var HEADER_ROWS = 1;              // ヘッダ部分行数
var UNITSCORE_FLAWLESS = 100;     // Flawless1個分のスコア
var MAGNIFICATION_NORM = 1.0;     // 未設定時のRP倍率
var MAGNIFICATION_SUV = 1.1;      // SUVのRP倍率
var MAGNIFICATION_ULT = 1.2;      // ULTのRP倍率
var MAGNIFICATIONS = [            // プルダウンとの関連づけ
  MAGNIFICATION_NORM, MAGNIFICATION_SUV, MAGNIFICATION_ULT
];

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
  return INPUT_SHEET.getRange(1, IDX_USERID+1).getValue();
}

function getPassword() {
  return INPUT_SHEET.getRange(1, IDX_PASSWORD+1).getValue();
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
    skillData[i].music.full_title = skillData[i].music.full_title.replace(/&#x2661;/g, '♡');
  }
  
  // -----------------------------
  // 入力シート作成/隠しシート準備
  // -----------------------------

  // 初期化
  INPUT_SHEET.insertRowAfter(INPUT_SHEET.getLastRow());
  INPUT_SHEET.getRange(INPUT_SHEET.getLastRow(), 1).setValue(' ');
  INPUT_SHEET.deleteRows(HEADER_ROWS+1, INPUT_SHEET.getLastRow()-HEADER_ROWS);
  INPUT_SHEET.insertRowsAfter(HEADER_ROWS+1, skillData.length*ITEM_ROWS-1);
  CURRENT_SHEET.clear();
  UPDATE_SHEET.clear();

  // 書式設定
  TEMPLATE_SHEET.getRange(1, 1, skillData.length*ITEM_ROWS, INPUT_SHEET_COLS).copyTo(INPUT_SHEET.getRange(HEADER_ROWS+1, 1));

  var musicCount = 0;

  for (var i = 0; i < skillData.length; i += UNIT_SIZE) {
    var inputFocusTopRow = HEADER_ROWS + i*ITEM_ROWS + 1;
    var updateFocusTopRow = i + 1;
    var inputFocusRows = (Math.min(UNIT_SIZE, skillData.length-i)) * ITEM_ROWS;
    var updateFocusRows = (Math.min(UNIT_SIZE, skillData.length-i));

    var inputSheetValues = INPUT_SHEET.getRange(inputFocusTopRow, 1, inputFocusRows, INPUT_SHEET_COLS).getValues();
    var inputSheetFormats = INPUT_SHEET.getRange(inputFocusTopRow, 1, inputFocusRows, INPUT_SHEET_COLS).getNumberFormats();
    var currentSheetValues = CURRENT_SHEET.getRange(updateFocusTopRow, 1, updateFocusRows, CURRENT_SHEET_COLS).getValues();
    var updateSheetFormulas = UPDATE_SHEET.getRange(updateFocusTopRow, 1, updateFocusRows, UPDATE_SHEET_COLS).getFormulas();

    for (var j = 0; j < UNIT_SIZE; j++) {
      var index = i + j;
      if (index >= skillData.length) {
        break;
      }
      var skill = skillData[index];
      var music = skill.music;
      var inputRelRow = j*ITEM_ROWS;
      var inputAbsRow = inputFocusTopRow + inputRelRow;
      var updateRelRow = j;
      var updateAbsRow = updateFocusTopRow + updateRelRow;

      // タイトル
      inputSheetValues[inputRelRow][IDX_INP_TITLE] = music.full_title;
      currentSheetValues[updateRelRow][IDX_HDN_TITLE] = music.full_title;
      updateSheetFormulas[updateRelRow][IDX_HDN_TITLE] = getA1Notation(CURRENT_SHEET.getRange(updateAbsRow, IDX_HDN_TITLE+1));
      // テキストID
      currentSheetValues[updateRelRow][IDX_HDN_TEXTID] = music.text_id;
      updateSheetFormulas[updateRelRow][IDX_HDN_TEXTID] = getA1Notation(CURRENT_SHEET.getRange(updateAbsRow, IDX_HDN_TEXTID+1));

      // 譜面別データ
      for (var k = 0; k < MUSIC_DIFFS.length; k++) {
        var diff_chart = music[MUSIC_DIFFS[k]];
        var diff_skill = skill[MUSIC_DIFFS[k]];
        var inputDiffRelRow = inputRelRow + (k+1);
        var inputDiffAbsRow = inputAbsRow + (k+1);
        var updateDiffLeftRelCol = 2 + HIDDEN_SHEET_DIFF_COLS*k;

        // 譜面が存在しない難易度の行は入力規則などを消す
        if ((diff_chart == undefined) || (diff_chart.level == null)) {
          inputSheetValues[inputDiffRelRow][IDX_INP_LEVEL]      = '－';
          inputSheetValues[inputDiffRelRow][IDX_INP_RP-1]       = '';
          inputSheetValues[inputDiffRelRow][IDX_INP_RATE-1]     = '';
          inputSheetValues[inputDiffRelRow][IDX_INP_RANK-1]     = '';
          inputSheetValues[inputDiffRelRow][IDX_INP_FC-1]       = '';
          inputSheetValues[inputDiffRelRow][IDX_INP_GAUGE-1]    = '';
          inputSheetValues[inputDiffRelRow][IDX_INP_SCORE-1]    = '';
          inputSheetValues[inputDiffRelRow][IDX_INP_FLAWLESS-1] = '';
          INPUT_SHEET.getRange(inputDiffAbsRow, IDX_INP_STAT+1).clearDataValidations();
          INPUT_SHEET.getRange(inputDiffAbsRow, IDX_INP_RATE+1).clearDataValidations();
          INPUT_SHEET.getRange(inputDiffAbsRow, IDX_INP_RANK+1).clearDataValidations();
          INPUT_SHEET.getRange(inputDiffAbsRow, IDX_INP_FC+1).clearDataValidations();
          INPUT_SHEET.getRange(inputDiffAbsRow, IDX_INP_GAUGE+1).clearDataValidations();
          continue;
        }

        // レベル
        inputSheetValues[inputDiffRelRow][IDX_INP_LEVEL] = diff_chart.level;
        // RP入力範囲（入力制限設定）
        var rp_rule = SpreadsheetApp.newDataValidation().requireNumberBetween(0, diff_chart.level*MAGNIFICATION_ULT).setAllowInvalid(false).build();
        INPUT_SHEET.getRange(inputDiffAbsRow, IDX_INP_RP+1).setDataValidation(rp_rule);
        // スコア入力範囲（入力制限設定）
        var score_rule = SpreadsheetApp.newDataValidation().requireNumberBetween(0, diff_chart.notes*UNITSCORE_FLAWLESS).setAllowInvalid(false).build();
        INPUT_SHEET.getRange(inputDiffAbsRow, IDX_INP_SCORE+1).setDataValidation(score_rule);
        // 判定数入力範囲（入力制限設定）
        var notes_rule = SpreadsheetApp.newDataValidation().requireNumberBetween(0, diff_chart.notes).setAllowInvalid(false).build();
        INPUT_SHEET.getRange(inputDiffAbsRow, IDX_INP_FLAWLESS+1).setDataValidation(notes_rule);
        INPUT_SHEET.getRange(inputDiffAbsRow, IDX_INP_SUPER+1).setDataValidation(notes_rule);
        INPUT_SHEET.getRange(inputDiffAbsRow, IDX_INP_COOL+1).setDataValidation(notes_rule);
        INPUT_SHEET.getRange(inputDiffAbsRow, IDX_INP_MAXCOMBO+1).setDataValidation(notes_rule);
        // プレイ状態
        inputSheetValues[inputDiffRelRow][IDX_INP_STAT] = STATS[diff_skill.stat];
        currentSheetValues[updateRelRow][updateDiffLeftRelCol+IDX_HDN_STAT] = STATS[diff_skill.stat];
        // 以下はクリアのデータがあるときのみ反映
        if (diff_skill.stat == 1) {
          // RP
          inputSheetValues[inputDiffRelRow][IDX_INP_RP] = diff_skill.point;
          if (diff_skill.point) {
            currentSheetValues[updateRelRow][updateDiffLeftRelCol+IDX_HDN_RP] = "'" + new Number(diff_skill.point).toFixed(2);
          }
          // クリアレート
          inputSheetValues[inputDiffRelRow][IDX_INP_RATE] = diff_skill.rate/100.00;
          currentSheetValues[updateRelRow][updateDiffLeftRelCol+IDX_HDN_RATE] = diff_skill.rate/100.00;
          // ランク
          inputSheetValues[inputDiffRelRow][IDX_INP_RANK] = RANKS[diff_skill.rank];
          currentSheetValues[updateRelRow][updateDiffLeftRelCol+IDX_HDN_RANK] = RANKS[diff_skill.rank];
          // コンボ
          inputSheetValues[inputDiffRelRow][IDX_INP_FC] = COMBO_STATUSES[diff_skill.combo];
          currentSheetValues[updateRelRow][updateDiffLeftRelCol+IDX_HDN_FC] = COMBO_STATUSES[diff_skill.combo];
          // ゲージ
          inputSheetValues[inputDiffRelRow][IDX_INP_GAUGE] = GAUGE_STATUSES[diff_skill.gauge];
          currentSheetValues[updateRelRow][updateDiffLeftRelCol+IDX_HDN_GAUGE] = GAUGE_STATUSES[diff_skill.gauge];
        }
        // スコア
        inputSheetValues[inputDiffRelRow][IDX_INP_SCORE] = diff_skill.score;
        currentSheetValues[updateRelRow][updateDiffLeftRelCol+IDX_HDN_SCORE] = diff_skill.score;
        // 判定値
        inputSheetValues[inputDiffRelRow][IDX_INP_FLAWLESS] = diff_skill.flawless;
        inputSheetValues[inputDiffRelRow][IDX_INP_SUPER]    = diff_skill.super;
        inputSheetValues[inputDiffRelRow][IDX_INP_COOL]     = diff_skill.cool;
        inputSheetValues[inputDiffRelRow][IDX_INP_MAXCOMBO] = diff_skill.maxcombo;
        currentSheetValues[updateRelRow][updateDiffLeftRelCol+IDX_HDN_FLAWLESS] = diff_skill.flawless;
        currentSheetValues[updateRelRow][updateDiffLeftRelCol+IDX_HDN_SUPER]    = diff_skill.super;
        currentSheetValues[updateRelRow][updateDiffLeftRelCol+IDX_HDN_COOL]     = diff_skill.cool;
        currentSheetValues[updateRelRow][updateDiffLeftRelCol+IDX_HDN_MAXCOMBO] = diff_skill.maxcombo;
        // 更新シートへの数式貼りつけ
        updateSheetFormulas[updateRelRow][updateDiffLeftRelCol+IDX_HDN_STAT]     = getA1Notation(INPUT_SHEET.getRange(inputDiffAbsRow, IDX_INP_STAT+1));
        updateSheetFormulas[updateRelRow][updateDiffLeftRelCol+IDX_HDN_RP]       = getA1Notation(INPUT_SHEET.getRange(inputDiffAbsRow, IDX_INP_RP+1));
        updateSheetFormulas[updateRelRow][updateDiffLeftRelCol+IDX_HDN_RATE]     = 'IF('+ getA1Notation(INPUT_SHEET.getRange(inputDiffAbsRow, IDX_INP_RATE+1)) + '<>"",VALUE(' + getA1Notation(INPUT_SHEET.getRange(inputDiffAbsRow, IDX_INP_RATE+1)) + '),"")';
        updateSheetFormulas[updateRelRow][updateDiffLeftRelCol+IDX_HDN_RANK]     = getA1Notation(INPUT_SHEET.getRange(inputDiffAbsRow, IDX_INP_RANK+1));
        updateSheetFormulas[updateRelRow][updateDiffLeftRelCol+IDX_HDN_FC]       = getA1Notation(INPUT_SHEET.getRange(inputDiffAbsRow, IDX_INP_FC+1));
        updateSheetFormulas[updateRelRow][updateDiffLeftRelCol+IDX_HDN_GAUGE]    = getA1Notation(INPUT_SHEET.getRange(inputDiffAbsRow, IDX_INP_GAUGE+1));
        updateSheetFormulas[updateRelRow][updateDiffLeftRelCol+IDX_HDN_SCORE]    = getA1Notation(INPUT_SHEET.getRange(inputDiffAbsRow, IDX_INP_SCORE+1));
        updateSheetFormulas[updateRelRow][updateDiffLeftRelCol+IDX_HDN_FLAWLESS] = getA1Notation(INPUT_SHEET.getRange(inputDiffAbsRow, IDX_INP_FLAWLESS+1));
        updateSheetFormulas[updateRelRow][updateDiffLeftRelCol+IDX_HDN_SUPER]    = getA1Notation(INPUT_SHEET.getRange(inputDiffAbsRow, IDX_INP_SUPER+1));
        updateSheetFormulas[updateRelRow][updateDiffLeftRelCol+IDX_HDN_COOL]     = getA1Notation(INPUT_SHEET.getRange(inputDiffAbsRow, IDX_INP_COOL+1));
        updateSheetFormulas[updateRelRow][updateDiffLeftRelCol+IDX_HDN_MAXCOMBO] = getA1Notation(INPUT_SHEET.getRange(inputDiffAbsRow, IDX_INP_MAXCOMBO+1));
      }

      var inputCommentRelRow = inputRelRow + MUSIC_DIFFS.length + 1;
      var inputCommentAbsRow = inputAbsRow + MUSIC_DIFFS.length + 1;
      var updateCommentCol = 2 + HIDDEN_SHEET_DIFF_COLS*MUSIC_DIFFS.length;
      var updateDataCols = updateCommentCol + 1;

      // コメント
      inputSheetValues[inputCommentRelRow][IDX_INP_COMMENT] = skillData[index].comment;
      inputSheetFormats[inputCommentRelRow][IDX_INP_COMMENT] = '@';
      currentSheetValues[updateRelRow][updateCommentCol] = skillData[index].comment;
      updateSheetFormulas[updateRelRow][updateCommentCol] = getA1Notation(INPUT_SHEET.getRange(inputCommentAbsRow, IDX_INP_COMMENT+1));

      // 変更検出用数式設定
      updateSheetFormulas[updateRelRow][updateCommentCol+1] = 'JOIN(",",' + getA1Notation(CURRENT_SHEET.getRange(updateAbsRow, 1, 1, updateDataCols)) + ')';
      updateSheetFormulas[updateRelRow][updateCommentCol+2] = 'JOIN(",",' + getA1Notation(UPDATE_SHEET.getRange(updateAbsRow, 1, 1, updateDataCols)) + ')';
      updateSheetFormulas[updateRelRow][updateCommentCol+3] = getA1Notation(UPDATE_SHEET.getRange(updateAbsRow, updateCommentCol+1+1)) + '<>' + getA1Notation(UPDATE_SHEET.getRange(updateAbsRow, updateCommentCol+2+1));

      musicCount++;
      skillData[index] = null;
    }

    INPUT_SHEET.getRange(inputFocusTopRow, 1, inputFocusRows, INPUT_SHEET_COLS).setValues(inputSheetValues);
    INPUT_SHEET.getRange(inputFocusTopRow, 1, inputFocusRows, INPUT_SHEET_COLS).setNumberFormats(inputSheetFormats);
    CURRENT_SHEET.getRange(updateFocusTopRow, 1, updateFocusRows, CURRENT_SHEET_COLS).setValues(currentSheetValues);
    UPDATE_SHEET.getRange(updateFocusTopRow, 1, updateFocusRows, UPDATE_SHEET_COLS).setFormulas(updateSheetFormulas);

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
  var data = UPDATE_SHEET.getRange(1, 1, UPDATE_SHEET.getLastRow(), UPDATE_SHEET_COLS).getValues();
  for (var i = 0; i < data.length; i++) {
    var isUpdate = data[i][UPDATE_SHEET.getLastColumn()-1];   // 更新フラグは最終列
    if (isUpdate) {
      var payload = {
        'user_id': user_id, 'password': password, 'text_id': data[i][IDX_HDN_TEXTID],
        'body': {
          'comment': encodeURIComponent(data[i][IDX_HDN_COMMENT])
        }
      };
      for (var j = 0; j < MUSIC_DIFFS.length; j++) {
        var inputDiffAbsRow = HEADER_ROWS + i*ITEM_ROWS + 1+j+1;
        var updateDiffLeftRelCol = 2 + HIDDEN_SHEET_DIFF_COLS*j;

        var stat = getValueFromName(STATS, data[i][updateDiffLeftRelCol+IDX_HDN_STAT]);
        if (stat == 1) {
          var level = INPUT_SHEET.getRange(inputDiffAbsRow, IDX_INP_LEVEL+1).getValue();
          var point = parseFloat(data[i][updateDiffLeftRelCol+IDX_HDN_RP]);
          var rate = parseFloat(data[i][updateDiffLeftRelCol+IDX_HDN_RATE]);
          var gauge = getValueFromName(GAUGE_STATUSES, data[i][updateDiffLeftRelCol+IDX_HDN_GAUGE]);
          var bonus_rate = MAGNIFICATIONS[gauge];
          var flawless = INPUT_SHEET.getRange(inputDiffAbsRow, IDX_INP_FLAWLESS+1).getValue();
          var super = INPUT_SHEET.getRange(inputDiffAbsRow, IDX_INP_SUPER+1).getValue();
          var cool = INPUT_SHEET.getRange(inputDiffAbsRow, IDX_INP_COOL+1).getValue();
          var maxcombo = INPUT_SHEET.getRange(inputDiffAbsRow, IDX_INP_MAXCOMBO+1).getValue();
          if (!isNaN(flawless) && !isNaN(super) && !isNaN(cool) && !isNaN(maxcombo) && isNaN(rate)) {
            // 判定数が入っていてかつクリアレートがないときはクリアレートを補完（判定数からの計算は小数第2位まで求める）
            var notes = INPUT_SHEET.getRange(inputDiffAbsRow, IDX_INP_FLAWLESS+1).getDataValidation().getCriteriaValues()[1];
            rate = Math.floor(Math.multiply(((flawless + super) * 0.8 + cool * 0.4 + maxcombo * 0.2) / notes, 10000)) / 10000.0;
            INPUT_SHEET.getRange(inputDiffAbsRow, IDX_INP_RATE+1).setValue(rate);
          }
          if (isNaN(point) && !isNaN(rate)) {
            // RPを補完
            point = Math.multiply(Math.multiply(level, rate), bonus_rate);
            point = Math.floor(Math.multiply(point, 100)) / 100.0;
            INPUT_SHEET.getRange(inputDiffAbsRow, IDX_INP_RP+1).setValue(point);
            rate = Math.multiply(rate, 100);
          } else if (!isNaN(point) && isNaN(rate)) {
            // クリアレートを補完（RPからの計算は小数点以下切り捨て）
            rate = Math.floor(Math.multiply(point / bonus_rate / level, 10000) / 100.0) / 100.0;
            INPUT_SHEET.getRange(inputDiffAbsRow, IDX_INP_RATE+1).setValue(rate);
          } else {
            rate = Math.multiply(rate, 100);
          }
          payload.body[MUSIC_DIFFS[j]] = {
            'stat': stat, 'point': point, 'rate': rate, 'gauge': gauge,
            'rank': getValueFromName(RANKS, data[i][updateDiffLeftRelCol+IDX_HDN_RANK]),
            'combo': getValueFromName(COMBO_STATUSES, data[i][updateDiffLeftRelCol+IDX_HDN_FC]),
            'score': data[i][updateDiffLeftRelCol+IDX_HDN_SCORE],
            'flawless': flawless, 'super': super, 'cool': cool, 'maxcombo': maxcombo,
          };
        } else if (stat == 2) {
          payload.body[MUSIC_DIFFS[j]] = {
            'stat': stat, 'score': data[i][updateDiffLeftRelCol+IDX_HDN_SCORE],
            'flawless': flawless, 'super': super, 'cool': cool, 'maxcombo': maxcombo,
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
        var updateData = UPDATE_SHEET.getRange(i+1, 1, 1, 2+HIDDEN_SHEET_DIFF_COLS*MUSIC_DIFFS.length+1).getValues();
        for (var j = 0; j < MUSIC_DIFFS.length; j++) {
          var updateDiffLeftRelCol = 2 + HIDDEN_SHEET_DIFF_COLS*j;
          if (updateData[0][updateDiffLeftRelCol+IDX_HDN_RP]) {
            updateData[0][updateDiffLeftRelCol+IDX_HDN_RP] = "'" + new Number(updateData[0][updateDiffLeftRelCol+IDX_HDN_RP]).toFixed(2);
          }
        }
        CURRENT_SHEET.getRange(i+1, 1, 1, CURRENT_SHEET_COLS).setValues(updateData);
        isUpdate = true;
      }
    }
    // 待ち時間設定もしくは終了処理
    if (isUpdate && (i < data.length)) {
      Utilities.sleep(500);
      isUpdate = false;
    }
  }

  var payload = {'user_id': user_id, 'password': password};
  var response = UrlFetchApp.fetch(EDIT_FIX_URI, {
    'method': 'post', 'payload': JSON.stringify(payload)
  });

  Browser.msgBox('登録データの更新が完了しました');
}
