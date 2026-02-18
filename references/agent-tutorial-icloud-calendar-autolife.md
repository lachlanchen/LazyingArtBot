# Agent Tutorial: Create AutoLife in iCloud (Not On-My-Mac)

This runbook explains how to create and verify an iCloud calendar named `AutoLife`, migrate local events into it, and keep name-based defaults (no hardcoded IDs).

## Why previous attempts failed

- AppleScript `make new calendar` does not reliably target iCloud source.
- On some systems it creates under local `Default` (On My Mac).
- Use EventKit via JXA to target source `iCloud` (sourceType `2`).

## 1) Create or ensure iCloud calendar `AutoLife`

```bash
osascript -l JavaScript <<'JXA'
ObjC.import('EventKit'); ObjC.import('Foundation'); ObjC.import('stdlib');

function wait(store, type) {
  let done = false, granted = false;
  store.requestAccessToEntityTypeCompletion(type, (ok, err) => { granted = ok; done = true; });
  const rl = $.NSRunLoop.currentRunLoop;
  while (!done) rl.runUntilDate($.NSDate.dateWithTimeIntervalSinceNow(0.1));
  return granted;
}
const U = x => ObjC.unwrap(x);

const store = $.EKEventStore.alloc.init;
if (!wait(store, 0)) throw new Error('Calendar permission denied');

const cals = store.calendarsForEntityType(0);
let iCloudSource = null;
let iCloudCal = null;

for (let i = 0; i < cals.count; i++) {
  const c = cals.objectAtIndex(i);
  const s = c.source;
  if (String(U(s.title)) === 'iCloud' && Number(U(s.sourceType)) === 2) iCloudSource = s;
  if (String(U(c.title)) === 'AutoLife' && String(U(s.title)) === 'iCloud' && Number(U(s.sourceType)) === 2) iCloudCal = c;
}

if (!iCloudSource) throw new Error('No iCloud source found in Calendar');
if (!iCloudCal) {
  iCloudCal = $.EKCalendar.calendarForEntityTypeEventStore(0, store);
  iCloudCal.title = 'AutoLife';
  iCloudCal.source = iCloudSource;
  const err = Ref();
  if (!store.saveCalendarCommitError(iCloudCal, true, err)) {
    throw new Error('Create failed: ' + (err[0] ? U(err[0].localizedDescription) : 'unknown'));
  }
  console.log('created=1');
} else {
  console.log('created=0');
}
console.log('calendar=AutoLife source=iCloud');
JXA
```

## 2) Verify it is really iCloud

```bash
osascript -l JavaScript <<'JXA'
ObjC.import('EventKit'); ObjC.import('Foundation');

function wait(store){
  let done=false, granted=false;
  store.requestAccessToEntityTypeCompletion(0,(ok,e)=>{granted=ok; done=true;});
  const rl=$.NSRunLoop.currentRunLoop;
  while(!done) rl.runUntilDate($.NSDate.dateWithTimeIntervalSinceNow(0.1));
  return granted;
}

const U=x=>ObjC.unwrap(x);
const s=$.EKEventStore.alloc.init;
if(!wait(s)) throw new Error('no access');

const cals=s.calendarsForEntityType(0);
for(let i=0;i<cals.count;i++){
  const c=cals.objectAtIndex(i), src=c.source;
  if(String(U(c.title))==='AutoLife') {
    console.log(`title=AutoLife source=${U(src.title)} type=${U(src.sourceType)}`);
  }
}
JXA
```

Expected: `source=iCloud type=2`

## 3) Move events from local `AutoLife` to iCloud `AutoLife` (if local exists)

```bash
osascript -l JavaScript <<'JXA'
ObjC.import('EventKit'); ObjC.import('Foundation');

function wait(store){
  let done=false, granted=false;
  store.requestAccessToEntityTypeCompletion(0,(ok,e)=>{granted=ok; done=true;});
  const rl=$.NSRunLoop.currentRunLoop;
  while(!done) rl.runUntilDate($.NSDate.dateWithTimeIntervalSinceNow(0.1));
  return granted;
}

const U=x=>ObjC.unwrap(x), store=$.EKEventStore.alloc.init;
if(!wait(store)) throw new Error('no access');

const cals=store.calendarsForEntityType(0);
let local=null, cloud=null;
for(let i=0;i<cals.count;i++){
  const c=cals.objectAtIndex(i), src=c.source;
  const t=String(U(c.title)), s=String(U(src.title)), ty=Number(U(src.sourceType));
  if(t==='AutoLife' && s==='Default' && ty===0) local=c;
  if(t==='AutoLife' && s==='iCloud' && ty===2) cloud=c;
}
if(!cloud) throw new Error('iCloud AutoLife not found');
if(!local){ console.log('local_found=0'); $.exit(0); }

const start=$.NSDate.dateWithTimeIntervalSince1970(0), end=$.NSDate.distantFuture;
const pred=store.predicateForEventsWithStartDateEndDateCalendars(start,end,$([local]));
const events=store.eventsMatchingPredicate(pred);
let moved=0;
for(let i=0;i<events.count;i++){
  const ev=events.objectAtIndex(i);
  ev.calendar=cloud;
  const err=Ref();
  if(store.saveEventSpanCommitError(ev,0,true,err)) moved++;
}
console.log('moved='+moved);
JXA
```

## 4) Use name-based defaults only (no ID)

Set defaults to calendar/list names in your pipeline scripts.

Typical files:

- `~/.openclaw/workspace/automation/lazyingart_simple_rule.applescript`
- `~/.openclaw/workspace/automation/lazyingart_simple.py`
- `~/.openclaw/workspace/automation/lazyingart_apply_action.py`
- `~/.openclaw/workspace/automation/create_reminder.applescript`

For example:

- `defaultCalendar = "AutoLife"` (or `"LazyingArt"` if mail automation should stay separated)
- reminder default list by name

## 5) Important safety rule

Name-only routing is safe only when the name is unique.

- If duplicate calendars exist with the same name across sources, routing is ambiguous.
- First remove/rename duplicate local calendars.
- Then keep name-only defaults.
