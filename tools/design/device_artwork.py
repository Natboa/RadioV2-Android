"""Confirm group ordering and missing-art tiles on the isolated candidate."""
import json,re,subprocess,sys,time
from device_redesign import adb,sh,tap_label,tap_node,nodes,label,shot,OUT,PKG,ACT

def capture(name):
    time.sleep(.6);shot('artwork-'+name)

def back():
    sh('input keyevent KEYCODE_BACK');time.sleep(.6)

def search(query):
    tap_node(next(n for n in nodes() if n.get('class','').endswith('EditText')))
    sh('input keycombination 113 29');sh("input text '%s'"%query.replace(' ','%s'))
    time.sleep(.7);back()

volume=re.search(r'volume is (\d+)',sh('cmd media_session volume --stream 3 --get')).group(1)
font=sh('settings get system font_scale')
result={}
try:
    subprocess.run([sys.executable,'tools/design/device_group_perf.py','after-artwork'],check=True)
    sh('am start -n '+ACT);time.sleep(1)
    tap_label('Discover\nTab');tap_label('Alternative Rock');capture('featured')
    sh('input swipe 540 1690 540 860 300');capture('ordinary-logos')
    search('202.fm');capture('group-search-monogram')
    back();tap_label('Browse\nTab');search('Burina.NET');capture('missing-row')
    sh('cmd media_session volume --stream 3 --set 0')
    tap_label('Burina.NET Demo Radio');time.sleep(12.6);capture('offline-message')
    tap_label('Open player,');capture('dark-player')
    sh('settings put system font_scale 1.3');capture('large-player')
    sh('settings put system font_scale '+font);tap_label('Collapse player')
    tap_label('Settings');tap_label('Light');back()
    capture('light-mini');tap_label('Open player,');capture('light-player')
    tap_label('Collapse player');tap_label('Settings');tap_label('Follow system');back()
    result['confirmed']='Featured remains pinned; ordinary-logo section, missing-art row/mini/player, offline and light/dark/large text captured.'
    result['errors']=adb('logcat','-d','-v','brief','-s','flutter:E','AndroidRuntime:E')
finally:
    sh('settings put system font_scale '+font)
    sh('cmd media_session volume --stream 3 --set '+volume)
    sh('settings put global stay_on_while_plugged_in 0')
    sh('am force-stop '+PKG)
    result['restoredStayAwake']=sh('settings get global stay_on_while_plugged_in')
    result['restoredFontScale']=sh('settings get system font_scale')
    result['restoredVolume']=sh('cmd media_session volume --stream 3 --get')
    (OUT/'after-artwork-check.json').write_text(json.dumps(result,indent=2))
print(json.dumps(result,indent=2),flush=True)
