import urllib.request
import urllib.error
import json
import re
import ssl
import gzip

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

H = {
    'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) Chrome/120.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,*/*;q=0.8',
    'Accept-Language': 'fr-FR,fr;q=0.9',
}

CANDIDATES = [
    "https://www.ac-mayotte.fr/le-systeme-educatif-a-mayotte",
    "https://www.ac-mayotte.fr/les-langues-regionales",
    "https://www.ac-mayotte.fr/education-prioritaire-rep-rep-mayotte",
    "https://www.ina.fr/ina-eclaire-actu/video/caf97009519/l-education-a-mayotte",
    "https://www.ina.fr/ina-eclaire-actu/video/rfo08007030/l-education-a-mayotte",
    "https://www.ina.fr/ina-eclaire-actu/video/i12293012/mayotte-ile-aux-parfums-3-partie",
    "https://www.ina.fr/ina-eclaire-actu/video/cpf05006021/l-ecole-a-mayotte",
    "https://www.radiofrance.fr/franceculture/podcasts/cultures-monde/mayotte-la-crise-des-migrants-5695802",
    "https://www.radiofrance.fr/franceculture/podcasts/le-cours-de-l-histoire/l-ile-de-mayotte-histoire-et-enjeux-4734093",
    "https://www.lumni.fr/article/le-systeme-scolaire-en-mayotte",
    "https://www.lumni.fr/article/mayotte-un-territoire-au-coeur-de-l-ocean-indien",
    "https://www.arte.tv/fr/videos/RC-023182/mayotte/",
    "https://www.arte.tv/fr/videos/110666-000-A/mayotte-terra-incognita/",
    "https://www.culture.gouv.fr/Regions/Dac-Mayotte/Education-artistique-et-culturelle",
    "https://www.ac-mayotte.fr/ecole-inclusive",
]


def fetch(url):
    req = urllib.request.Request(url, headers=H)
    try:
        with urllib.request.urlopen(req, timeout=20, context=ctx) as r:
            ct = r.headers.get('Content-Type', '')
            data = r.read(600000)
            return r.status, ct, data
    except urllib.error.HTTPError as e:
        return e.code, '', b''
    except Exception as ex:
        return 0, str(ex)[:80], b''


def meta(raw):
    try:
        if raw[:2] == b'\x1f\x8b':
            raw = gzip.decompress(raw)
    except Exception:
        pass
    h = raw.decode('utf-8', errors='replace')
    t = re.search(r'<title[^>]*>([^<]+)</title>', h, re.I)
    oi = (re.search(r'property=["\']og:image["\'][^>]+content=["\']([^"\']+)["\']', h, re.I) or
          re.search(r'content=["\']([^"\']+)["\'][^>]+property=["\']og:image["\']', h, re.I))
    ot = (re.search(r'property=["\']og:title["\'][^>]+content=["\']([^"\']+)["\']', h, re.I) or
          re.search(r'content=["\']([^"\']+)["\'][^>]+property=["\']og:title["\']', h, re.I))
    title = (ot.group(1) if ot else (t.group(1) if t else '')).strip()
    img = oi.group(1).strip() if oi else ''
    return title, img


for url in CANDIDATES:
    s, ct, body = fetch(url)
    title, img = '', ''
    if s == 200:
        title, img = meta(body)

    ts, tct, tb = 0, '', b''
    if img:
        ts, tct, tb = fetch(img)

    r = {
        'url': url,
        'http': s,
        'title': title[:120],
        'img': img[:200],
        'ts': ts,
        'tct': tct[:60],
        'tkb': round(len(tb) / 1024, 1)
    }
    print('RESULT:' + json.dumps(r, ensure_ascii=False))
