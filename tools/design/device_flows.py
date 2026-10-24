"""Exercise the test install and retain real-device render/semantic evidence."""
import json, re, time
from device_redesign import adb, sh, nodes, tap_node, tap_label, label, shot as raw_shot, OUT, MODE, PKG, ACT

def shot(name):
    time.sleep(.6)
    raw_shot(name)

def back():
    sh('input keyevent KEYCODE_BACK')
    time.sleep(.6)

def search(query):
    box=next(n for n in nodes() if n.get('class','').endswith('EditText'))
    tap_node(box)
    sh('input keycombination 113 29')
    sh("input text '%s'" % query.replace(' ','%s'))
    time.sleep(.7)
    sh('input keyevent KEYCODE_BACK')
    time.sleep(.3)

def session():
    out=sh('dumpsys media_session')
    pos=out.find('package='+PKG)
    if pos<0: return '?',''
    block=out[pos:]
    m=re.search(r'state=PlaybackState \{state=(\w+)',block)
    title=re.search(r'description=([^\r\n]+)',block)
    return m.group(1) if m else '?',title.group(1) if title else ''

def wait_playing(seconds=20):
    start=time.monotonic()
    while time.monotonic()-start<seconds:
        state,title=session()
        if state in ('3','PLAYING'): return round(time.monotonic()-start,2),title
        time.sleep(.2)
    raise AssertionError(('No playback',session()))

volume=re.search(r'volume is (\d+)',sh('cmd media_session volume --stream 3 --get')).group(1)
result={}
try:
    sh('input keyevent KEYCODE_WAKEUP');sh('am force-stop '+PKG);sh('am start -n '+ACT);time.sleep(1)
    sh('cmd media_session volume --stream 3 --set 0')
    tap_label('Discover\nTab');time.sleep(.5);shot('flow-discover')
    tap_label('Alternative Rock');time.sleep(.5);shot('group')
    for _ in range(4): sh('input swipe 540 1700 540 700 200')
    shot('group-pagination');back()
    if MODE=='before':
        sh('input tap 1005 180')
    else: tap_label('Settings')
    time.sleep(.4);shot('settings')
    back()
    tap_label('Browse\nTab');search('lofi');shot('search')
    tap_label('#lofi | by reyfm.de')
    result['playback']=wait_playing();shot('mini-player')
    if MODE=='before': sh('input tap 300 1835')
    else: tap_label('Open player,')
    time.sleep(.5);shot('player')
    sh('input keyevent KEYCODE_HOME');sh('cmd media_session dispatch pause');time.sleep(.3)
    result['backgroundPause']=session()
    sh('cmd media_session dispatch play');result['backgroundResume']=wait_playing()
    sh('cmd statusbar expand-notifications');time.sleep(.4);shot('media-notification')
    sh('cmd statusbar collapse');sh('am start -n '+ACT);time.sleep(.3)
    if MODE!='before':
        tap_label('Save to favourites');result['savedFavourite']=True
        back();tap_label('Favourites\nTab');shot('favourites-saved')
        tap_label('Remove from favourites');shot('favourites-removed')
        tap_label('Browse\nTab');search('Burina.NET');tap_label('Burina.NET Demo Radio')
        # Timeout is a routine, neutral recoverable state in the redesigned UI.
        time.sleep(12.6);shot('offline-message');tap_label('Open player,');shot('offline-player')
        result['offlineSession']=session()
        tap_label('Retry station');time.sleep(.3)
        result['retrySession']=session()
        back();tap_label('Browse\nTab');search('lofi');tap_label('#lofi | by reyfm.de')
        result['recoveryAfterRetry']=wait_playing()
    result['finalSession']=session()
    (OUT/f'{MODE}-flows.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
    print(json.dumps(result,indent=2),flush=True)
finally:
    sh('am force-stop '+PKG)
    sh('cmd media_session volume --stream 3 --set '+volume)
