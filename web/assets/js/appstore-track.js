// Tracks App Store link clicks in PostHog and tags each link with an App Store
// Connect campaign token (ct) so installs can be attributed per page/placement.
(function () {
  var SEL = 'a[href*="apps.apple.com"]';

  function placement(a) {
    if (a.closest('.header-icons')) return 'header';
    if (a.classList.contains('footer-link')) return 'footer';
    if (a.classList.contains('app-cta')) return 'pdf_cta';
    if (a.classList.contains('btn-download')) return 'cook_mode_page';
    return 'other';
  }

  function pageKey() {
    var p = location.pathname.replace(/^\/|\/$/g, '');
    if (!p) return 'home';
    var m = p.match(/^recipes\/(.+)$/);
    return m ? m[1] : p.replace(/\.html$/, '');
  }

  function campaign(a) {
    // Apple limits ct to 40 chars; keep it to letters, digits, dash, underscore.
    return (placement(a) + '_' + pageKey()).replace(/[^A-Za-z0-9_-]/g, '-').slice(0, 40);
  }

  function tag() {
    document.querySelectorAll(SEL).forEach(function (a) {
      try {
        var u = new URL(a.href);
        u.searchParams.set('ct', campaign(a));
        a.href = u.toString();
      } catch (e) {}
    });
  }

  document.addEventListener('click', function (e) {
    var a = e.target.closest && e.target.closest(SEL);
    if (!a || !window.posthog) return;
    posthog.capture('app_store_click', {
      placement: placement(a),
      page: pageKey(),
      campaign: campaign(a),
    });
  }, true);

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', tag);
  else tag();
})();
