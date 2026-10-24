"""Compare paginated group scrolling before/after the artwork follow-up."""
import json,time
from device_redesign import adb,sh,tap_label,records,frame_summary,mem,shot,OUT,MODE,PKG,ACT

try:
    sh('am force-stop '+PKG);sh('am start -n '+ACT);time.sleep(1)
    tap_label('Discover\nTab');tap_label('Alternative Rock');time.sleep(1)
    shot('group-top')
    adb('logcat','-c')
    for _ in range(12):
        sh('input swipe 540 1690 540 610 180');time.sleep(.1)
    time.sleep(1)
    memory=mem()
    shot('group-scrolled')
    # Animated remote logos can keep the opt-in probe's idle flush pending.
    # Hide the app to flush the bounded flow, identically for both candidates.
    sh('input keyevent KEYCODE_HOME');time.sleep(1)
    result={'groupFlowFrames':frame_summary(records()),'pssKb':memory,
            'scope':'Whole group flow through 12 flings; includes any previously unflushed frames. Not input latency.'}
    (OUT/(MODE+'-group-perf.json')).write_text(json.dumps(result,indent=2))
    print(json.dumps(result,indent=2),flush=True)
finally:
    sh('am force-stop '+PKG)
