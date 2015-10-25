var DEBUG = true;
if (!DEBUG) {
	console['log'] = function () {};
}

var JQUERY_UI_SCRIPT_URI = 'https://code.jquery.com/ui/1.11.4/jquery-ui.min.js';
var JQUERY_DIALOG_SCRIPT_URI = 'https://marines.sakura.ne.jp/script/jquery.dialog.js';
var JQUERY_RETRYAJAX_SCRIPT_URI = 'https://marines.sakura.ne.jp/script/jquery.retryAjax.js';
var JQUERY_UI_STYLE_URI = 'https://code.jquery.com/ui/1.11.4/themes/eggplant/jquery-ui.css';

var RPSIM_LOGIN_URI = MAPLIA_BASE_URI + 'bml_login';
var RPSIM_UPDATE_MASTER_URI = MAPLIA_BASE_URI + 'bml_update_master';
var RPSIM_LOGOUT_URI = MAPLIA_BASE_URI + 'bml_logout';

var MESSAGE_SESSION_IS_DEAD = '処理の途中でセッションが終了しました。最初からやり直してください。';

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

// RPシミュレータにログインする
function loginToRpSim(progress, userData) {
	var deferred = $.Deferred();
	// REV.ユーザIDの取得
	userData.revUserId = $('.u-profList li dl dd')[0].textContent;
	console.log('REV.ユーザID: ' + userData.revUserId);
	// REV.ユーザIDの登録確認
	progress.setMessage1('ユーザー登録を確認中です。');
	progress.setMessage2('');
	$.post(RPSIM_LOGIN_URI, 'game_id=' + userData.revUserId, function (response) {
		if (response.status != 200) {
			console.log('REV. RankPoint Simulator ユーザ未登録');
			deferred.reject('REV. RankPoint SimulatorにREV.ユーザーIDが登録されていません。');
		} else {
			console.log('REV. RankPoint Simulator ユーザ登録確認');
			userData.key = response.key;
			userData.user_id = response.user_id;
			deferred.resolve();
		}
	});
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

// ミュージックデータの取得
function parseMusicItem(document) {
	var item = {};
	// ミュージックRPページから取得する
	item.text_id = /\/([^\/]*).png/.exec($(document).find('.pdm-jkt')[0].src)[1];
	item.text_id = item.text_id.toLowerCase();
	item.text_id = item.text_id.replace(/[\_\-\(\)]/g, '');
	item.title = $(document).find('.title')[0].textContent;
	item.sort_key = /\/([^\/]*).png/.exec($(document).find('.pdm-jkt')[0].src)[1];
	$.each($(document).find('.pdm-result'), function (i, element) {
		var itemDiff = {};
		itemDiff.level = parseInt(/Lv.(\d+)/.exec($(element).find('.lv')[0].textContent)[1]);
		itemDiff.notes = parseInt(/Note:(\d+)/.exec($(element).find('.note')[0].textContent)[1]);
		item[MUSIC_DIFFS[i]] = itemDiff;
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
			var logLabel = 'チャレンジ [' + item.lookup_key + ']';
		}
		switch (response.status) {
		case 401: case 500:
			console.log(logLabel + ': 更新失敗');
			deferred.reject('マスタデータの更新に失敗しました。最初から操作をやり直してください。');
			break;
		default:
			console.log(logLabel + ': 更新成功');
			deferred.resolve();
			break;
		}
	});
	return deferred.promise();
}

// RPシミュレータからログアウトする
function logoutFromRpSim(progress, userData) {
	var deferred = $.Deferred();
	$.postWithRetries(RPSIM_LOGOUT_URI, 'key=' + userData.key, function (response) {
		if (response.status != 200) {
			console.log('ログアウト異常発生');
		} else {
			console.log('ログアウト');
		}
		deferred.resolve();
	});
	return deferred.promise();
}
