function shortenString(string) {
  var count = 0;
  for (var i = 0; i < string.length; i++) {
    if (/^[\x00-\x7F]*$/.test(string.substr(i, 1))) {
      count += 1;
    } else {
      count += 2;
    }
    if (count > 30) {
      break;
    }
  }
  if (i == string.length) {
    return string;
  } else {
    return string.substr(0, i) + '...';
  }
}

function createSelect(select, data) {
  $.each(data, function (i, item) {
    var option = $('<option />', {
      value: item.text_id
    });
    if (mobile) {
      option.html(shortenString(item.full_title));
    } else {
      option.html(item.full_title);
    }
    select.append(option);
  });
}

function getSelectedMusic(select, data) {
  var selected_music = null;
  $.each(data, function (i, music) {
    if (music.text_id == select.val()) {
      selected_music = music;
      return true;
    }
  });
  return selected_music;
}
