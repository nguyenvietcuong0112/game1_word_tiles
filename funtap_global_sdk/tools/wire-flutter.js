#!/usr/bin/env node
// wire-flutter.js — đấu dây plugin FGSDK vào project Flutter (chạy sau khi install bat giải nén).
//
// Làm 3 việc, đều IDEMPOTENT (chạy lại không nhân đôi):
//   1. pubspec.yaml            → thêm dependency `funtap_global_sdk: { path: ./funtap_global_sdk }`
//   2. android/app/build.gradle[.kts] → ép minSdk >= 24 (AAR yêu cầu)
//   3. android/gradle.properties      → android.uniquePackageNames=false
//      (AppsFlyer af-android-sdk + purchase-connector CÙNG khai package="com.appsflyer"
//       — mọi version đều vậy, lỗi đóng gói phía AppsFlyer. AGP 9 siết unique namespace
//       nên chặn build; cờ này nới lại.)
//
// Dùng:  node funtap_global_sdk/tools/wire-flutter.js [--project <root>]

'use strict';
var fs = require('fs');
var path = require('path');

var DEP_NAME = 'funtap_global_sdk';
var DEP_PATH = './funtap_global_sdk';
var MIN_SDK = 24;

function parseArgs(argv) {
    var o = {};
    for (var i = 2; i < argv.length; i++) {
        if (argv[i] === '--project') o.project = argv[++i];
    }
    return o;
}

function backup(file) {
    var b = file + '.fgsdkbak';
    if (!fs.existsSync(b)) fs.copyFileSync(file, b);
}

// ── 1. pubspec.yaml ───────────────────────────────────────────────────────────
function wirePubspec(root, log) {
    var file = path.join(root, 'pubspec.yaml');
    if (!fs.existsSync(file)) { log.push('!! Khong thay pubspec.yaml'); return false; }
    var src = fs.readFileSync(file, 'utf-8');

    if (new RegExp('^\\s{2}' + DEP_NAME + ':', 'm').test(src)) {
        log.push('-- pubspec.yaml da co ' + DEP_NAME + ' (bo qua)');
        return true;
    }
    // Chèn ngay sau dòng `dependencies:` ở cột 0 (tránh dev_dependencies).
    var m = /^dependencies:[ \t]*$/m.exec(src);
    if (!m) { log.push('!! Khong tim thay block "dependencies:" trong pubspec.yaml — them tay'); return false; }

    backup(file);
    var insertAt = m.index + m[0].length;
    var block = '\n  ' + DEP_NAME + ':\n    path: ' + DEP_PATH;
    var out = src.slice(0, insertAt) + block + src.slice(insertAt);
    fs.writeFileSync(file, out, 'utf-8');
    log.push('OK pubspec.yaml += ' + DEP_NAME + ' (path: ' + DEP_PATH + ')');
    return true;
}

// ── 2. minSdk >= 24 ───────────────────────────────────────────────────────────
function wireMinSdk(root, log) {
    var candidates = [
        path.join(root, 'android', 'app', 'build.gradle.kts'),
        path.join(root, 'android', 'app', 'build.gradle')
    ];
    var file = candidates.filter(function (p) { return fs.existsSync(p); })[0];
    if (!file) { log.push('!! Khong thay android/app/build.gradle[.kts] — bo qua minSdk'); return; }

    var src = fs.readFileSync(file, 'utf-8');
    // Bắt cả `minSdk = 21`, `minSdkVersion 21`, `minSdk flutter.minSdkVersion`…
    var re = /(minSdkVersion|minSdk)(\s*=\s*|\s+)([A-Za-z0-9_.]+)/;
    var m = re.exec(src);
    if (!m) { log.push('!! Khong tim thay minSdk trong ' + path.basename(file) + ' — dat tay >= 24'); return; }

    var cur = m[3];
    var curNum = parseInt(cur, 10);
    if (!isNaN(curNum) && curNum >= MIN_SDK) {
        log.push('-- minSdk = ' + cur + ' (>= ' + MIN_SDK + ', giu nguyen)');
        return;
    }
    backup(file);
    var out = src.replace(re, m[1] + m[2] + MIN_SDK);
    fs.writeFileSync(file, out, 'utf-8');
    log.push('OK minSdk ' + cur + ' -> ' + MIN_SDK + ' (' + path.basename(file) + ')');
}

// ── 3. gradle.properties: nới kiểm tra unique namespace ───────────────────────
function wireGradleProps(root, log) {
    var file = path.join(root, 'android', 'gradle.properties');
    var KEY = 'android.uniquePackageNames';
    var LINE = KEY + '=false';

    var src = fs.existsSync(file) ? fs.readFileSync(file, 'utf-8') : '';
    if (new RegExp('^\\s*' + KEY.replace(/\./g, '\\.') + '\\s*=', 'm').test(src)) {
        log.push('-- gradle.properties da co ' + KEY + ' (bo qua)');
        return;
    }
    if (fs.existsSync(file)) backup(file);
    var block = (src && !src.endsWith('\n') ? '\n' : '') +
        '\n# AppsFlyer af-android-sdk va purchase-connector CUNG khai package="com.appsflyer"\n' +
        '# (moi version deu vay). AGP 9 siet unique namespace nen chan build -> noi lai.\n' +
        LINE + '\n';
    ensureDirFor(file);
    fs.writeFileSync(file, src + block, 'utf-8');
    log.push('OK gradle.properties += ' + LINE);
}

function ensureDirFor(file) { fs.mkdirSync(path.dirname(file), { recursive: true }); }

// ── main ──────────────────────────────────────────────────────────────────────
(function () {
    var args = parseArgs(process.argv);
    var root = args.project || process.cwd();
    root = root.replace(/^"+|"+$/g, '').replace(/[\\/]+"?$/, '');

    var log = [];
    var ok = wirePubspec(root, log);
    wireMinSdk(root, log);
    wireGradleProps(root, log);

    log.forEach(function (l) { console.log('   ' + l); });
    if (!ok) {
        console.error('[wire] CHUA XONG — sua tay phan bao !! o tren roi chay lai.');
        process.exit(1);
    }
    console.log('[wire] XONG. Tiep theo: flutter pub get');
    process.exit(0);
})();
