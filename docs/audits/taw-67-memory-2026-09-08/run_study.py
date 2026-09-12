import os,sys,subprocess,pathlib,json,time,signal
out=pathlib.Path(sys.argv[1]);out.mkdir(exist_ok=True)
env=os.environ.copy();env.update(STUDY_OUTPUT=str(out),XDG_CONFIG_HOME='/tmp/taw67/release-config',XDG_DATA_HOME='/tmp/taw67/release-data',XDG_CACHE_HOME='/tmp/taw67/release-cache')
p=subprocess.Popen(['dbus-run-session','--',sys.argv[2]],env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,start_new_session=True)
try:
 with (out/'run.log').open('w') as log:
  for line in p.stdout:
   log.write(line);log.flush()
   if line.startswith('STUDY {'):
    j=json.loads(line[6:]);pid=j['pid'];label=j['label'];base=pathlib.Path('/proc')/str(pid)
    for name in ['smaps','smaps_rollup','status']:
     (out/(label+'.'+name)).write_bytes((base/name).read_bytes())
    print(line.strip(),flush=True)
   elif line.startswith('STUDY'):print(line.strip(),flush=True)
   if line.startswith('STUDY DONE'):break
finally:
 os.killpg(p.pid,signal.SIGTERM);p.wait()
