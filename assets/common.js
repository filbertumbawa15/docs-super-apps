// Sinkronkan tema (data-theme dari viewer, atau preferensi sistem) ke data-bs-theme milik Bootstrap
(function () {
  var root = document.documentElement;
  var mq = window.matchMedia ? window.matchMedia('(prefers-color-scheme: dark)') : null;
  function apply() {
    var t = root.getAttribute('data-theme');
    if (t !== 'dark' && t !== 'light') t = mq && mq.matches ? 'dark' : 'light';
    if (root.getAttribute('data-bs-theme') !== t) root.setAttribute('data-bs-theme', t);
  }
  apply();
  new MutationObserver(apply).observe(root, { attributes: true, attributeFilter: ['data-theme'] });
  if (mq && mq.addEventListener) mq.addEventListener('change', apply);
})();

document.addEventListener('DOMContentLoaded', function () {
  // Tombol salin untuk setiap blok kode
  document.querySelectorAll('.code-wrap').forEach(function (wrap) {
    var pre = wrap.querySelector('pre');
    var btn = document.createElement('button');
    btn.type = 'button';
    btn.className = 'btn btn-sm btn-copy';
    btn.textContent = 'Salin';
    btn.addEventListener('click', function () {
      var text = pre.innerText;
      var done = function () { btn.textContent = 'Tersalin'; setTimeout(function () { btn.textContent = 'Salin'; }, 1500); };
      try {
        navigator.clipboard.writeText(text).then(done, function () { btn.textContent = 'Gagal'; });
      } catch (e) { btn.textContent = 'Gagal'; }
    });
    wrap.appendChild(btn);
  });

  // Label sel untuk tabel .stack di layar sempit
  var label = function () {
    document.querySelectorAll('.stack td:not([data-l])').forEach(function (c) {
      var i = 0, p = c;
      while ((p = p.previousElementSibling)) i += p.colSpan;
      var head = c.closest('table').rows[0].cells[i];
      c.dataset.l = head ? head.textContent.trim() : '';
    });
  };
  label();
  new MutationObserver(label).observe(document.body, { childList: true, subtree: true });
});
