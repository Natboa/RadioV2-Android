"""Rendered theme, large-text and reduced-motion checks. Restores OS settings."""
import json, re, subprocess, time
from device_redesign import ADB, adb, sh, nodes, tap_node, tap_label, label, shot, OUT, MODE, PKG, ACT

def search(query):
    tap_node(next(n for n in nodes() if n.get('class','').endswith('EditText')))
    sh('input keycombination 113 29');sh("input text '%s'"%query.replace(' ','%s'))
    time.sleep(.7);sh('input keyevent KEYCODE_BACK');time.sleep(.2)
def capture(name):
    # A screenshot command does not wait for Flutter route animations.
    time.sleep(.6)
    shot(name)

def back():
    sh('input keyevent KEYCODE_BACK')
    time.sleep(.6)
def bounds(text):
    n=next(n for n in nodes() if text in label(n))
    a,b,c,d=map(int,re.findall(r'\d+',n['bounds']))
    return (a+c)//2,(b+d)//2
def tap_xy(pos): sh('input tap %d %d'%pos)

saved={('system','font_scale'):sh('settings get system font_scale')}
for key in ('transition_animation_scale','window_animation_scale','animator_duration_scale'):
    saved['global',key]=sh('settings get global '+key)
volume=re.search(r'volume is (\d+)',sh('cmd media_session volume --stream 3 --get')).group(1)
result={}
try:
    sh('input keyevent KEYCODE_WAKEUP');sh('am force-stop '+PKG);sh('am start -n '+ACT);time.sleep(1)
    sh('cmd media_session volume --stream 3 --set 0')
    tap_label('Settings');tap_label('Light');capture('light-settings');back()
    tap_label('Discover\nTab');capture('light-discover')
    search('rock');capture('light-search-grid');tap_label('Clear search')
    tap_label('Alternative Rock');capture('light-group');back();capture('group-return')
    tap_label('Browse\nTab');search('lofi');tap_label('#lofi | by reyfm.de');time.sleep(2)
    capture('light-mini');tap_label('Open player,');capture('light-player');tap_label('Collapse player')
    tap_label('Settings');tap_label('Dark');capture('dark-settings');back()
    capture('dark-browse');tap_label('Open player,');capture('dark-player');tap_label('Collapse player')
    tap_label('Discover\nTab');capture('dark-discover')
    sh('settings put system font_scale 1.3');time.sleep(.4);capture('large-discover')
    search('rock');capture('large-grid');tap_label('Clear search')
    tap_label('Alternative Rock');capture('large-group');back()
    tap_label('Open player,');capture('large-player');tap_label('Collapse player')
    tap_label('Settings');capture('large-settings');back()
    sh('settings put system font_scale '+saved['system','font_scale']);time.sleep(.4)
    # Establish full-player control bounds, then record interrupted route and
    # play/pause feedback without UI-dump delays inside the interaction.
    mini=bounds('Open player,');tap_xy(mini);time.sleep(.5)
    control=bounds('Pause');tap_label('Collapse player')
    for reduced in (False,True):
        for key in ('transition_animation_scale','window_animation_scale','animator_duration_scale'):
            normal=saved['global',key]
            sh('settings put global %s %s'%(key,'0' if reduced else ('1.0' if normal=='null' else normal)))
        time.sleep(.2)
        remote='/data/local/tmp/rv2_motion.mp4'
        rec=subprocess.Popen([ADB,'shell','screenrecord','--size','540x1170','--time-limit','6',remote],stdout=subprocess.DEVNULL)
        time.sleep(.7);tap_xy(mini);time.sleep(.08);sh('input keyevent KEYCODE_BACK')
        time.sleep(.4);tap_xy(mini);time.sleep(.5);tap_xy(control);time.sleep(.15);tap_xy(control)
        time.sleep(.7);sh('input keyevent KEYCODE_BACK');rec.wait(timeout=15)
        adb('pull',remote,str(OUT/('after-motion-reduced.mp4' if reduced else 'after-motion-normal.mp4')))
        result['reduced' if reduced else 'normal']='Interrupted expansion, reopened, rapid playback toggle and Back completed'
    capture('reduced-motion')
    tap_label('Settings');tap_label('Follow system');sh('input keyevent KEYCODE_BACK')
    result['settingsRestored']=True
    (OUT/'after-variants.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
    print(json.dumps(result,indent=2),flush=True)
finally:
    for (namespace,key),value in saved.items():
        sh('settings delete %s %s'%(namespace,key) if value=='null' else 'settings put %s %s %s'%(namespace,key,value))
    sh('cmd media_session volume --stream 3 --set '+volume)
    sh('am force-stop '+PKG)
    sh('rm -f /data/local/tmp/rv2_motion.mp4')
