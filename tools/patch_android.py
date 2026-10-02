#!/usr/bin/env python3
"""يعدّل مشروع الأندرويد اللي طلّعه `flutter create` عشان يطابق تطبيق وصلها."""
import os, re, shutil, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
APP = os.path.join(ROOT, 'android', 'app')
if not os.path.isdir(APP):
    sys.exit('android/app مش موجود — شغّل: flutter create --org com.wasalah --platforms=android .')

# 1) applicationId + minSdk (Firebase محتاج 23 على الأقل)
for name in ('build.gradle.kts', 'build.gradle'):
    p = os.path.join(APP, name)
    if not os.path.exists(p):
        continue
    s = open(p, encoding='utf-8').read()
    s = re.sub(r'applicationId\s*=?\s*"[^"]+"', lambda m: m.group(0).split('"')[0] + '"com.wasalah.app"', s)
    s = re.sub(r'minSdk(Version)?\s*=?\s*flutter\.minSdkVersion',
               lambda m: m.group(0).replace('flutter.minSdkVersion', '23'), s)
    open(p, 'w', encoding='utf-8').write(s)
    print('patched', name)

# 2) AndroidManifest
mp = os.path.join(APP, 'src', 'main', 'AndroidManifest.xml')
m = open(mp, encoding='utf-8').read()
perms = [
    'android.permission.INTERNET',
    'android.permission.ACCESS_FINE_LOCATION',
    'android.permission.ACCESS_COARSE_LOCATION',
    'android.permission.CAMERA',
    'android.permission.ACCESS_NETWORK_STATE',
    'android.permission.POST_NOTIFICATIONS',
]
block = ''.join(f'    <uses-permission android:name="{p}" />\n'
                for p in perms if p not in m)
if block:
    m = m.replace('<application', block + '    <application', 1)
m = re.sub(r'android:label="[^"]*"', 'android:label="وصلها"', m, count=1)
if 'default_notification_icon' not in m:
    meta = ('        <meta-data android:name="com.google.firebase.messaging.default_notification_icon"\n'
            '            android:resource="@mipmap/ic_launcher" />\n'
            '        <meta-data android:name="com.google.firebase.messaging.default_notification_color"\n'
            '            android:resource="@color/colorPrimary" />\n')
    m = m.replace('</application>', meta + '    </application>', 1)
if '<queries>' not in m:
    q = ('    <queries>\n'
         '        <intent><action android:name="android.intent.action.VIEW" /><data android:scheme="https" /></intent>\n'
         '    </queries>\n')
    m = m.replace('</manifest>', q + '</manifest>', 1)
open(mp, 'w', encoding='utf-8').write(m)
print('patched AndroidManifest.xml')

# 3) الأيقونات + السبلاش + الألوان
src = os.path.join(ROOT, 'android_overrides', 'res')
dst = os.path.join(APP, 'src', 'main', 'res')
for dp, _, files in os.walk(src):
    for f in files:
        rel = os.path.relpath(os.path.join(dp, f), src)
        out = os.path.join(dst, rel)
        os.makedirs(os.path.dirname(out), exist_ok=True)
        shutil.copy2(os.path.join(dp, f), out)
# نفس الـ launch_background في drawable-v21 لو موجود
v21 = os.path.join(dst, 'drawable-v21')
if os.path.isdir(v21):
    shutil.copy2(os.path.join(src, 'drawable', 'launch_background.xml'),
                 os.path.join(v21, 'launch_background.xml'))
print('copied icons / splash / colors')
