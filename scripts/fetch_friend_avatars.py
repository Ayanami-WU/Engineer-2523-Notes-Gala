#!/usr/bin/env python3
from __future__ import annotations

import argparse
import base64
import hashlib
import html
import re
import sys
from dataclasses import dataclass
from html.parser import HTMLParser
from pathlib import Path
from typing import Optional
from urllib.error import URLError
from urllib.parse import urljoin, urlparse
from urllib.request import Request, urlopen


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "docs" / "assets" / "friends"
MAX_BYTES = 2_000_000
TIMEOUT = 10
USER_AGENT = (
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
    "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125 Safari/537.36"
)


@dataclass(frozen=True)
class Friend:
    slug: str
    name: str
    url: str
    github_owner: Optional[str] = None
    skip_fetch: bool = False


FRIENDS = [
    Friend("zju-icicles", "浙江大学课程攻略共享计划", "https://github.com/QSCTech/zju-icicles", "QSCTech"),
    Friend("zju-opt", "ZJU-OPT", "https://github.com/yinze00/ZJU-OPT", "yinze00"),
    Friend("zju-isee", "zju-isee", "https://github.com/zju-isee/zju-isee", "zju-isee"),
    Friend("zjuse-course-note", "CourseNoteOfZJUSE", "https://github.com/Zhang-Each/CourseNoteOfZJUSE", "Zhang-Each"),
    Friend("zju-ee", "ZJU-EE", "https://github.com/alwaysbyx/ZJU-EE", "alwaysbyx"),
    Friend("zju-course", "ZJU_Course", "https://github.com/RyanFcr/ZJU_Course", "RyanFcr"),
    Friend("sloffde", "SLOFFDE", "https://mp.weixin.qq.com/s/O1wa9_9zslam7ovctp4ffw", skip_fetch=True),
    Friend("dezhiti", "一起学习德智体", "https://mp.weixin.qq.com/s/AebEozF9Xemqb1BfIFLayg", skip_fetch=True),
    Friend("lu-nonsense", "路老师的 nonsense collection", "https://mp.weixin.qq.com/s/-hBAeed1AWT35l6Xc5svXQ", skip_fetch=True),
    Friend("randall-math", "Randall 爱数学", "https://mp.weixin.qq.com/s/M6ulC2ljYVDZ2mqXJRST-Q", skip_fetch=True),
    Friend("nongshenglian", "农生链", "https://mp.weixin.qq.com/s/qTc_Reqa8HxLa3boh988Wg", skip_fetch=True),
    Friend("zju-welcome", "zju-welcome", "https://zjuers.com/welcome/", "kaixuanwang2003"),
    Friend("turing-courses", "图灵班学习指南", "https://zju-turing.github.io/TuringCourses/", "ZJU-Turing"),
    Friend("practical-skills", "PracticalSkillsTutorial", "https://slides.tonycrane.cc/PracticalSkillsTutorial/", "TonyCrane"),
    Friend("zju-cs-asio", "ZJU CS - All Sum in One!", "https://isshikihugh.github.io/zju-cs-asio/", "IsshikiHugh"),
    Friend("linear-algebra-left-undone", "Linear-Algebra-Left-Undone", "https://github.com/yhwu-is/Linear-Algebra-Left-Undone", "yhwu-is"),
    Friend("ctf101", "CTF101", "https://courses.zjusec.com/", "team-s2"),
    Friend("hpc101", "HPC101", "https://hpc101.zjusct.io", "ZJUSCT"),
    Friend("computer-system-newbie", "Computer-System-Start-From-a-Newbie", "https://yhwu-is.github.io/Computer-System-Start-From-a-Newbie/", "yhwu-is"),
    Friend("eestudy-place", "EEStUdy-Place", "http://www.eestudy-place.com/", "ZJU-EESUAD"),
    Friend("zju-math", "数学之韵", "https://zju_math.pages.zjusct.io/mathweb/"),
    Friend("zjusaa", "力速双 A - ZJUSAA", "https://fsaa.pages.zjusct.io/fsaa/"),
    Friend("hikari-of-me", "Hikari of ME", "https://hikari-of-me.pages.zjusct.io/hikari-of-me/"),
    Friend("ctrl-a", "控制学习驿站", "https://ctrl-a.pages.zjusct.io/CseHub/"),
    Friend("surfing-tutorial", "SurfingTutorial", "https://github.com/mzdluo123/SurfingTutorial", "mzdluo123"),
    Friend("how-to-ask", "How-To-Ask-Questions", "https://github.com/ryanhanwu/How-To-Ask-Questions-The-Smart-Way/blob/main/README-zh_CN.md", "ryanhanwu"),
    Friend("csdiy", "csdiy.wiki", "https://csdiy.wiki/", "pkuflyingpig"),
    Friend("survive-sjtu", "SurviveSJTUManual", "https://survivesjtu.gitbook.io/survivesjtumanual", "SurviveSJTU"),
    Friend("missing-semester", "missing semester", "https://missing-semester-cn.github.io/", "missing-semester-cn"),
]


class IconParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.icons: list[tuple[int, str]] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, Optional[str]]]) -> None:
        if tag.lower() != "link":
            return

        data = {key.lower(): value for key, value in attrs if value is not None}
        href = data.get("href")
        rel = data.get("rel", "").lower()
        if not href:
            return
        rel_parts = set(rel.split())
        if "icon" not in rel_parts and "apple-touch-icon" not in rel_parts:
            return

        score = 10
        if "apple-touch-icon" in rel_parts:
            score += 10
        if "svg" in href.lower():
            score += 4
        sizes = data.get("sizes", "")
        if "180" in sizes or "192" in sizes or "512" in sizes:
            score += 3
        self.icons.append((score, href))


def fetch(url: str, accept: str) -> tuple[str, str, bytes]:
    req = Request(
        url,
        headers={
            "Accept": accept,
            "User-Agent": USER_AGENT,
        },
    )
    with urlopen(req, timeout=TIMEOUT) as response:
        data = response.read(MAX_BYTES + 1)
        if len(data) > MAX_BYTES:
            raise ValueError(f"response too large for {url}")
        content_type = response.headers.get_content_type()
        return response.geturl(), content_type, data


def detect_mime(data: bytes, content_type: str) -> str:
    if content_type.startswith("image/"):
        return content_type
    head = data[:512].lstrip().lower()
    if data.startswith(b"\x89PNG\r\n\x1a\n"):
        return "image/png"
    if data.startswith(b"\xff\xd8\xff"):
        return "image/jpeg"
    if data.startswith((b"GIF87a", b"GIF89a")):
        return "image/gif"
    if data.startswith(b"\x00\x00\x01\x00"):
        return "image/x-icon"
    if head.startswith(b"<svg") or b"<svg" in head:
        return "image/svg+xml"
    raise ValueError(f"not an image response ({content_type})")


def page_icon_url(url: str) -> Optional[str]:
    final_url, _content_type, data = fetch(url, "text/html,application/xhtml+xml,*/*;q=0.8")
    document = data.decode("utf-8", errors="ignore")
    parser = IconParser()
    parser.feed(document)
    if parser.icons:
        _score, href = sorted(parser.icons, reverse=True)[0]
        return urljoin(final_url, href)

    parsed = urlparse(final_url)
    if parsed.scheme and parsed.netloc:
        return f"{parsed.scheme}://{parsed.netloc}/favicon.ico"
    return None


def label_for(name: str) -> str:
    ascii_words = re.findall(r"[A-Za-z0-9]+", name)
    if ascii_words:
        if len(ascii_words) == 1:
            return ascii_words[0][:3].upper()
        return "".join(word[0] for word in ascii_words[:3]).upper()
    return "".join(ch for ch in name if not ch.isspace())[:2] or "友链"


def colors_for(slug: str) -> tuple[str, str]:
    digest = hashlib.sha256(slug.encode("utf-8")).digest()
    hue = digest[0] * 360 // 255
    return f"hsl({hue} 70% 42%)", f"hsl({(hue + 36) % 360} 72% 54%)"


def fallback_svg(friend: Friend) -> str:
    color_a, color_b = colors_for(friend.slug)
    label = html.escape(label_for(friend.name))
    title = html.escape(friend.name)
    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128" role="img" aria-label="{title}">
  <title>{title}</title>
  <defs>
    <linearGradient id="g" x1="18" y1="12" x2="110" y2="116" gradientUnits="userSpaceOnUse">
      <stop stop-color="{color_a}"/>
      <stop offset="1" stop-color="{color_b}"/>
    </linearGradient>
  </defs>
  <rect width="128" height="128" rx="28" fill="url(#g)"/>
  <circle cx="104" cy="22" r="30" fill="#fff" opacity=".14"/>
  <circle cx="24" cy="114" r="34" fill="#000" opacity=".12"/>
  <text x="64" y="73" text-anchor="middle" dominant-baseline="middle"
        font-family="Inter, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif"
        font-size="34" font-weight="700" fill="#fff">{label}</text>
</svg>
"""


def image_wrapper_svg(friend: Friend, image_data: bytes, mime: str) -> str:
    encoded = base64.b64encode(image_data).decode("ascii")
    title = html.escape(friend.name)
    color_a, _color_b = colors_for(friend.slug)
    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128" role="img" aria-label="{title}">
  <title>{title}</title>
  <defs>
    <clipPath id="avatar-clip">
      <rect width="128" height="128" rx="28"/>
    </clipPath>
  </defs>
  <rect width="128" height="128" rx="28" fill="{color_a}" opacity=".12"/>
  <image href="data:{mime};base64,{encoded}" width="128" height="128"
         preserveAspectRatio="xMidYMid slice" clip-path="url(#avatar-clip)"/>
</svg>
"""


def fetch_avatar(friend: Friend) -> tuple[Optional[str], Optional[str], Optional[bytes]]:
    if friend.skip_fetch or "mp.weixin.qq.com" in friend.url:
        raise ValueError("skipped dynamic WeChat page")

    if friend.github_owner:
        url = f"https://github.com/{friend.github_owner}.png?size=128"
        _final_url, content_type, data = fetch(url, "image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8")
        return url, detect_mime(data, content_type), data

    icon_url = page_icon_url(friend.url)
    if not icon_url:
        raise ValueError("no icon URL found")
    _final_url, content_type, data = fetch(icon_url, "image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8")
    return icon_url, detect_mime(data, content_type), data


def write_avatar(friend: Friend, refresh: bool) -> str:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    dest = OUT_DIR / f"{friend.slug}.svg"
    if dest.exists() and not refresh:
        return f"skip     {dest.relative_to(ROOT)}"

    try:
        source_url, mime, data = fetch_avatar(friend)
        assert mime is not None and data is not None
        dest.write_text(image_wrapper_svg(friend, data, mime), encoding="utf-8")
        return f"fetched  {dest.relative_to(ROOT)} <- {source_url}"
    except (OSError, URLError, ValueError) as exc:
        dest.write_text(fallback_svg(friend), encoding="utf-8")
        return f"fallback {dest.relative_to(ROOT)} ({exc})"


def main() -> int:
    parser = argparse.ArgumentParser(description="Fetch and cache friend-link avatars as local SVG files.")
    parser.add_argument("--refresh", action="store_true", help="overwrite existing cached avatars")
    args = parser.parse_args()

    results = [write_avatar(friend, args.refresh) for friend in FRIENDS]
    for line in results:
        print(line)
    fetched = sum(line.startswith("fetched") for line in results)
    fallback = sum(line.startswith("fallback") for line in results)
    skipped = sum(line.startswith("skip") for line in results)
    print(f"\nsummary: fetched={fetched}, fallback={fallback}, skipped={skipped}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
