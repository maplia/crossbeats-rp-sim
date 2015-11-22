var input_table_id = '#table_input';
var chart_table_id = '#table_chart';
var history_table_id = '#table_history';
var mtime_p_id = '#p_mtime';

$.cookie.json = true;
var cookie_expires = 10;

function getMusicKey(music) {
  var name = music.mid;
  if (music.diff != undefined) {
    name = name + '_' + music.diff;
  }

  return name;
}

function getScoreDateKey(date) {
  return date.strftime('score_%Y%m%d');
}

function initialize() {
  var playData = loadPlayData(event_id, data.event_musics);

  createInputTable($(input_table_id), data.event_musics, playData);
  createChartTable($(chart_table_id), data.event_musics, playData);

  if (span != undefined) {
    var dates = [];
    for (var date = new Date(span.span_s); date <= span.span_e; date.setDate(date.getDate() + 1)) {
      dates[dates.length] = new Date(date);
    }
    createHistoryTable($(history_table_id), data.event_musics, dates, playData);
  }

  if (playData.mtime != undefined) {
    $(mtime_p_id).text('最終更新時刻: ' + playData.mtime);
  }
}

function loadPlayData(event_id, event_musics) {
  var playData = ($.cookie(event_id) || {});

  $.each(event_musics, function (i, music) {
    var key = getMusicKey(music);
    if (playData[key] == undefined) {
      playData[key] = {};
    }
  });

  return playData;
}

function createInputTable(table, event_musics, playdata) {
  var table_data = {};
  table_data.tbody = [];

  $.each(event_musics, function (i, music) {
    var key = getMusicKey(music);

    var input = $('<input type="text" />').attr({
      name: getMusicKey(music), maxLength: 5, size: 5
    });
    if (!isNaN(playdata[key].score)) {
      input.attr({value: playdata[key].score});
    }

    table_data.tbody[i] = {
      class_name: music.diff,
      values: [music.title, input]
    };
  });

  table.json2table(table_data);
}

function createChartTable(table, event_musics, playdata) {
  var note_sum = 0;
  var max_score_sum = 0;
  var score_sum = 0;
  var loss_sum = 0;
  var table_data = {};
  table_data.thead = [];
  table_data.tbody = [];
  table_data.tfoot = [];
  if (mobile) {
    table_data.thead_column_classes = [
      '', 'score', 'score', 'score', 'rate'
    ];
    table_data.tbody_column_classes = [
      '', 'score', 'score', 'score', 'rate'
    ];
    table_data.tfoot_column_classes = [
      '', 'score', 'score', 'score', 'rate'
    ];
    table_data.thead[0] = {
      values: ['Title', 'MAX', 'Score', 'Loss', '%']
    };
  } else {
    table_data.thead_column_classes = [
      '', 'notes', 'score', 'score', 'score', 'rate'
    ];
    table_data.tbody_column_classes = [
      '', 'notes', 'score', 'score', 'score', 'rate'
    ];
    table_data.tfoot_column_classes = [
      '', 'notes', 'score', 'score', 'score', 'rate'
    ];
    table_data.thead[0] = {
      values: ['Title', 'Notes', 'MAX', 'Score', 'Loss', '%']
    };
  }

  $.each(event_musics, function (i, music) {
    var key = getMusicKey(music);
    var max_score = music.notes * 100;

    var score = parseInt(playdata[key].score || '0');
    var loss = max_score - score;
    var rate_obj = new Number(score / max_score * 100);

    note_sum = note_sum + music.notes;
    max_score_sum = max_score_sum + max_score;
    score_sum = score_sum + score;
    loss_sum = loss_sum + loss;

    if (mobile) {
      table_data.tbody[i] = {
        class_name: music.diff,
        values: [
          music.title,
          max_score, score, loss, rate_obj.toFixed(2)+'%']
      };
    } else {
      table_data.tbody[i] = {
        class_name: music.diff,
        values: [
          music.title,
          music.notes, max_score, score, loss, rate_obj.toFixed(2)+'%']
      };
    }
  });

  var rate_sum_obj = new Number(score_sum / max_score_sum * 100);

  if (mobile) {
    table_data.tfoot[0] = {
      values: [
        'Total',
        max_score_sum, score_sum, loss_sum, rate_sum_obj.toFixed(2)+'%']
    };
  } else {
    table_data.tfoot[0] = {
      values: [
        'Total',
        note_sum, max_score_sum, score_sum, loss_sum, rate_sum_obj.toFixed(2)+'%']
    };
  }

  table.json2table(table_data);
}

function createHistoryTable(table, event_musics, dates, playdata) {
  var table_data = {};
  table_data.thead = [];
  table_data.tbody = [];
  table_data.thead_column_classes = [];
  table_data.thead_column_classes[0] = '';
  table_data.tbody_column_classes = [];
  table_data.tbody_column_classes[0] = '';
  $.each(dates, function (i, date) {
    table_data.thead_column_classes[i+1] = 'score';
    table_data.tbody_column_classes[i+1] = 'score';
  });

  table_data.thead[0] = {};
  table_data.thead[0].values = [];
  table_data.thead[0].values[0] = 'Title';
  $.each(dates, function (i, date) {
    table_data.thead[0].values[i+1] = date.strftime('%m/%d');
  });

  $.each(event_musics, function (i, music) {
    table_data.tbody[i] = {};
    table_data.tbody[i].class_name = music.diff;

    table_data.tbody[i].values = [];
    table_data.tbody[i].values[0] = music.title;
    $.each(dates, function (j, date) {
      var music_key = getMusicKey(music);
      var date_key = getScoreDateKey(date);

      if (playdata[music_key] == undefined) {
        table_data.tbody[i].values[j+1] = '';
      } else {
        table_data.tbody[i].values[j+1] = playdata[music_key][date_key] || '';
      }
    });
  });

  table.json2table(table_data);
}

function submitScores() {
  var date = new Date();
  var playData = loadPlayData(event_id, data.event_musics);

  $.each(data.event_musics, function (i, music) {
    var music_key = getMusicKey(music);
    var date_key = getScoreDateKey(date);
    var score = parseInt($('[name="' + music_key + '"]')[0].value);

    playData[music_key].score = score;
    playData[music_key][date_key] = score;
  });
  playData.mtime = date.strftime('%Y/%m/%d %H:%M:%S');

  $.cookie(event_id, playData, {expires: cookie_expires});

  initialize();
}
