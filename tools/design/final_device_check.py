"""Final bounded confirmation; stops on failure and restores phone settings."""
import json, re, subprocess, sys, time
from device_redesign import adb, sh, tap_label, OUT, PKG, ACT

result={}
try:
    policy=sh('dumpsys window policy')
    if re.search(r'\bshowing=true',policy):
        raise RuntimeError('Phone is locked; unlock before the final check.')
    sh('am start -n '+ACT);time.sleep(1)
    tap_label('Settings');tap_label('Dark');sh('input keyevent KEYCODE_BACK')
    scripts=('device_variants.py','device_flows.py') if '--skip-metrics' in sys.argv else ('device_redesign.py','device_variants.py','device_flows.py')
    if '--skip-metrics' in sys.argv:
        result['device_redesign.py']='passed in preceding run; after-metrics.json retained'
    for script in scripts:
        subprocess.run([sys.executable,'tools/design/'+script,'after'],check=True)
        result[script]='passed'
    result['flutterErrors']=adb('logcat','-d','-v','brief','-s','flutter:E','AndroidRuntime:E')
finally:
    # Original value was read as0 before any test; the hold must not persist.
    sh('settings put global stay_on_while_plugged_in 0')
    result['restoredStayAwake']=sh('settings get global stay_on_while_plugged_in')
    result['fontScale']=sh('settings get system font_scale')
    result['animationScales']={k:sh('settings get global '+k) for k in ('window_animation_scale','transition_animation_scale','animator_duration_scale')}
    result['mediaVolume']=sh('cmd media_session volume --stream 3 --get')
    (OUT/'final-device-check.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
print(json.dumps(result,indent=2),flush=True)
