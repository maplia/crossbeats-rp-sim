var MAPLIA_BASE_URI = 'https://secure508.sakura.ne.jp/revbeta.maplia.jp/';
var COMMON_SCRIPT_URI = 'https://revrank.maplia.jp/' + 'script/revrank_common.js';

var RPSIM_EDIT_URI = MAPLIA_BASE_URI + 'bml_edit';

var MUSIC_DIFFS = ['esy', 'std', 'hrd', 'mas', 'unl'];
var GRADES = ['S++', 'S+', 'S', 'A+', 'A', 'B+', 'B', 'C', 'D', 'E'];
var WAIT_MSEC = 1500;
var DIALOG_TITLE = 'REV. RankPoint Simulator';
var DIALOG_FONT_SIZE = '1.7em';
var PROGRESS_OPTIONS = {
	title: DIALOG_TITLE, width: 300, height: 170, font_size: DIALOG_FONT_SIZE, detail_height: '3.2em'
};
var ALERT_OPTIONS = {
	title: DIALOG_TITLE, width: 300, height: 210, font_size: DIALOG_FONT_SIZE
};

var progress = null;
var userData = {};
var musicList = [];

// 待ち合わせダイアログの表示
function openProgressDialog(progress) {
	var deferred = $.Deferred();
	progress = $.progress(PROGRESS_OPTIONS);
	progress.open(function () {
		progress.cancel();
	});
	deferred.resolve();
	return deferred.promise();
}

// RPの更新
function updateRp(progress, postData, item) {
	if (progress.isCanceled()) {
		return $.Deferred.reject('処理がキャンセルされました').promise();
	} else {
		var deferred = $.Deferred();
		$.post(RPSIM_EDIT_URI, JSON.stringify(postData), function (response) {
			if (postData.type == 'music') {
				var logLabel = 'ミュージックRP [' + item.title + ']';
			} else {
				var logLabel = 'チャレンジRP [' + item.lookup_key + ']';
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
				alert('データベースの処理エラーが発生したため、チャレンジRPの更新をスキップします。');
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

// チャレンジRPの更新
function updateChallengeRp(progress, userData) {
	var deferred = $.Deferred();
	progress.setMessage1('チャレンジRPを更新中です');
	// RP対象曲一覧のチャレンジRP部分を参照する
	$.get('rplist', function (document) {
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
		var lookupKey = /challenge\/([^\.]+\.png)/.exec($(document).find('.rpc-image')[0].src)[1];
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
	$.each(musicList, function (i, musicItem) {
		chain = chain.then(function () {
			return updateMusicRp(progress, userData, musicItem);
		}).then(function () {
			return wait(WAIT_MSEC);
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
	$.get(musicItem.uri, function (document) {
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
				progress.incProgressbarValue();
				deferred.resolve();
			}).fail(function (e) {
				deferred.reject(e);
			});
		}
	});
	return deferred.promise();
}

// ミュージックRPの取得
function parseMusicRp(document, lookupKey) {
	var body = {};
	// ミュージックRPの取得
	$.each($(document).find('.pdm-result'), function (i, element) {
		var bodyDiff = {};
		// クリアランク + クリア状況
		var grade = parseInt(/grade_(\d+).png/.exec($(element).find('.grade img')[0].src)[1]) + 1;
		if (grade == GRADES.length + 2) {
			bodyDiff.stat = 0;			// プレイなし
		} else if (grade == GRADES.length + 1) {
			bodyDiff.stat = 2;			// クリア失敗
		} else {
			bodyDiff.stat = 1;			// クリア
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
			var gauge = /bnr_(\w+)_CLEAR.png/.exec(gaugeSrc)[1];
			if (gauge == 'SURVIVAL') {
				bodyDiff.gauge = 1;		// SURVIVAL
			} else if (gauge == 'ULTIMATE') {
				bodyDiff.gauge = 2;		// ULTIMATE
			} else {
				bodyDiff.gauge = 0;		// ゲージオプションなし
			}
			// フルコンボ
			if ($(element).find('.fullcombo').length == 1) {
				var notes = parseInt(/Note:(\d+)/.exec($(element).find('.note')[0].textContent)[1]);
				var score = parseInt($(element).find('.pdResultList dd')[0].textContent);
				if (notes * 100 == score) {
					bodyDiff.combo = 2; // フルコンボ（All Flawless）
				} else {
					bodyDiff.combo = 1; // フルコンボ
				}
			} else {
				bodyDiff.combo = 0;		// フルコンボなし
			}
		}
		body[MUSIC_DIFFS[i]] = bodyDiff;
	});
	return {
		'type': 'music',
		'body': body
	};
}

$('body').css('cursor', 'wait');
$.getScript(COMMON_SCRIPT_URI).done(function () {
	initJQueryUiDialog().done(function() {
		return openProgressDialog(progress);
	}).then(function () {
		return loginToRpSim(progress, userData);
	}).then(function () {
		return getMusicList(progress, musicList, true);
	}).then(function () {
		return updateChallengeRp(progress, userData);
	}).then(function () {
		return updateMusicRps(progress, userData, musicList);
	}).done(function () {
		$('body').css('cursor', 'auto');
		progress.close();
		return $.alert('REV. RankPoint Simulatorの更新が完了しました。', ALERT_OPTIONS);
	}).fail(function (e) {
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
