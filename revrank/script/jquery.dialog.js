(function(jQuery) {
	// プログレスダイアログ
	jQuery.progress = function (options) {
		options = options || {};
		if (jQuery('body').find('#progress-dialog').length == 0) {
			jQuery('body').append('<div id="progress-dialog"><table id="progress-table"><tbody><tr><td id="progress-message1"></td></tr><tr><td id="progress-message2"></td></tr><tr><td><div id="progressbar"></div></td></tr></tbody></table></div>');
		}
		jQuery('#progress-dialog').dialog({
			title: options.title || '', autoOpen: false, modal: true,
			width: options.width || 'auto', height: options.height || 'auto',
			draggable: false, resizable: false, closeOnEscape: false
//			buttons: {
//				'キャンセル': function () {
//					jQuery.progress.cancel();
//					if (jQuery.progress.cancelCallback) {
//						jQuery.progress.cancelCallback();
//					}
//				}
//			}
		});
		jQuery('.ui-dialog').css('z-index', '30000');
		jQuery('.ui-widget-overlay').css('z-index', '25000');
		jQuery('.ui-dialog-title').css('font-size', options.font_size);
		jQuery('.ui-button-text').css('font-size', options.font_size);
		jQuery('#progress-table').css('width', '100%');
		jQuery('#progress-dialog').css('font-size', options.font_size);
		jQuery('#progress-table tr td').css('height', options.font_size);
		jQuery('#progress-message2').css('height', options.detail_height || options.font_size);
		return this.extend(jQuery.progress, {
			open: function (cancelCallback) {
				this.canceled = false;
				this.cancelCallback = cancelCallback;
				jQuery('#progress-message1').text('');
				jQuery('#progress-massage2').text('');
				jQuery('#progressbar').progressbar({
					max: 0, value: false
				});
				jQuery('#progress-dialog').dialog('open');
				jQuery('.ui-dialog-titlebar-close').hide();
				return this;
			},
			close: function () {
				jQuery('#progress-dialog').dialog('close');
			},
			cancel: function () {
				console.log('canceled!');
				this.canceled = true;
			},
			isCanceled: function () {
				return this.canceled;
			},
			setMessage1: function (message) {
				jQuery('#progress-message1').text(message);
			},
			setMessage2: function (message) {
				jQuery('#progress-message2').text(message);
			},
			setProgressbarMax: function (max) {
				jQuery('#progressbar').progressbar({
					max: max, value: 0
				});
			},
			incProgressbarValue: function () {
				jQuery('#progressbar').progressbar('value', jQuery('#progressbar').progressbar('value') + 1);
			}
		});
	};
	// メッセージ表示ダイアログ
	jQuery.alert = function (message, options) {
		options = options || {};
		var deferred = jQuery.Deferred();
		if (jQuery('body').find('#alert-dialog').length == 0) {
			jQuery('body').append('<div id="alert-dialog"><p id="alert-message"></p></div>');
		}
		jQuery('#alert-dialog').dialog({
			title: options.title || '', autoOpen: false, modal: true,
			width: options.width || 'auto', height: options.height || 'auto',
			draggable: false, resizable: false, closeOnEscape: false,
			buttons: {
				'OK': function () {
					jQuery('#alert-dialog').dialog('close');
					deferred.resolve();
				}
			}
		});
		jQuery('.ui-dialog').css('z-index', '30000');
		jQuery('.ui-widget-overlay').css('z-index', '25000');
		jQuery('.ui-dialog-title').css('font-size', options.font_size);
		jQuery('.ui-button-text').css('font-size', options.font_size);
		jQuery('#alert-message').css('font-size', options.font_size);
		jQuery('#alert-message').text(message);
		jQuery('#alert-dialog').dialog('open');
		jQuery('.ui-dialog-titlebar-close').hide();
		return deferred.promise();
	};
	// 確認ダイアログ
	jQuery.confirm = function (message, options, acceptCallback, cancelCallback) {
		options = options || {};
		var deferred = jQuery.Deferred();
		jQuery.confirm.self = this;
		jQuery.confirm.self.acceptCallback = acceptCallback;
		jQuery.confirm.self.cancelCallback = cancelCallback;
		if (jQuery('body').find('#confirm-dialog').length == 0) {
			jQuery('body').append('<div id="confirm-dialog"><p id="confirm-message"></p></div>');
		}
		jQuery('#confirm-dialog').dialog({
			title: options.title || '', autoOpen: false, modal: true,
			width: options.width || 'auto', height: options.height || 'auto',
			draggable: false, resizable: false, closeOnEscape: false,
			buttons: {
				'はい': function () {
					jQuery('#confirm-dialog').dialog('close');
					jQuery.confirm.self.acceptCallback();
					deferred.resolve();
				},
				'いいえ': function () {
					jQuery('#confirm-dialog').dialog('close');
					jQuery.confirm.self.cancelCallback();
					deferred.reject();
				}
			}
		});
		jQuery('.ui-dialog').css('z-index', '30000');
		jQuery('.ui-widget-overlay').css('z-index', '25000');
		jQuery('.ui-dialog-title').css('font-size', options.font_size);
		jQuery('.ui-button-text').css('font-size', options.font_size);
		jQuery('#confirm-message').css('font-size', options.font_size);
		jQuery('#confirm-message').text(message);
		jQuery('#confirm-dialog').dialog('open');
		jQuery('.ui-dialog-titlebar-close').hide();
		return deferred.promise();
	};
})(jQuery);
