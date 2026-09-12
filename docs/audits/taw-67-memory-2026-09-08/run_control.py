import pathlib,subprocess,os,time,signal,json
out=pathlib.Path('/tmp/taw67/empty-clean');out.mkdir(exist_ok=True)
env=os.environ.copy();env.update(STUDY_OUTPUT=str(out),XDG_CONFIG_HOME='/tmp/taw67/release-config',XDG_DATA_HOME='/tmp/taw67/release-data',XDG_CACHE_HOME='/tmp/taw67/release-cache')
with (out/'run.log').open('w') as log:
 p=subprocess.Popen(['dbus-run-session','--','/tmp/taw67/empty-bundle/Tawaq'],env=env,stdout=log,stderr=subprocess.STDOUT,start_new_session=True)
 try:
  time.sleep(8)
  children=pathlib.Path(f'/proc/{p.pid}/task/{p.pid}/children').read_text().split()
  pid=next(c for c in children if pathlib.Path('/proc/'+c+'/cmdline').read_bytes().startswith(b'/tmp/taw67/empty-bundle/Tawaq'))
  for name in ['smaps','smaps_rollup','status']:(out/('empty.'+name)).write_bytes(pathlib.Path('/proc/'+pid+'/'+name).read_bytes())
  windows=json.loads(subprocess.check_output(['hyprctl','clients','-j']));(out/'geometry.json').write_text(json.dumps([{k:w[k] for k in ['pid','size','workspace','mapped','hidden']} for w in windows if w['pid']==int(pid)]))
  print((out/'empty.smaps_rollup').read_text());print((out/'geometry.json').read_text())
 finally:os.killpg(p.pid,signal.SIGTERM);p.wait()
