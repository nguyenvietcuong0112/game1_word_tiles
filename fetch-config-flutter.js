#!/usr/bin/env node
// fetch-config-flutter.js — CLI kéo config bundle từ server Funtap về project Flutter.
//
// PORT từ fetch-config-2x.js (bản Cocos 2.4): Node thuần (chỉ https/http/fs/path — KHÔNG cần
// npm install). Khác chỗ ĐÍCH GHI, vì layout Flutter khác Cocos:
//   mainConfig     → android/app/src/main/assets/fg_main_config.json   (native đọc từ assets APK)
//                  + ios/Runner/fg_main_config.json                     (native đọc từ bundle)
//   google-services→ android/app/google-services.json
//   GoogleService  → ios/Runner/GoogleService-Info.plist
//   keystore       → android/<file> + android/key.properties (convention Flutter)
//   admob app id   → chèn manifestPlaceholder FGSDK_ADMOB_APP_ID vào android/app/build.gradle[.kts]
//
// Endpoint DÙNG CHUNG với Unity / Cocos: GET <baseUrl>/api/sdk/bundle, header X-API-Key.
//
// Dùng:  node fetch-config-flutter.js --key <APIKEY> [--url https://fgtool.funtapglobal.com]
//                                     [--project <root>] [--force]

'use strict';
var https = require('https');
var http = require('http');
var fs = require('fs');
var path = require('path');

var BUNDLE_PATH = '/api/sdk/bundle';
var DEFAULT_URL = 'https://fgtool.funtapglobal.com';
var COOLDOWN_SECONDS = 180; // chặn spam server (fgtool limit 30/10 phút)

function parseArgs(argv) {
    var o = {};
    for (var i = 2; i < argv.length; i++) {
        var a = argv[i];
        if (a === '--key') o.key = argv[++i];
        else if (a === '--url') o.url = argv[++i];
        else if (a === '--project') o.project = argv[++i];
        else if (a === '--force') o.force = true;
    }
    return o;
}

function ensureDir(dir) { fs.mkdirSync(dir, { recursive: true }); }

function writeTextIfChanged(filePath, content) {
    ensureDir(path.dirname(filePath));
    if (fs.existsSync(filePath) && fs.readFileSync(filePath, 'utf-8') === content) return false;
    fs.writeFileSync(filePath, content, 'utf-8');
    return true;
}
function writeBytesIfChanged(filePath, data) {
    ensureDir(path.dirname(filePath));
    if (fs.existsSync(filePath)) {
        var existing = fs.readFileSync(filePath);
        if (existing.length === data.length && existing.equals(data)) return false;
    }
    fs.writeFileSync(filePath, data);
    return true;
}
function extractMessage(json) {
    if (!json) return '';
    var key = '"message":"';
    var start = json.indexOf(key);
    if (start < 0) return json.slice(0, 200);
    var s = start + key.length;
    var end = json.indexOf('"', s);
    return end < 0 ? json.slice(s) : json.slice(s, end);
}

// ── HTTP GET bundle ───────────────────────────────────────────────────────────
function fetchBundle(apiKey, baseUrl) {
    return new Promise(function (resolve) {
        var u;
        try { u = new URL(baseUrl.replace(/\/+$/, '') + BUNDLE_PATH); }
        catch (e) { resolve({ ok: false, status: 0, error: 'URL khong hop le: ' + baseUrl }); return; }
        var isHttps = u.protocol === 'https:';
        var lib = isHttps ? https : http;
        var req = lib.request({
            protocol: u.protocol, hostname: u.hostname, port: u.port || (isHttps ? 443 : 80),
            path: u.pathname + u.search, method: 'GET',
            headers: { 'X-API-Key': apiKey, Accept: 'application/json' }
        }, function (res) {
            var chunks = [];
            res.on('data', function (c) { chunks.push(c); });
            res.on('end', function () {
                var body = Buffer.concat(chunks).toString('utf-8');
                var status = res.statusCode || 0;
                if (status < 200 || status >= 300) {
                    var msg = extractMessage(body);
                    var error;
                    if (status === 401) error = '401 Unauthorized — ' + msg + '. Lay key moi o tab SDK API.';
                    else if (status === 429) error = '429 Rate limit — Doi vai phut roi thu lai.';
                    else error = 'HTTP ' + status + ': ' + (msg || body.slice(0, 200));
                    resolve({ ok: false, status: status, error: error });
                    return;
                }
                try { resolve({ ok: true, status: status, bundle: JSON.parse(body) }); }
                catch (e) { resolve({ ok: false, status: status, error: 'Parse JSON loi: ' + e.message }); }
            });
        });
        req.on('error', function (e) { resolve({ ok: false, status: 0, error: 'Network error: ' + e.message }); });
        req.setTimeout(20000, function () { req.destroy(); resolve({ ok: false, status: 0, error: 'Timeout (20s).' }); });
        req.end();
    });
}

// ── Ghi AdMob app id ─────────────────────────────────────────────────────────
// ⚠️ PHẢI ghi vào android/gradle.properties, KHÔNG phải app/build.gradle:
// meta-data ${FGSDK_ADMOB_APP_ID} nằm trong manifest của PLUGIN, mà AGP thay
// placeholder bằng giá trị của module sở hữu manifest -> đặt ở app là vô tác dụng,
// APK sẽ mang app id TEST và quảng cáo không ra tiền. Plugin đọc property này.
function writeAdmobAppId(projectRoot, appId, log) {
    var KEY = 'FGSDK_ADMOB_APP_ID';
    if (!appId) {
        log.push('!! config KHONG co android.main_ads_config.google_admob_app_id'
            + ' -> giu app id TEST cua Google. Quang cao se KHONG ra tien o ban release.');
        return;
    }
    var file = path.join(projectRoot, 'android', 'gradle.properties');
    var src = fs.existsSync(file) ? fs.readFileSync(file, 'utf-8') : '';
    var re = new RegExp('^[ \t]*' + KEY + '[ \t]*=.*$', 'm');
    var line = KEY + '=' + appId;
    if (re.test(src)) {
        var next = src.replace(re, line);
        if (next === src) { log.push('-- AdMob app id (unchanged)'); return; }
        fs.writeFileSync(file, next, 'utf-8');
        log.push('OK AdMob app id (cap nhat) -> android/gradle.properties');
        return;
    }
    var pad = (src && src.charAt(src.length - 1) !== '\n') ? '\n' : '';
    fs.writeFileSync(file, src + pad + '\n# AdMob app id that (plugin FGSDK doc property nay)\n'
        + line + '\n', 'utf-8');
    log.push('OK AdMob app id -> android/gradle.properties');
}

// ── Chặn secret lọt vào git ─────────────────────────────
// Fetch kéo về keystore + key.properties + API key đã lưu. Dev lỡ commit là lộ khoá ký app.
// Tự thêm vào .gitignore (idempotent) cho chắc.
function protectGitignore(projectRoot, log) {
    var file = path.join(projectRoot, '.gitignore');
    var MARK = '# --- FGSDK: KHONG commit secret ---';
    var src = fs.existsSync(file) ? fs.readFileSync(file, 'utf-8') : '';
    if (src.indexOf(MARK) !== -1) { log.push('-- .gitignore da chan secret'); return; }
    var entries = [
        MARK,
        'android/key.properties',
        '*.keystore',
        '*.jks',
        '.fgsdk/',
        'android/app/google-services.json',
        'ios/Runner/GoogleService-Info.plist'
    ];
    var pad = (src && src.charAt(src.length - 1) !== '\n') ? '\n' : '';
    fs.writeFileSync(file, src + pad + '\n' + entries.join('\n') + '\n', 'utf-8');
    log.push('OK .gitignore += chan keystore/key.properties/API key/google-services');
}

// ── Ghi bundle ra file ────────────────────────────────────────────────────────
function writeBundle(bundle, projectRoot) {
    var log = [];
    var androidAssets = path.join(projectRoot, 'android', 'app', 'src', 'main', 'assets');
    var androidApp = path.join(projectRoot, 'android', 'app');
    var androidDir = path.join(projectRoot, 'android');
    var iosRunner = path.join(projectRoot, 'ios', 'Runner');
    var files = bundle.files || {};

    if (bundle.gameCode || bundle.appName) {
        log.push('Game: ' + (bundle.gameCode || '?') + ' — ' + (bundle.appName || ''));
    }

    if (files.mainConfig && files.mainConfig.json != null) {
        var cfg = files.mainConfig.json;
        var json = JSON.stringify(cfg, null, 2);
        var a = writeTextIfChanged(path.join(androidAssets, 'fg_main_config.json'), json);
        log.push((a ? 'OK ' : '-- ') + 'fg_main_config.json -> android/app/src/main/assets/');
        var i = writeTextIfChanged(path.join(iosRunner, 'fg_main_config.json'), json);
        log.push((i ? 'OK ' : '-- ') + 'fg_main_config.json -> ios/Runner/');

        var appId = '';
        try { appId = cfg.android.main_ads_config.google_admob_app_id || ''; } catch (e) { /* ignore */ }
        writeAdmobAppId(projectRoot, appId, log);
    }

    var android = files.googleServices && files.googleServices.android;
    if (android && android.contentBase64) {
        var w2 = writeBytesIfChanged(path.join(androidApp, android.filename),
            Buffer.from(android.contentBase64, 'base64'));
        log.push((w2 ? 'OK ' : '-- ') + android.filename + ' -> android/app/');
    }
    var ios = files.googleServices && files.googleServices.ios;
    if (ios && ios.contentBase64) {
        var w3 = writeBytesIfChanged(path.join(iosRunner, ios.filename),
            Buffer.from(ios.contentBase64, 'base64'));
        log.push((w3 ? 'OK ' : '-- ') + ios.filename + ' -> ios/Runner/');
        log.push('   (nho add file nay vao Xcode project Runner neu chua co)');
    }

    var ks = files.keystore;
    if (ks && ks.contentBase64 && ks.filename) {
        var ksPath = path.join(androidDir, ks.filename);
        var w4 = writeBytesIfChanged(ksPath, Buffer.from(ks.contentBase64, 'base64'));
        log.push((w4 ? 'OK ' : '-- ') + ks.filename + ' -> android/');
        if (ks.info) {
            // key.properties: convention chuẩn của Flutter cho signing release.
            var props = [
                'storePassword=' + (ks.info.storePassword || ''),
                'keyPassword=' + (ks.info.keyPassword || ''),
                'keyAlias=' + (ks.info.alias || ''),
                'storeFile=' + ks.filename,
                ''
            ].join('\n');
            var pw = writeTextIfChanged(path.join(androidDir, 'key.properties'), props);
            log.push((pw ? 'OK ' : '-- ') + 'key.properties -> android/ (alias: ' + ks.info.alias + ')');
            log.push('   !! key.properties + keystore chua secret — DUNG commit vao git');
        }
    }

    protectGitignore(projectRoot, log);

    if (bundle.missing && bundle.missing.length) {
        log.push('!! Chua co tren server: ' + bundle.missing.join(', '));
    }
    return log;
}

// ── Lưu / đọc API key ─────────────────────────────────────────────────────────
function keyStore(projectRoot) { return path.join(projectRoot, '.fgsdk', 'fetch-flutter.json'); }
function loadState(projectRoot) {
    try { return JSON.parse(fs.readFileSync(keyStore(projectRoot), 'utf-8')) || {}; } catch (e) { return {}; }
}
function loadSavedKey(projectRoot) { return loadState(projectRoot).apiKey || ''; }
function saveKey(projectRoot, apiKey, url, lastFetch) {
    try {
        var p = keyStore(projectRoot); ensureDir(path.dirname(p));
        var st = loadState(projectRoot);
        st.apiKey = apiKey; st.url = url;
        if (lastFetch != null) st.lastFetch = lastFetch;
        fs.writeFileSync(p, JSON.stringify(st, null, 2), 'utf-8');
    } catch (e) { /* ignore */ }
}
function remainingCooldown(projectRoot) {
    var last = loadState(projectRoot).lastFetch;
    if (!last) return 0;
    var elapsed = Math.floor((Date.now() - last) / 1000);
    return Math.max(0, COOLDOWN_SECONDS - elapsed);
}

// ── main ──────────────────────────────────────────────────────────────────────
(function () {
    var args = parseArgs(process.argv);
    var projectRoot = args.project || process.cwd();
    // bat/cmd có thể truyền path dính dấu " thừa. Bỏ đi.
    projectRoot = projectRoot.replace(/^"+|"+$/g, '').replace(/[\\/]+"?$/, '');
    var baseUrl = args.url || DEFAULT_URL;
    var apiKey = args.key || loadSavedKey(projectRoot);

    if (!fs.existsSync(path.join(projectRoot, 'pubspec.yaml'))) {
        console.error('[fetch] LOI: khong thay pubspec.yaml — chay o ROOT project Flutter.');
        process.exit(2);
    }
    if (!apiKey) {
        console.error('[fetch] LOI: thieu API Key. Chay: node fetch-config-flutter.js --key <APIKEY>');
        process.exit(2);
    }
    var cd = remainingCooldown(projectRoot);
    if (cd > 0 && !args.force) {
        console.error('[fetch] Cooldown: doi ' + cd + 's nua roi thu lai (chan spam server, limit 30/10phut).');
        console.error('[fetch] Muon bo qua ngay: chay lai voi --force');
        process.exit(3);
    }
    console.log('[fetch] Server : ' + baseUrl + BUNDLE_PATH);
    console.log('[fetch] Project: ' + projectRoot);
    fetchBundle(apiKey, baseUrl).then(function (r) {
        if (!r.ok) { console.error('[fetch] THAT BAI: ' + r.error); process.exit(1); }
        var log = writeBundle(r.bundle, projectRoot);
        log.forEach(function (l) { console.log('   ' + l); });
        saveKey(projectRoot, apiKey, baseUrl, Date.now());
        console.log('[fetch] XONG.');
        process.exit(0);
    });
})();
