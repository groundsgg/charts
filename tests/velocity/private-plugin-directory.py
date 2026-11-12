"""The shared volume must not let a different UID replace a private plugin cache directory."""
import json, pathlib, subprocess
root = pathlib.Path(__file__).resolve().parents[2]
chart = root / 'charts' / 'grounds-velocity'
def render(*args):
    rendered = subprocess.check_output(['helm','template','velocity',str(chart),*args],text=True)
    return json.loads(subprocess.check_output(['yq','eval-all','-o=json','-I=0','[.]','-'],input=rendered,text=True))
resources = render('--set','plugins[0]=plugin-chat')
pod = next(r for r in resources if r and r['kind']=='Deployment')['spec']['template']['spec']
init = pod['initContainers']
assert init[0]['name']=='prepare-plugin-directory', 'Shared volume must be prepared before any seed/fetch'
assert init[0]['command']==['sh','-c','chmod 1777 /plugins'], 'Sticky bit prevents replacing another UID private directory'
assert init[0]['securityContext']=={
    'runAsUser':0,'runAsGroup':0,'allowPrivilegeEscalation':False,'readOnlyRootFilesystem':True,
    'capabilities':{'drop':['ALL']},'seccompProfile':{'type':'RuntimeDefault'},
}
assert init[0]['volumeMounts']==[{'name':'plugins','mountPath':'/plugins'}]
assert init[1]['name']=='copy-baked-plugins'
assert init[1]['command']==['sh','-c','cp -r /app/plugins/. /plugins/'], 'Preserve non-root seed ownership'
assert 'securityContext' not in init[1], 'Do not turn the seed/copy or main proxy into root'
empty = next(r for r in render() if r and r['kind']=='Deployment')['spec']['template']['spec']
assert not empty.get('initContainers'), 'Do not create mount preparers when no plugins volume is used'
print('Private plugin directory: rendered sticky preparation and unchanged seed/defaults passed')
