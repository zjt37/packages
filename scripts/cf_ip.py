#!/usr/bin/env python3
import re
import sys
import urllib.request
from pathlib import Path

COUNTRY_MAP = {
    "HK": "香港", "TW": "台湾", "JP": "日本", "KR": "韩国",
    "SG": "新加坡", "US": "美国", "CN": "中国", "UK": "英国",
    "DE": "德国", "FR": "法国", "CA": "加拿大", "AU": "澳大利亚",
    "IN": "印度", "RU": "俄罗斯", "BR": "巴西", "NL": "荷兰",
}

RE_IP = re.compile(r"^(\d{1,3}(?:\.\d{1,3}){3}):(\d+)#(.*)")
RE_COUNTRY = re.compile(
    r"\b(HK|TW|JP|KR|SG|US|CN|UK|DE|FR|CA|AU|IN|RU|BR|NL)\b",
    re.IGNORECASE,
)


def ip_sort_key(ip_port):
    parts = ip_port.split(".")
    return tuple(int(p) for p in parts[0].split(".")) + (int(parts[1]),)


def fetch_url(url):
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=15) as resp:
            return resp.read().decode("utf-8", errors="ignore")
    except Exception as e:
        print(f"[WARN] Failed to fetch {url}: {e}", file=sys.stderr)
        return ""


def main():
    script_dir = Path(__file__).resolve().parent
    repo_root = script_dir.parent
    sources_file = repo_root / "ip_sources.txt"
    output_file = repo_root / "cf_ips.txt"

    if not sources_file.exists():
        print(f"[ERROR] {sources_file} not found", file=sys.stderr)
        sys.exit(1)

    lines = [
        ln.strip()
        for ln in sources_file.read_text(encoding="utf-8").splitlines()
        if ln.strip() and not ln.strip().startswith("#")
    ]

    entries = {}  # key: ip:port -> (country_zh, ip_port)

    for url in lines:
        print(f"[INFO] Fetching {url}")
        content = fetch_url(url)
        for line in content.splitlines():
            line = line.strip()
            m = RE_IP.match(line)
            if not m:
                continue
            ip_port = f"{m.group(1)}:{m.group(2)}"
            comment = m.group(3)
            cm = RE_COUNTRY.search(comment)
            if not cm:
                continue
            country_code = cm.group(1).upper()
            country_zh = COUNTRY_MAP.get(country_code, country_code)
            if ip_port not in entries:
                entries[ip_port] = (country_zh, ip_port)

    countries_order = ["香港", "台湾", "日本", "韩国", "新加坡", "美国", "中国"]
    grouped = {}
    for country_zh, ip_port in entries.values():
        grouped.setdefault(country_zh, []).append(ip_port)

    result_lines = []
    for c in countries_order:
        if c not in grouped:
            continue
        ips = sorted(grouped[c], key=ip_sort_key)
        for ip in ips:
            result_lines.append(f"{ip}#{c}")
        del grouped[c]

    for c in sorted(grouped.keys()):
        ips = sorted(grouped[c], key=ip_sort_key)
        for ip in ips:
            result_lines.append(f"{ip}#{c}")

    output_file.write_text("\n".join(result_lines) + "\n", encoding="utf-8")
    print(f"[INFO] Done. {len(result_lines)} IPs written to {output_file}")


if __name__ == "__main__":
    main()
