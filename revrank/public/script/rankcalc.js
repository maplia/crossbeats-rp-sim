var select_music_id = '#select_music';
var rank_chart_table_id = '#table_rank_chart';
var rate_chart_table_id = '#table_rate_chart';

var ranks = new Array('S++', 'S+', 'S', 'A+', 'A', 'B+', 'B', 'C');
var rates = new Array(1.00, 0.98, 0.95, 0.90, 0.85, 0.80, 0.75, 0.70);
var crates = new Array(1.00, 0.99, 0.98, 0.97, 0.96);

function getDiffName(diff) {
	return diff.toUpperCase();
}

function initialize() {
	createSelect($(select_music_id), data);
	createRankChart($(select_music_id), $(rank_chart_table_id), data);
	createRateChart($(select_music_id), $(rate_chart_table_id), data);
}

function changeChart() {
	createRankChart($(select_music_id), $(rank_chart_table_id), data);
	createRateChart($(select_music_id), $(rate_chart_table_id), data);
}

function createSelect(select, data) {
	$.each(data, function (i, item) {
		var option = $('<option />', {
			value: i
		});
		option.html(item.full_title);

		select.append(option);
	});
}

function createRankChart(select, table, data) {
	var table_data = {};
	table_data.thead = [];
	table_data.tbody = [];
	table_data.thead_column_classes = ['diff', 'level', 'notes'];
	$.each(ranks, function (i, rank) {
		table_data.thead_column_classes[table_data.thead_column_classes.length] = 'notes';
	});

	table_data.thead[0] = {
		values: ['＼', 'Lv', 'Notes']
	};
	$.each(ranks, function (i, rank) {
		table_data.thead[0].values[table_data.thead[0].values.length] = rank;
	});

	var item = data[parseInt(select.val())];

	$.each(diffs, function (i, diff) {
		var values = [getDiffName(diff), (item[diff].level || '-'), (item[diff].notes || '-')];

		var index = table_data.tbody.length;
		table_data.tbody[index] = {
			class_name: diff,
			values: values
		};

		$.each(rates, function (j, rate) {
			if (item[diff].notes) {
				var allow = Math.floor(item[diff].notes * (1 - rate));
				table_data.tbody[index].values[table_data.tbody[index].values.length] = allow;
			} else {
				table_data.tbody[index].values[table_data.tbody[index].values.length] = '-';
			}
		});
	});

	table.json2table(table_data);
}

function createRateChart(select, table, data) {
	var table_data = {};
	table_data.thead = [];
	table_data.tbody = [];
	table_data.thead_column_classes = ['diff', 'level', 'notes'];
	$.each(ranks, function (i, rank) {
		table_data.thead_column_classes[table_data.thead_column_classes.length] = 'notes';
	});

	table_data.thead[0] = {
		values: ['＼', 'Lv', 'Notes']
	};
	$.each(crates, function (i, crate) {
		table_data.thead[0].values[table_data.thead[0].values.length] = (crate * 100) + '%';
	});

	var item = data[parseInt(select.val())];

	$.each(diffs, function (i, diff) {
		var values = [getDiffName(diff), (item[diff].level || '-'), (item[diff].notes || '-')];

		var index = table_data.tbody.length;
		table_data.tbody[index] = {
			class_name: diff,
			values: values
		};

		$.each(crates, function (j, crate) {
			if (item[diff].notes) {
				var allow = Math.floor(item[diff].notes * (1 - crate) / 0.40);
				table_data.tbody[index].values[table_data.tbody[index].values.length] = allow;
			} else {
				table_data.tbody[index].values[table_data.tbody[index].values.length] = '-';
			}
		});
	});

	table.json2table(table_data);
}
