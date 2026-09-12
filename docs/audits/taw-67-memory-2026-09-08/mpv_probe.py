import ctypes as C,os,sys,time,json,pathlib
out=pathlib.Path('/tmp/taw67/audio-'+sys.argv[1]);out.mkdir(exist_ok=True)
def sample(label):
 s=pathlib.Path('/proc/self/smaps_rollup').read_text();(out/(label+'.rollup')).write_text(s)
 print(label,{l.split(':')[0]:l.split(':')[1].strip() for l in s.splitlines() if l.startswith(('Rss:','Pss:','Swap:'))},flush=True)
sample('python-base')
m=C.CDLL('/tmp/taw67/baseline-release/lib/libmpv.so');m.mpv_create.restype=C.c_void_p
m.mpv_initialize.argtypes=[C.c_void_p];m.mpv_set_option_string.argtypes=[C.c_void_p,C.c_char_p,C.c_char_p];m.mpv_command.argtypes=[C.c_void_p,C.POINTER(C.c_char_p)];m.mpv_get_property_string.argtypes=[C.c_void_p,C.c_char_p];m.mpv_get_property_string.restype=C.c_void_p;m.mpv_free.argtypes=[C.c_void_p];m.mpv_terminate_destroy.argtypes=[C.c_void_p]
p=m.mpv_create()
opts={'vid':'no','sid':'no','vo':'null','ao':'null','pause':'yes','resume-playback':'no','force-seekable':'yes','keep-open':'yes','idle':'yes','input-builtin-bindings':'no','volume':'0','config':'no'}
if sys.argv[1]=='bounded':opts.update({'demuxer-max-bytes':str(8*1024*1024),'demuxer-max-back-bytes':str(2*1024*1024)})
for k,v in opts.items():
 r=m.mpv_set_option_string(p,k.encode(),v.encode())
 if r<0:print('option error',k,r)
assert m.mpv_initialize(p)>=0
time.sleep(2);sample('initialized')
def prop(k):
 r=m.mpv_get_property_string(p,k.encode())
 if not r:return None
 s=C.string_at(r).decode();m.mpv_free(r);return s
print('actual limits',{k:prop(k) for k in ['demuxer-max-bytes','demuxer-max-back-bytes','cache','cache-secs']},flush=True)
a=(C.c_char_p*4)(b'loadfile',b'http://127.0.0.1:43891/sample.mp3',b'replace',None);assert m.mpv_command(p,a)>=0
time.sleep(6);sample('http-buffered');print('state',{k:prop(k) for k in ['duration','pause','demuxer-cache-duration','demuxer-cache-state']},flush=True)
a=(C.c_char_p*2)(b'stop',None);m.mpv_command(p,a);time.sleep(2);sample('stopped');print('stop-state',{k:prop(k) for k in ['idle-active','path','demuxer-cache-state']},flush=True);m.mpv_terminate_destroy(p);sample('disposed');C.CDLL('libc.so.6').malloc_trim(0);sample('trimmed')
