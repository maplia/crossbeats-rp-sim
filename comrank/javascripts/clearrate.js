var select_music_id = '#select_music';
var rate_table_id = '#table_rate';

function initialize() {
  createSelect($(select_music_id), data);
}

function calcClearRate() {
  var selected_music = getSelectedMusic($(select_music_id), data);
  var selected_diff = $('[name="diff"]:checked').val();
  var inputed_flawless = parseInt($('[name="flawless"]')[0].value);
  var inputed_super = parseInt($('[name="super"]')[0].value);
  var inputed_cool = parseInt($('[name="cool"]')[0].value);
  var inputed_maxcombo = parseInt($('[name="maxcombo"]')[0].value);
  var table = $(rate_table_id);
  var clearrate = ((inputed_flawless + inputed_super) * 0.8 + inputed_cool * 0.4 + inputed_maxcombo * 0.2) / selected_music[selected_diff].notes * 100;

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
      values: ['Lv', 'ノート数', 'クリアレート']
    };
    table_data.thead_column_classes = [
      '', 'score', 'rate',
    ];
    table_data.tbody_column_classes = [
      'level', 'score', 'rate',
    ];
  } else {
    table_data.thead[0] = {
      values: ['タイトル', 'レベル', 'ノート数', 'クリアレート']
    };
    table_data.thead_column_classes = [
      '', '', 'score', 'rate',
    ];
    table_data.tbody_column_classes = [
      '', 'level', 'score', 'rate',
    ];
  }

  if (mobile) {
    table_data.tbody[0] = {
      class_name: selected_diff,
      values: [
        selected_music[selected_diff].level, selected_music[selected_diff].notes,
        new Number(clearrate).toFixed(2)+'%'
      ]
    };
  } else {
    table_data.tbody[0] = {
      class_name: selected_diff,
      values: [
        selected_music.full_title + ' [' + selected_diff.toUpperCase() + ']',
        selected_music[selected_diff].level, selected_music[selected_diff].notes,
        new Number(clearrate).toFixed(2)+'%'
      ]
    };
  }

  table.json2table(table_data);
}
