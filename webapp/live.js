// reloads the page when a new commit lands on main
(function () {
  var seen = null;
  setInterval(function () {
    fetch('/.version', { cache: 'no-store' })
      .then(function (r) { return r.ok ? r.text() : null; })
      .then(function (v) {
        if (v === null) return;
        if (seen !== null && v !== seen) location.reload();
        seen = v;
      })
      .catch(function () {});
  }, 2000);
})();
