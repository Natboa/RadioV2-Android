"""Repeatable physical-device profile and screenshots; no production app writes.
python device_redesign.py before|after (profile test install required).
Frame timing samples come from opt-in Dart FrameTiming instrumentation.
"""
import json, os, re, statistics, subprocess, sys, time, xml.etree.ElementTree as ET
from pathlib import Path

ADB = str(Path(os.environ['LOCALAPPDATA'])/'Android/Sdk/platform-tools/adb.exe')
PKG = 'com.radiov2.radiov2_android.designtest'
ACT = PKG+'/com.radiov2.radiov2_android.MainActivity'
OUT = Path('build/design'); OUT.mkdir(parents=True, exist_ok=True)
MODE = sys.argv[1]

def adb(*args):
    p = subprocess.run([ADB,*args],capture_output=True,timeout=60)
    if p.returncode: raise RuntimeError(p.stderr.decode(errors='replace'))
    return p.stdout.decode('utf-8',errors='replace').strip()
def sh(cmd): return adb('shell',cmd)
def nodes():
    sh('uiautomator dump /data/local/tmp/rv2_design.xml')
    return [n.attrib for n in ET.fromstring(sh('cat /data/local/tmp/rv2_design.xml')).iter('node')]
def label(n): return n.get('text') or n.get('content-desc','')
def tap_node(n):
    a,b,c,d=map(int,re.findall(r'\d+',n['bounds']))
    sh(f'input tap {(a+c)//2} {(b+d)//2}')
def tap_label(text):
    hits=[n for n in nodes() if text in label(n)]
    if not hits: raise AssertionError((text,[label(n) for n in nodes() if label(n)]))
    tap_node(hits[0])
def shot(name):
    sh('screencap -p /data/local/tmp/rv2_design.png')
    adb('pull','/data/local/tmp/rv2_design.png',str(OUT/f'{MODE}-{name}.png'))
    (OUT/f'{MODE}-{name}.json').write_text(json.dumps(nodes(),ensure_ascii=False,indent=2),encoding='utf-8')
def records():
    lines=adb('logcat','-d','-v','brief','-s','flutter:I')
    (OUT/f'{MODE}-flutter.log').write_text(lines,encoding='utf-8')
    rows=[]
    for l in lines.splitlines():
        if 'RV2PERF {' not in l: continue
        raw=l.split('RV2PERF ',1)[1]
        try: rows.append(json.loads(raw))
        except json.JSONDecodeError:
            # Android truncates long log lines. Retain complete frame pairs
            # only; report their partial coverage explicitly.
            rows.append({'frames':[[int(a),int(b)] for a,b in re.findall(r'\[(\d+),(\d+)\]',raw)],'truncated':True})
    return rows
def mem():
    out=sh('dumpsys meminfo '+PKG)
    m=re.search(r'TOTAL PSS:\s*(\d+)',out)
    return int(m.group(1)) if m else None
def cpu():
    pid=sh('pidof '+PKG)
    out=sh(f'cat /proc/{pid}/stat')
    rest=out[out.rfind(')')+2:].split()
    return int(rest[11])+int(rest[12])
def frame_summary(rows):
    frames=[f for r in rows for f in r.get('frames',[])]
    if not frames: return {'count':0}
    p95=lambda xs: sorted(xs)[min(len(xs)-1,int(len(xs)*.95))]/1000
    return {'count':len(frames),'build_p95_ms':p95([f[0] for f in frames]),
            'raster_p95_ms':p95([f[1] for f in frames]),
            'over_16_7ms':sum(max(f)>16667 for f in frames),
            'over_8_3ms':sum(max(f)>8333 for f in frames)}

def main():
    result={'mode':MODE,'package':PKG,'device':sh('getprop ro.product.model'),'startup':[]}
    sh('input keyevent KEYCODE_WAKEUP')
    for i in range(3):
        sh('am force-stop '+PKG); adb('logcat','-c'); time.sleep(.5)
        launch=sh('am start -W -n '+ACT); time.sleep(3)
        rs=records()
        timing=re.search(r'TotalTime: (\d+)',launch)
        if timing is None: raise RuntimeError('No launch timing: '+launch)
        result['startup'].append({'androidLaunchMs':int(timing.group(1)),
                                 'dartFirstFrameMs':next((r['firstFrameMs'] for r in rs if 'firstFrameMs' in r),None)})
    shot('favourites')
    result['idlePssKb']=mem(); a=cpu();time.sleep(10); result['idleCpuTicks10s']=cpu()-a
    adb('logcat','-c')
    t=time.monotonic(); tap_label('Discover'); time.sleep(2)
    result['discoverNavigationAndWaitS']=round(time.monotonic()-t,3)
    shot('discover')
    result['discoverInitial']=records(); result['discoverInitialPssKb']=mem()
    adb('logcat','-c')
    for i in range(12):
        sh('input swipe 540 1690 540 610 180');time.sleep(.1)
    time.sleep(1)
    result['scroll']=frame_summary(records());result['scrollPssKb']=mem()
    shot('discover-scrolled')
    tap_label('Browse');time.sleep(.5);shot('browse')
    sh('input keyevent KEYCODE_HOME');a=cpu();time.sleep(10);result['backgroundCpuTicks10s']=cpu()-a
    result['backgroundPssKb']=mem()
    (OUT/f'{MODE}-metrics.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
    summary={k:v for k,v in result.items() if k!='discoverInitial'}
    summary['discoverInitialCache']=[{k:v for k,v in r.items() if k!='frames'} for r in result['discoverInitial'] if 'cacheBytes' in r]
    print(json.dumps(summary,indent=2),flush=True)

if __name__ == "__main__": main()
