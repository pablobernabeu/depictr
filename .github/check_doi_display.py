#!/usr/bin/env python3
"""Hold this repository's own DOIs to the family's display standard.

The same file sits at .github/check_doi_display.py in all seven repositories of
the family (scopusflow, scopusflow-py, depictr, depictr-py, theoryforge, pilotr,
lexsync), so change every copy together. It needs only the standard library. It
reads which DOIs are the repository's own from CITATION.cff (the top-level doi
and the doi identifiers), so it carries no per-repository settings and never
touches the DOIs of cited literature.

Crossref and DataCite ask for a DOI to be shown as a full https://doi.org/ link
whose text is the URL. The rules, over the tracked Markdown, R Markdown,
_pkgdown.yml, mkdocs.yml, inst/CITATION and docs/*.bib files:

1. No bare DOI in text: not as link text, not after "doi:" or "DOI", not
   unlinked. A DOI may stand outside a URL only in a BibTeX or code string, in
   inline code or in image alt text. inst/CITATION is held to this rule alone,
   since R prints its textVersion as it stands.
2. A https://doi.org/ URL is never left bare: write <https://doi.org/...>, which
   GitHub, pandoc (pkgdown, CRAN), Python-Markdown (mkdocs) and PyPI all link.
   A link to the DOI shows the URL as its text, uses no other resolver form
   (http://, dx.doi.org) and has no "doi:" or "DOI" label before it, and a
   quoted reference ends with it, with no full stop. A BibTeX url field gives
   the registry page (CRAN or PyPI), never the DOI a second time.
3. Each _pkgdown.yml gives the CRAN DOI once, in the Citation component, as
       [https://doi.org<wbr>/10.32614<wbr>/CRAN.package<wbr>.<pkg>](https://doi.org/10.32614/CRAN.package.<pkg>)
   on a line of its own, and pkgdown/extra.scss beside it carries the two rules
   that size that link and hide the README's DOI badge under Dev status.
4. Site pages (docs/, vignettes/), _pkgdown.yml and the mkdocs footer carry no
   DOI badge, and the mkdocs home page (docs/index.md) gives the Zenodo DOI as a
   full link.
5. A landing README (the repository root, or beside DESCRIPTION or
   pyproject.toml) ends its badge block with exactly one DOI badge: the CRAN DOI
   as a shields.io badge beside a DESCRIPTION, otherwise CITATION.cff's doi as
   Zenodo's own badge, with "DOI <doi>" as its alt text. Its Citation section
   gives the DOIs of what it describes as full links, and a README.Rmd and the
   README.md knitted from it agree.
6. A reference that gives CRAN as the source of what it cites names it in full,
   alike everywhere: "Comprehensive R Archive Network (CRAN)". That is the whole
   of a BibTeX or bibentry publisher, institution or organization field that
   names CRAN; in the text of a reference it stands just before the link, as
   "... R package version 0.4.0. Comprehensive R Archive Network (CRAN).
   <https://doi.org/...>"; and the full name never appears without the
   abbreviation after it. A reference to a CRAN DOI (10.32614/CRAN.package.<pkg>)
   gives that source, so inst/CITATION's bibentry and text version, the About
   page's reference and BibTeX entry, and a README's quoted reference all name
   it. NEWS.md and CHANGELOG.md are exempt, since they record what earlier
   versions said.

With --site DIR (a built pkgdown site, whose package is DIR/.. unless --package
says otherwise), it checks the built home page instead: that pkgdown's markup
still matches the two extra.scss rules and that the compiled stylesheet carries
them, so that a change in pkgdown cannot quietly bring back a second showing of
the DOI in the sidebar.

Machine-readable records keep the bare DOI and are not read: CITATION.cff,
codemeta.json, .zenodo.json and the BibTeX doi fields (allowed by rule 1).

Usage: python3 .github/check_doi_display.py [repository root]
       python3 .github/check_doi_display.py --site docs
"""
import argparse
import re
import subprocess
import sys
from html.parser import HTMLParser
from pathlib import Path

HIDE_RULE = 'aside .dev-status li:has(> a[href^="https://doi.org/"])'
SIZE_RULE = 'aside .citation p:has(> a[href^="https://doi.org/"])'
CRAN_NAME = "Comprehensive R Archive Network (CRAN)"
# A DOI link in a reference's text: an autolink, a Markdown link or an <a> element.
CRAN_DOI_LINK = r"(?:<a\s[^>]*>|\[|<)?https://doi\.org/10\.32614/CRAN\.package\."
# What marks a paragraph as a reference, not a sentence that mentions the DOI.
REFERENCE_MARK = r"R package version|\[(?:R package|Computer software)\]|\(Version "


def sidebar_link(pkg):
    doi = f"10.32614/CRAN.package.{pkg}"
    return (f"[https://doi.org<wbr>/10.32614<wbr>/CRAN.package<wbr>.{pkg}]"
            f"(https://doi.org/{doi})")


def package_name(folder):
    desc = folder / "DESCRIPTION"
    return re.search(r"^Package:\s*(\S+)", desc.read_text(encoding="utf-8"), re.M).group(1)


def section(text, heading="## Citation"):
    """The text under a level-two heading, up to the next level-one or -two heading."""
    m = re.search(r"^" + re.escape(heading) + r"[ \t]*$", text, re.M)
    if not m:
        return None
    end = re.search(r"^#{1,2} ", text[m.end():], re.M)
    return text[m.end():m.end() + end.start()] if end else text[m.end():]


def norm(s):
    return re.sub(r"\s+", " ", s).strip()


def check_cran_name(rel, text, prose, plain, report):
    """Rule 6: a reference names CRAN as CRAN_NAME, and one citing a CRAN DOI names it."""
    # A field, in a .bib, a bibentry() or a BibTeX entry built in an About page's code.
    for m in re.finditer(r"\b(publisher|institution|organization)\s*=\s*(\{+|\")(.*?)(\}+|\")", text):
        value = m.group(3).strip()
        if re.search(r"\bCRAN\b|R Archive Network", value) and value != CRAN_NAME:
            report(rel, text, m.start(), f"{m.group(1)} '{value}': write {CRAN_NAME}")
    # The bare abbreviation as a reference's source, just before its link.
    for m in re.finditer(r"(?<![\w(])CRAN\.(?=[ \t]*\n?[ \t>]*(?:<a\s|<|\[)?https?://)", prose):
        report(rel, prose, m.start(), f"a reference names its source in full: write '{CRAN_NAME}.'")
    for m in re.finditer(r"(?i)\bComprehensive\s+R\s+Archive\s+Network\b(?!\s+\(CRAN\))", prose):
        report(rel, prose, m.start(), f"give the abbreviation after the name: {CRAN_NAME}")
    if plain:
        # inst/CITATION: R concatenates the text version from string literals, so
        # they are joined before the source is looked for in front of the link.
        joined = "".join(re.findall(r'"((?:[^"\\]|\\.)*)"', text))
        if "https://doi.org/10.32614/CRAN.package." in joined and \
                not re.search(re.escape(CRAN_NAME) + r"\.\s*https://doi\.org/10\.32614/CRAN\.package\.", joined):
            report(rel, text, text.find("textVersion"),
                   f"the text version names its source before the DOI: '... {CRAN_NAME}. https://doi.org/...'")
    elif re.search(REFERENCE_MARK, text):
        # A paragraph that is a reference (it carries a version or a bracketed
        # description) and links a CRAN DOI gives the source just before the link.
        for para in re.finditer(r"(?:[^\n]|\n(?![ \t]*\n))+", prose):
            body = para.group(0)
            if re.search(REFERENCE_MARK, body) and re.search(CRAN_DOI_LINK, body):
                flat = norm(re.sub(r"(?m)^[ \t]*>[ \t]?", "", body))
                if not re.search(re.escape(CRAN_NAME) + r"\.\s*" + CRAN_DOI_LINK, flat):
                    report(rel, prose, para.start(),
                           f"a reference to a CRAN DOI names its source before the link: '{CRAN_NAME}.'")
    # A BibTeX entry that gives a CRAN DOI gives CRAN, in full, as its publisher.
    if re.search(r"\bdoi\s*=\s*\{10\.32614/CRAN\.package\.", text) and \
            not re.search(r"\bpublisher\s*=\s*\{" + re.escape(CRAN_NAME) + r"\}", text):
        report(rel, text, re.search(r"\bdoi\s*=\s*\{10\.32614/CRAN", text).start(),
               f"a BibTeX entry with a CRAN DOI gives publisher = {{{CRAN_NAME}}}")
    if plain and re.search(r'\bdoi\s*=\s*"10\.32614/CRAN\.package\.', text) and \
            not re.search(r'\bpublisher\s*=\s*"' + re.escape(CRAN_NAME) + '"', text):
        report(rel, text, text.find("bibentry"), f'the bibentry gives publisher = "{CRAN_NAME}"')


def check_repository(root):
    problems = []
    cff = (root / "CITATION.cff").read_text(encoding="utf-8")
    own_doi = re.search(r"^doi:\s*[\"']?(10\.\d{4,9}/[^\s\"']+)", cff, re.M).group(1)
    dois = sorted(set(re.findall(r"^(?:doi|\s+value):\s*[\"']?(10\.\d{4,9}/[^\s\"']+)", cff, re.M)))
    tracked = subprocess.run(["git", "-C", str(root), "ls-files"], capture_output=True,
                             text=True, check=True).stdout.splitlines()
    scanned = [f for f in tracked if re.search(
        r"\.(md|Rmd|qmd)$|(^|/)(_pkgdown|mkdocs)\.ya?ml$|(^|/)inst/CITATION$|(^|/)docs/[^/]+\.bib$", f)]

    def report(rel, text, pos, message):
        problems.append(f"{rel}:{text.count(chr(10), 0, pos) + 1}: {message}")

    def blank(match):
        return re.sub(r"[^\n]", " ", match.group(0))

    for rel in scanned:
        text = (root / rel).read_text(encoding="utf-8")
        # Alt text transcribes a badge's own text and an image URL is not prose, so
        # both are blanked. <wbr> is markup, not text, so it is dropped. Neither
        # touches a newline, so line numbers are counted on what is left.
        prose = re.sub(r"!\[[^\]]*\]\([^)]*\)|<img\b[^>]*>", blank, text).replace("<wbr>", "")
        pkgdown = re.search(r"(^|/)_pkgdown\.ya?ml$", rel)
        plain = rel.endswith("inst/CITATION")
        for doi in dois:
            d, url = re.escape(doi), f"https://doi.org/{doi}"
            for m in re.finditer(r"(?<![\w/{\"'`%])" + d, prose):
                report(rel, prose, m.start(), f"bare DOI {doi}: write " + (url if plain else f"<{url}>"))
            if plain:
                continue
            for m in re.finditer(r"(?:^|(?<=\s))https?://(?:dx\.)?doi\.org/" + d, prose, re.M):
                report(rel, prose, m.start(), f"bare URL: write <{url}>")
            for m in re.finditer(r"(?:^|(?<=[\s(]))(?:dx\.)?doi\.org/" + d, prose, re.M):
                report(rel, prose, m.start(), f"incomplete URL: write <{url}>")
            links = [(m, m.group(1)) for m in re.finditer(
                r"\[([^\]]*)\]\(https?://(?:dx\.)?doi\.org/" + d + r"\)", prose)]
            links += [(m, re.sub(r"<[^>]+>", " ", m.group(1))) for m in re.finditer(
                r'<a\s[^>]*href="https?://(?:dx\.)?doi\.org/' + d + r'"[^>]*>(.*?)</a>', prose, re.S)]
            for m, label in links:
                label = norm(label)
                if label and label not in (url, doi):  # a bare-DOI label is reported above
                    report(rel, prose, m.start(), f"link text '{label}' hides the DOI: write <{url}>")
            # https://doi.org/ is the one resolver form, so http:// or a dx. or www.
            # host is reported in an autolink, a link target or an href as well.
            for m in re.finditer(r"https?://(?:dx\.|www\.)?doi\.org/" + d, prose):
                if not m.group(0).startswith("https://doi.org/"):
                    report(rel, prose, m.start(),
                           f"'{m.group(0)}' is not the https://doi.org/ form: write <{url}>")
            # A "doi:" or "DOI:" label before the link, or a paragraph, list item or
            # quoted line that opens with "DOI" before it. The word DOI inside a
            # sentence ("the DOI <https://doi.org/...>") stays.
            for m in re.finditer(r"(?i)\bdoi\s*:\s*[<\[]?https?://(?:dx\.|www\.)?doi\.org/" + d, prose):
                report(rel, prose, m.start(), f"label before the link: write <{url}>")
            for m in re.finditer(r"(?i)(?:\A|\n[ \t]*\n)[ \t]*(?:[>*-][ \t]*)*doi[ \t]+[<\[]https?://"
                                 r"(?:dx\.|www\.)?doi\.org/" + d, prose):
                report(rel, prose, m.end() - len(doi), f"label before the link: write <{url}>")
            # A quoted reference ends with the DOI and no full stop (APA 7).
            for m in re.finditer(r"(?m)^[ \t]*>.*<https://doi\.org/" + d + r">\.[ \t]*$", prose):
                report(rel, prose, m.start(), "a reference ends with the DOI, with no full stop after it")

        path = Path(rel)
        if path.name not in ("NEWS.md", "CHANGELOG.md"):
            check_cran_name(rel, text, prose, plain, report)
        # The package's own BibTeX entry, on an About page or in a shipped .bib, names
        # the registry page in url. Code that fills the DOI in ({doi}) is caught too.
        if path.name in ("about.md", "about.Rmd") or path.suffix == ".bib":
            for m in re.finditer(r"url\s*=\s*\{+https?://(?:dx\.)?doi\.org/", prose):
                report(rel, prose, m.start(), "BibTeX url repeats the DOI: give the CRAN or PyPI page")
        if plain:
            continue
        if pkgdown and (root / path.parent / "DESCRIPTION").exists():
            pkg = package_name(root / path.parent)
            link = sidebar_link(pkg)
            lines = [ln.strip() for ln in text.splitlines()]
            if lines.count(link) != 1:
                report(rel, text, 0, f"the Citation component must give, on a line of its own: {link}")
            scss = root / path.parent / "pkgdown" / "extra.scss"
            css = scss.read_text(encoding="utf-8") if scss.exists() else ""
            for rule in (SIZE_RULE, HIDE_RULE):
                if rule not in css:
                    problems.append(f"{scss.relative_to(root).as_posix()}: missing the rule {rule}")

        if re.search(r"(^|/)(docs|vignettes)/", rel) or path.name == "mkdocs.yml" or pkgdown:
            for m in re.finditer(r"zenodo\.org/badge/DOI/|img\.shields\.io/badge/DOI-", text):
                report(rel, text, m.start(), "DOI badge on a site page: the README badge rows carry it")

        if path.name == "index.md" and path.parent.name == "docs" and \
                (root / path.parent.parent / "mkdocs.yml").exists():
            if f"<https://doi.org/{own_doi}>" not in text:
                report(rel, text, 0, f"the home page must give <https://doi.org/{own_doi}>")

        folder = root / path.parent
        landing = path.name in ("README.md", "README.Rmd") and (
            str(path.parent) == "." or (folder / "DESCRIPTION").exists()
            or (folder / "pyproject.toml").exists())
        if not landing:
            continue
        if (folder / "DESCRIPTION").exists():
            doi = f"10.32614/CRAN.package.{package_name(folder)}"
            want_badge = (f"DOI {doi}",
                          "https://img.shields.io/badge/DOI-" + doi.replace("/", "%2F") + "-blue.svg",
                          f"https://doi.org/{doi}")
            cites = [doi]
        else:
            want_badge = (f"DOI {own_doi}", f"https://zenodo.org/badge/DOI/{own_doi}.svg",
                          f"https://doi.org/{own_doi}")
            # A Python package's README gives its own DOI; a dual-language root gives every one.
            cites = [own_doi] if (folder / "pyproject.toml").exists() else dois
        block = re.search(r"<!-- badges: start -->(.*?)<!-- badges: end -->", text, re.S)
        if not block:
            report(rel, text, 0, "a landing README needs a <!-- badges: start/end --> block")
        else:
            badges = re.findall(r"\[!\[([^\]]*)\]\(([^)\s]+)\)\]\(([^)\s]+)\)", block.group(1))
            with_doi = [b for b in badges if b[2].startswith("https://doi.org/")]
            if len(with_doi) != 1 or badges[-1] is not with_doi[0] \
                    or tuple(norm(x) for x in with_doi[0]) != want_badge:
                report(rel, text, block.start(), "the badge block must end with exactly one DOI "
                       f"badge: [![{want_badge[0]}]({want_badge[1]})]({want_badge[2]})")
        cite = section(text)
        if cite is None:
            report(rel, text, 0, "a landing README needs a '## Citation' section")
        else:
            for doi in cites:
                if f"<https://doi.org/{doi}>" not in cite:
                    report(rel, text, text.find("## Citation"),
                           f"the Citation section must give <https://doi.org/{doi}>")
        if path.name == "README.md" and (folder / "README.Rmd").exists():
            rmd = (folder / "README.Rmd").read_text(encoding="utf-8")
            pair = [re.search(r"<!-- badges: start -->(.*?)<!-- badges: end -->", t, re.S) for t in (rmd, text)]
            if all(pair) and norm(pair[0].group(1)) != norm(pair[1].group(1)):
                report(rel, text, 0, "the badge block differs from README.Rmd's: re-knit README.md")
            if all(section(t) is not None for t in (rmd, text)):
                urls = [sorted(set(re.findall(r"<https://doi\.org/[^>]+>", section(t)))) for t in (rmd, text)]
                if urls[0] != urls[1]:
                    report(rel, text, 0, "the Citation section differs from README.Rmd's: re-knit README.md")
    return problems, scanned, dois


class _Sidebar(HTMLParser):
    """Collects, from a pkgdown home page, the links that the extra.scss rules target."""

    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.stack, self.div, self.hidden, self.sized, self._a = [], [], [], [], None

    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if tag == "wbr":  # a void element; pkgdown writes a stray </wbr> after it
            return
        parent = self.stack[-1] if self.stack else None
        self.stack.append(tag)
        if tag == "div" and a.get("class") in ("dev-status", "citation"):
            self.div.append((a["class"], len(self.stack)))
        if tag == "a" and self.div and a.get("href", "").startswith("https://doi.org/"):
            self._a = {"where": self.div[-1][0], "parent": parent, "href": a["href"], "text": ""}

    def handle_endtag(self, tag):
        if tag == "wbr" or tag not in self.stack:
            return
        while self.stack:
            t = self.stack.pop()
            if self.div and len(self.stack) < self.div[-1][1]:
                self.div.pop()
            if t == "a" and self._a is not None:
                (self.hidden if self._a["where"] == "dev-status" else self.sized).append(self._a)
                self._a = None
            if t == tag:
                break

    def handle_data(self, data):
        if self._a is not None:
            self._a["text"] += data


def check_site(site, package):
    problems = []
    pkg = package_name(package)
    url = f"https://doi.org/10.32614/CRAN.package.{pkg}"
    parser = _Sidebar()
    parser.feed((site / "index.html").read_text(encoding="utf-8"))
    hidden = [a for a in parser.hidden if a["href"] == url]
    sized = [a for a in parser.sized if a["href"] == url]
    if len(hidden) != 1 or hidden[0]["parent"] != "li":
        problems.append(f"{site}/index.html: Dev status should list the README's DOI badge as "
                        f"li > a[href^=\"https://doi.org/\"], which extra.scss hides; found {hidden}")
    if len(sized) != 1 or sized[0]["parent"] != "p" or norm(sized[0]["text"]) != url:
        problems.append(f"{site}/index.html: the Citation component should hold p > a with the text "
                        f"{url}; found {sized}")
    css = "".join(p.read_text(encoding="utf-8") for p in site.glob("deps/bootstrap-*/bootstrap.min.css"))
    squash = re.sub(r"\s+", "", css).replace('"', "'")
    for rule in (HIDE_RULE, SIZE_RULE):
        if re.sub(r"\s+", "", rule).replace('"', "'") not in squash:
            problems.append(f"{site}/deps: the compiled stylesheet lacks {rule}")
    return problems


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("root", nargs="?", default=str(Path(__file__).resolve().parents[1]))
    ap.add_argument("--site", help="a built pkgdown site to check instead, relative to the root")
    ap.add_argument("--package", help="the R package the site was built from (default: the site's parent)")
    args = ap.parse_args()
    root = Path(args.root).resolve()
    if args.site:
        site = (root / args.site).resolve()
        package = (root / args.package).resolve() if args.package else site.parent
        problems = check_site(site, package)
        print("\n".join(problems) if problems else
              f"DOI display: the sidebar of {args.site}/index.html shows the DOI once, as a link.")
        return 1 if problems else 0
    problems, scanned, dois = check_repository(root)
    print("\n".join(problems) if problems else
          f"DOI display: {len(scanned)} files agree for {', '.join(dois)}.")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
