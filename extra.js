// Meridian brand: normalise the search placeholder to a plain "Search".
// pkgdown ships the built-in search input with "Search for..."; the house
// style is the shorter label. This only rewrites the placeholder text; the
// search behaviour is untouched.
document.addEventListener("DOMContentLoaded", function () {
  document
    .querySelectorAll('#search-input, input[type="search"], input.form-control[role="searchbox"]')
    .forEach(function (el) {
      el.setAttribute("placeholder", "Search");
      el.setAttribute("aria-label", "Search");
    });
});
