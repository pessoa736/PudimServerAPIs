(function () {
  var path = window.location.pathname.split('/').pop() || 'index.html';
  var links = document.querySelectorAll('.nav a');

  links.forEach(function (link) {
    var href = (link.getAttribute('href') || '').replace('./', '');
    if (href === path) {
      link.classList.add('active');
    }
  });

  var year = document.getElementById('year');
  if (year) {
    year.textContent = new Date().getFullYear();
  }

  function escapeHtml(str) {
    return str
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;');
  }

  function applyLuaHighlight(text) {
    var src = escapeHtml(text);

    var placeholders = [];
    function keep(match, cls) {
      var token = '___TOK' + placeholders.length + '___';
      placeholders.push({ token: token, html: '<span class="' + cls + '">' + match + '</span>' });
      return token;
    }

    src = src.replace(/("(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*')/g, function (m) {
      return keep(m, 'tok-string');
    });
    src = src.replace(/(--[^\n]*)/g, function (m) {
      return keep(m, 'tok-comment');
    });

    src = src.replace(/\b(local|function|return|if|then|else|elseif|end|for|while|do|in|and|or|not|nil|true|false)\b/g, '<span class="tok-kw">$1</span>');
    src = src.replace(/\b(\d+(?:\.\d+)?)\b/g, '<span class="tok-num">$1</span>');
    src = src.replace(/\b(require|print|ipairs|pairs|tostring|tonumber|os|table|string|math|socket|cjson|log)\b/g, '<span class="tok-fn">$1</span>');

    placeholders.forEach(function (entry) {
      src = src.replace(entry.token, entry.html);
    });

    return src;
  }

  function applyShellHighlight(text) {
    var src = escapeHtml(text);

    src = src.replace(/(^|\n)(\s*#.*)/g, '$1<span class="tok-comment">$2</span>');
    src = src.replace(/("(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*')/g, '<span class="tok-string">$1</span>');
    src = src.replace(/\b(curl|lua|luarocks|openssl|mkdir|cd|export|echo)\b/g, '<span class="tok-fn">$1</span>');
    src = src.replace(/\b(\d+)\b/g, '<span class="tok-num">$1</span>');

    return src;
  }

  function detectLanguage(text) {
    var trimmed = text.trim();
    if (!trimmed) return 'plain';

    if (/^(curl|lua|luarocks|openssl|mkdir|cd)\b/m.test(trimmed) || /^\s*#/.test(trimmed)) {
      return 'shell';
    }

    if (
      /\b(local|function|return|end|nil|true|false)\b/.test(trimmed) ||
      /\brequire\("/.test(trimmed) ||
      /[A-Za-z_][\w]*:[A-Za-z_][\w]*\s*\(/.test(trimmed) ||
      /\{\s*[A-Za-z_][\w]*\s*=/.test(trimmed)
    ) {
      return 'lua';
    }

    return 'plain';
  }

  var codeBlocks = document.querySelectorAll('pre code');
  codeBlocks.forEach(function (block) {
    var raw = block.textContent || '';
    var lang = detectLanguage(raw);

    if (lang === 'lua') {
      block.innerHTML = applyLuaHighlight(raw);
      block.classList.add('lang-lua');
    } else if (lang === 'shell') {
      block.innerHTML = applyShellHighlight(raw);
      block.classList.add('lang-shell');
    }
  });
})();
