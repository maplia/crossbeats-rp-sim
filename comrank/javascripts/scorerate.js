var select_music_id = '#select_music';
var rate_table_id = '#table_rate';

function initialize() {
  createSelect($(select_music_id), data);
}

function calcScoreRate() {
  var selected_music = getSelectedMusic($(selected_music_id), data);
  var selected_diff = $('[name="diff"]:checked').val();
  var inputed_score = parseInt($('[name="score"]')[0].value);
  var table = $(rate_table_id);

  $.each(data, function (i, music) {
    if (music.text_id == $(select_music_id).val()) {
      selected_music = music;
      return true;
    }
  });

  var table_data = {};
  table_data.thead = [];
  table_data.tbody = [];
  if (mobile) {
    table_data.thead[0] = {
      values: ['レベル', '理論値', 'スコア', '得点率']
    };
    table_data.thead_column_classes = [
      'level', 'score', 'score', 'rate',
    ];
    table_data.tbody_column_classes = [
      'level', 'score', 'score', 'rate',
    ];
  } else {
    table_data.thead[0] = {
      values: ['タイトル', 'レベル', '理論値', 'スコア', '得点率']
    };
    table_data.thead_column_classes = [
      '', 'level', 'score', 'score', 'rate',
    ];
    table_data.tbody_column_classes = [
      '', 'level', 'score', 'score', 'rate',
    ];
  }

  if (mobile) {
    table_data.tbody[0] = {
      class_name: selected_diff,
      values: [
        selected_music[selected_diff].level, selected_music[selected_diff].notes * 100,
        inputed_score,
        new Number(inputed_score / selected_music[selected_diff].notes).toFixed(2)+'%'
      ]
    };
  } else {
    table_data.tbody[0] = {
      class_name: selected_diff,
      values: [
        selected_music.full_title + ' [' + selected_diff.toUpperCase() + ']',
        selected_music[selected_diff].level, selected_music[selected_diff].notes * 100,
        inputed_score,
        new Number(inputed_score / selected_music[selected_diff].notes).toFixed(2)+'%'
      ]
    };
  }

  table.json2table(table_data);
}
