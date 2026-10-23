"""Real-device stall check. Resolves search/tab/station bounds from UI hierarchy,
hides keyboard before row taps and verifies media-session title after each tap.
Usage: python device_stall_verified.py [package] [alone|switch|both]
"""
import json, os, re, subprocess, sys, time, xml.etree.ElementTree as ET
sys.stdout.reconfigure(encoding='utf-8')
ADB = r'C:\Users\natbo\AppData\Local\Android\Sdk\platform-tools\adb.exe'
PKG = sys.argv[1] if len(sys.argv)>1 else 'com.radiov2.radiov2_android'
MODE = sys.argv[2] if len(sys.argv)>2 else 'both'
ACT = PKG + '/com.radiov2.radiov2_android.MainActivity'
DEAD = 'Burina.NET Demo Radio'
GOOD = '#lofi | by reyfm.de'
def sh(cmd):
    p=subprocess.run([ADB,'shell',cmd],capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=30)
    if p.returncode: raise RuntimeError(p.stderr)
    return p.stdout

def nodes():
    sh('uiautomator dump /data/local/tmp/rv2_stall_ui.xml')
    root=ET.fromstring(sh('cat /data/local/tmp/rv2_stall_ui.xml'))
    return [n.attrib for n in root.iter('node')]
def label(n): return n.get('text') or n.get('content-desc','')
def tap(n):
    a,b,c,d=map(int,re.findall(r'\d+',n['bounds']))
    sh('input tap %d %d'%((a+c)//2,(b+d)//2))
def find(pred):
    ns=nodes()
    hits=[n for n in ns if pred(n)]
    if not hits: raise AssertionError('Expected UI element absent. Visible: '+repr([label(n) for n in ns if label(n)]))
    return hits[0]
def session():
    out=sh('dumpsys media_session')
    m=re.search(r'^\s*package='+re.escape(PKG)+r'\s*$',out,re.M)
    if not m:return '?',''
    block=out[m.start():]
    # Bound the extraction at the next session package.
    end=re.search(r'\n\s+package=',block[len(m.group()):])
    if end:block=block[:len(m.group())+end.start()]
    st=re.search(r'state=PlaybackState \{state=(\w+)',block)
    title=re.search(r'description=([^\r\n]+)',block)
    value=st.group(1) if st else '?'
    value={'NONE':'0','STOPPED':'1','PAUSED':'2','PLAYING':'3','BUFFERING':'6','ERROR':'7','CONNECTING':'8'}.get(value,value)
    return value, (title.group(1).strip() if title else '')
def search(query):
    box=find(lambda n:n.get('class','').endswith('EditText'))
    tap(box)
    sh('input keycombination 113 29')
    sh("input text '%s'"%query.replace(' ','%s'))
    time.sleep(.6)
    sh('input keyevent KEYCODE_BACK')
    time.sleep(.3)
def station(name):
    n=find(lambda n:label(n)==name and not n.get('class','').endswith('EditText'))
    a,b,c,d=map(int,re.findall(r'\d+',n['bounds']))
    assert c-a>800 and d-b>100,('Not a station row',n)
    return n

def start_dead():
    sh('input keyevent KEYCODE_WAKEUP')
    sh('am force-stop '+PKG)
    sh('am start -n '+ACT)
    time.sleep(2)
    tap(find(lambda n:'Tab 1 of 3' in label(n)))
    search(DEAD)
    n=station(DEAD)
    t=time.monotonic();tap(n)
    st,title=session()
    assert DEAD in title,('Dead tap did not reach the player',st,title)
    print('verified dead tap:',st,title,flush=True)
    return t

def watch(t,limit,want,title):
    changes=[]
    while time.monotonic()-t<limit:
        st,meta=session();elapsed=round(time.monotonic()-t,2)
        if not changes or changes[-1][1]!=st:changes.append((elapsed,st));print('state',changes[-1],flush=True)
        assert title in meta,('Unexpected station',meta)
        if st==want:return {'elapsed_s':elapsed,'reached':True,'states':changes}
        time.sleep(.15)
    return {'elapsed_s':round(time.monotonic()-t,2),'reached':False,'states':changes}
vol=re.search(r'volume is (\d+)',sh('cmd media_session volume --stream 3 --get')).group(1)
results={}
try:
    sh('cmd media_session volume --stream 3 --set 1')
    if MODE in ('alone','both'):
        t=start_dead();results['dead_alone']=watch(t,90,'7',DEAD)
    if MODE in ('switch','both'):
        t=start_dead()
        search('lofi')
        n=station(GOOD)
        print('seconds spent navigating after dead tap',round(time.monotonic()-t,2),flush=True)
        t=time.monotonic();tap(n)
        st,title=session();assert GOOD in title,('Good tap did not reach player',st,title)
        print('verified good tap:',st,title,flush=True)
        results['dead_then_good']=watch(t,85,'3',GOOD)
    print(json.dumps({'package':PKG,'results':results}),flush=True)
finally:
    sh('am force-stop '+PKG)
    sh('cmd media_session volume --stream 3 --set '+vol)
    sh('rm -f /data/local/tmp/rv2_stall_ui.xml')
    sh('input keyevent KEYCODE_HOME')
    print('restored volume',vol,flush=True)
