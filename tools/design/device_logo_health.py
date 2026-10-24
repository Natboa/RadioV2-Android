"""Measure and confirm cached artwork ordering without changing visible rows."""
import json,re,subprocess,sys,time
from device_redesign import adb,sh,nodes,tap_node,tap_label,label,shot,OUT,PKG,ACT

def search(text):
    tap_node(next(n for n in nodes() if n.get('class','').endswith('EditText')))
    sh('input keycombination 113 29');sh("input text '%s'"%text.replace(' ','%s'))
    time.sleep(.7);sh('input keyevent KEYCODE_BACK');time.sleep(1)

def back():
    sh('input keyevent KEYCODE_BACK');time.sleep(.7)

def capture(name):
    time.sleep(.7);shot('logo-health-'+name)

def stations_with_bounds(names):
    return [(label(n),n['bounds']) for n in nodes() if label(n) in names]

result={}
try:
    if '--skip-metrics' not in sys.argv:
        for script in ('device_redesign.py','device_group_perf.py'):
            subprocess.run([sys.executable,'tools/design/'+script,'after-logo-health'],check=True)
    sh('am start -n '+ACT);time.sleep(1)
    # Ordinary requests learn failures; no preflight, list scanning or seeded
    # failure metadata is injected into the app by this check.
    tap_label('Browse\nTab');search('BigFM Rock');time.sleep(4)
    capture('failure-learned')
    tap_label('Discover\nTab');tap_label('Alternative Rock');time.sleep(1)
    search('Best');capture('best-order')
    names={'Best Radio 92.6','Best Of Rock.FM Alternative Rock','Best of Rock FM'}
    first=stations_with_bounds(names)
    time.sleep(6)
    second=stations_with_bounds(names)
    expected={'Best Of Rock.FM Alternative Rock','Best of Rock FM'}
    if not expected.issubset({name for name,_ in first}):
        raise AssertionError(('Expected the two logo-bearing Best stations',first))
    if any(name=='Best Radio 92.6' for name,_ in first):
        raise AssertionError(('Unsupported artwork still interleaved at the top',first))
    if first!=second: raise AssertionError(('Rows moved after initial display',first,second))
    ordered=[name for name,_ in sorted(first,key=lambda row:int(re.findall(r'\d+',row[1])[1]))]
    result['bestOrder']=ordered
    result['visibleRowsStableAfter6s']=True
    capture('best-order-settled')
    for _ in range(8):
        if any(label(n)=='Best Radio 92.6' for n in nodes()): break
        sh('input swipe 540 1690 540 1100 250');time.sleep(.3)
    if not any(label(n)=='Best Radio 92.6' for n in nodes()):
        raise AssertionError('The station with unsupported artwork was lost.')
    result['bestRadioRetainedBelowArtwork']=True
    capture('unsupported-retained-below')
    tap_label('Clear search');search('BigFM');capture('bigfm-retained')
    rows=[n for n in nodes() if label(n)=='BigFM Rock']
    if len(rows)!=2: raise AssertionError(('Lost duplicate-name stations',len(rows)))
    result['bothBigFmStationsRetained']=True
    back();tap_label('Alternative Rock');time.sleep(1)
    result['reopenedGroup']=True
    capture('reopened')
    result['engineLog']=adb('logcat','-d','-v','brief','-s','flutter:E','AndroidRuntime:E')
finally:
    sh('am force-stop '+PKG)
    sh('settings put global stay_on_while_plugged_in 0')
    sh('rm -f /data/local/tmp/rv2_design.xml /data/local/tmp/rv2_design.png')
    result['restoredStayAwake']=sh('settings get global stay_on_while_plugged_in')
    (OUT/'after-logo-health-check.json').write_text(json.dumps(result,indent=2))
print(json.dumps(result,indent=2),flush=True)
