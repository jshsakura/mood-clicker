// Language switcher shared by both pages. The first pick happens in an inline script in <head>
// so the page never paints in the wrong language; this file only reacts to the switcher.
(function () {
  "use strict";
  var LANGS = ["ko", "en", "ja"];
  var root = document.documentElement;

  function apply(lang) {
    root.setAttribute("data-lang", lang);
    root.lang = lang;
    var title = root.getAttribute("data-title-" + lang);
    if (title) document.title = title;
    var desc = document.querySelector('meta[name="description"]');
    var descText = root.getAttribute("data-desc-" + lang);
    if (desc && descText) desc.setAttribute("content", descText);

    var buttons = document.querySelectorAll("[data-set-lang]");
    for (var i = 0; i < buttons.length; i++) {
      var on = buttons[i].getAttribute("data-set-lang") === lang;
      buttons[i].setAttribute("aria-pressed", on ? "true" : "false");
    }
    // Carry the choice across pages even when storage is blocked.
    var links = document.querySelectorAll("a[data-keep-lang]");
    for (var j = 0; j < links.length; j++) {
      links[j].setAttribute("href", links[j].getAttribute("data-keep-lang") + "?lang=" + lang);
    }
  }

  function choose(lang) {
    if (LANGS.indexOf(lang) < 0) return;
    apply(lang);
    try { localStorage.setItem("lang", lang); } catch (e) { /* storage blocked: the URL keeps it */ }
    try {
      var url = new URL(location.href);
      url.searchParams.set("lang", lang);
      history.replaceState(null, "", url.pathname + url.search + url.hash);
    } catch (e) { /* file:// or old browser: the page still switched */ }
  }

  var current = root.getAttribute("data-lang");
  apply(LANGS.indexOf(current) >= 0 ? current : "en");

  var buttons = document.querySelectorAll("[data-set-lang]");
  for (var k = 0; k < buttons.length; k++) {
    buttons[k].addEventListener("click", function (event) {
      choose(event.currentTarget.getAttribute("data-set-lang"));
    });
  }
})();
