(function () {
	'use strict';

	var KEY = 'atmaterial_brightness';
	var MIN = 50, MAX = 130, DEF = 100;

	function getVal() {
		var v = parseInt(localStorage.getItem(KEY), 10);
		return (isNaN(v) || v < MIN || v > MAX) ? DEF : v;
	}

	function apply(v) {
		document.documentElement.style.filter = 'brightness(' + v + '%)';
	}

	var css = '.atmat-brightness-btn{position:fixed;right:1rem;bottom:1rem;z-index:9999;width:2.6rem;height:2.6rem;border-radius:50%;border:none;background:#F47932;color:#fff;font-size:1.3rem;line-height:1;cursor:pointer;box-shadow:0 2px 8px rgba(0,0,0,.3);display:flex;align-items:center;justify-content:center}.atmat-brightness-panel{position:fixed;right:1rem;bottom:4rem;z-index:9999;width:15rem;background:#fff;border:1px solid #e4eaec;border-radius:6px;box-shadow:0 4px 16px rgba(0,0,0,.2);padding:.8rem 1rem;display:none;flex-direction:column;gap:.4rem}.atmat-brightness-panel.open{display:flex}.atmat-brightness-panel .title{font-size:.8rem;font-weight:600;color:#333;display:flex;justify-content:space-between;align-items:center}.atmat-brightness-panel input[type=range]{width:100%;accent-color:#F47932}.atmat-brightness-panel .row{display:flex;justify-content:space-between;align-items:center;font-size:.75rem;color:#666}.atmat-brightness-panel .reset{border:1px solid #e4eaec;border-radius:4px;background:#f9f9f9;color:#333;cursor:pointer;padding:.15rem .6rem}.atmat-brightness-panel .reset:hover{background:#e4eaec}';

	function init() {
		var v = getVal();
		apply(v);

		var btn = document.createElement('button');
		btn.className = 'atmat-brightness-btn';
		btn.type = 'button';
		btn.textContent = '\u2600';
		btn.title = '亮度调节';

		var panel = document.createElement('div');
		panel.className = 'atmat-brightness-panel';

		var title = document.createElement('div');
		title.className = 'title';
		var titleSpan = document.createElement('span');
		titleSpan.textContent = '亮度';
		var valueSpan = document.createElement('span');
		valueSpan.textContent = v + '%';
		title.appendChild(titleSpan);
		title.appendChild(valueSpan);

		var range = document.createElement('input');
		range.type = 'range';
		range.min = MIN;
		range.max = MAX;
		range.step = 5;
		range.value = v;

		var row = document.createElement('div');
		row.className = 'row';
		var hint = document.createElement('span');
		hint.textContent = MIN + '% - ' + MAX + '%';
		var reset = document.createElement('button');
		reset.type = 'button';
		reset.className = 'reset';
		reset.textContent = '重置 100%';

		row.appendChild(hint);
		row.appendChild(reset);
		panel.appendChild(title);
		panel.appendChild(range);
		panel.appendChild(row);

		var style = document.createElement('style');
		style.textContent = css;

		btn.addEventListener('click', function () {
			panel.classList.toggle('open');
		});
		range.addEventListener('input', function () {
			apply(range.value);
			valueSpan.textContent = range.value + '%';
		});
		range.addEventListener('change', function () {
			localStorage.setItem(KEY, range.value);
		});
		reset.addEventListener('click', function () {
			range.value = DEF;
			apply(DEF);
			valueSpan.textContent = DEF + '%';
			localStorage.setItem(KEY, DEF);
		});
		document.addEventListener('click', function (ev) {
			if (!panel.contains(ev.target) && !btn.contains(ev.target))
				panel.classList.remove('open');
		});

		document.body.appendChild(style);
		document.body.appendChild(btn);
		document.body.appendChild(panel);
	}

	if (document.readyState !== 'loading')
		init();
	else
		document.addEventListener('DOMContentLoaded', init);
})();
