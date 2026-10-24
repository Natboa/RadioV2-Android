"""Measure visible Discover settling from a 30fps physical-screen recording.
Reports first visible content change -> stable final artwork, not adb/UI-dump
latency. Local genre assets only; repeated process-cold, filesystem-warm runs.
"""
import json, shutil, subprocess, time
from device_redesign import adb, sh, tap_label, OUT, MODE, PKG, ACT
FF=shutil.which('ffmpeg')
rows=[]
for i in range(3):
    sh('am force-stop '+PKG);sh('am start -n '+ACT);time.sleep(1)
    # Resolve bounds before recording; no hierarchy-dump latency in the metric.
    from device_redesign import nodes,label
    import re
    n=next(n for n in nodes() if 'Discover\nTab' in label(n))
    a,b,c,d=map(int,re.findall(r'\d+',n['bounds']))
    remote='/data/local/tmp/rv2_load.mp4'
    rec=subprocess.Popen([__import__('device_redesign').ADB,'shell','screenrecord','--size','540x1170','--bit-rate','6M','--time-limit','5',remote],stdout=subprocess.DEVNULL)
    time.sleep(.9);sh(f'input tap {(a+c)//2} {(b+d)//2}');rec.wait(timeout=15)
    path=OUT/f'{MODE}-art-loading-{i+1}.mp4';adb('pull',remote,str(path))
    data=subprocess.check_output([FF,'-v','error','-i',str(path),'-vf','fps=30,crop=540:870:0:180,scale=54:87,format=gray','-f','rawvideo','-'])
    nbytes=54*87;frames=[data[j:j+nbytes] for j in range(0,len(data)-nbytes+1,nbytes)]
    diff=lambda a,b:sum(abs(x-y) for x,y in zip(a,b))/len(a)
    start=next(j for j,f in enumerate(frames) if diff(f,frames[0])>3)
    settled=next(j for j in range(start,len(frames)-3) if all(diff(frames[k],frames[-1])<1.2 for k in range(j,j+3)))
    rows.append({'visibleChangeToSettledMs':round((settled-start)*1000/30), 'firstChangeFrame':start,'settledFrame':settled})
sh('rm -f /data/local/tmp/rv2_load.mp4')
(OUT/f'{MODE}-art-loading.json').write_text(json.dumps(rows,indent=2),encoding='utf-8')
print(json.dumps(rows,indent=2),flush=True)
