# iCloud AutoLife Calendar Setup (2026-02-18)

Runbook for creating/migrating the **AutoLife** calendar directly into iCloud (EventKit/JXA) and removing the local duplicate.

## Why AppleScript alone fails

- `Calendar` AppleScript `make new calendar` often drops the calendar under "On My Mac" (Default store) because the iCloud store isn’t exposed reliably.
- Fix: use EventKit (JXA) to explicitly target the iCloud source (`sourceType = 2`).

## Steps

### 1. Create/ensure AutoLife under iCloud

```bash
osascript -l JavaScript <<'JXA'
ObjC.import('EventKit');
ObjC.import('Foundation');
ObjC.import('stdlib');
function wait(store, type) {
  let done = false, granted = false;
  store.requestAccessToEntityTypeCompletion(type, (ok, err) => { granted = ok; done = true; });
  const rl = $.NSRunLoop.currentRunLoop;
  while (!done) rl.runUntilDate($.NSDate.dateWithTimeIntervalSinceNow(0.1));
  return granted;
}
const U = x => ObjC.unwrap(x);
const store = $.EKEventStore.alloc.init;
if (!wait(store, 0)) throw new Error("Calendar permission denied");
const cals = store.calendarsForEntityType(0);
let iCloudSource = null;
let iCloudCal = null;
for (let i = 0; i < cals.count; i++) {
  const c = cals.objectAtIndex(i);
  const s = c.source;
  if (String(U(s.title)) === "iCloud" && Number(U(s.sourceType)) === 2) iCloudSource = s;
  if (String(U(c.title)) === "AutoLife" && String(U(s.title)) === "iCloud" && Number(U(s.sourceType)) === 2) iCloudCal = c;
}
if (!iCloudSource) throw new Error("No iCloud source found in Calendar");
if (!iCloudCal) {
  iCloudCal = $.EKCalendar.calendarForEntityTypeEventStore(0, store);
  iCloudCal.title = "AutoLife";
  iCloudCal.source = iCloudSource;
  const err = Ref();
  if (!store.saveCalendarCommitError(iCloudCal, true, err)) {
    throw new Error("Create failed: " + (err[0] ? U(err[0].localizedDescription) : "unknown"));
  }
  console.log("created=1");
} else {
  console.log("created=0");
}
console.log("calendar=AutoLife source=iCloud");
JXA
```

### 2. Verify it’s iCloud

```bash
osascript -l JavaScript <<'JXA'
ObjC.import('EventKit');
ObjC.import('Foundation');
function wait(store){
  let d=false,g=false;
  store.requestAccessToEntityTypeCompletion(0,(ok,e)=>{g=ok;d=true;});
  const rl=$.NSRunLoop.currentRunLoop;
  while(!d) rl.runUntilDate($.NSDate.dateWithTimeIntervalSinceNow(0.1));
  return g;
}
const U=x=>ObjC.unwrap(x), s=$.EKEventStore.alloc.init;
if(!wait(s)) throw new Error("no access");
const cals=s.calendarsForEntityType(0);
for(let i=0;i<cals.count;i++){
  const c=cals.objectAtIndex(i), src=c.source;
  if(String(U(c.title))==="AutoLife") console.log(`title=AutoLife source=${U(src.title)} type=${U(src.sourceType)}`);
}
JXA
```

Expect `source=iCloud type=2`.

### 3. (Optional) Move events from local AutoLife to iCloud AutoLife

```bash
osascript -l JavaScript <<'JXA'
ObjC.import('EventKit');
ObjC.import('Foundation');
function wait(store){
  let d=false,g=false;
  store.requestAccessToEntityTypeCompletion(0,(ok,e)=>{g=ok;d=true;});
  const rl=$.NSRunLoop.currentRunLoop;
  while(!d) rl.runUntilDate($.NSDate.dateWithTimeIntervalSinceNow(0.1));
  return g;
}
const U=x=>ObjC.unwrap(x), store=$.EKEventStore.alloc.init;
if(!wait(store)) throw new Error("no access");
const cals=store.calendarsForEntityType(0);
let local=null, cloud=null;
for(let i=0;i<cals.count;i++){
  const c=cals.objectAtIndex(i), src=c.source, t=String(U(c.title)), s=String(U(src.title)), ty=Number(U(src.sourceType));
  if(t==="AutoLife" && s==="Default" && ty===0) local=c;
  if(t==="AutoLife" && s==="iCloud" && ty===2) cloud=c;
}
if(!cloud) throw new Error("iCloud AutoLife not found");
if(!local){
  console.log("local_found=0");
  $.exit(0);
}
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
console.log("moved="+moved);
JXA
```

### 4. Delete the local AutoLife calendar (if it exists)

```bash
osascript -l JavaScript <<'JXA'
ObjC.import('EventKit');
ObjC.import('Foundation');
function wait(store){
  let d=false,g=false;
  store.requestAccessToEntityTypeCompletion(0,(ok,e)=>{g=ok;d=true;});
  const rl=$.NSRunLoop.currentRunLoop;
  while(!d) rl.runUntilDate($.NSDate.dateWithTimeIntervalSinceNow(0.1));
  return g;
}
const U=x=>ObjC.unwrap(x), store=$.EKEventStore.alloc.init;
if(!wait(store)) throw new Error("no access");
const cals=store.calendarsForEntityType(0);
let local=null;
for(let i=0;i<cals.count;i++){
  const c=cals.objectAtIndex(i), src=c.source;
  if(String(U(c.title))==="AutoLife" && String(U(src.title))==="Default" && Number(U(src.sourceType))===0){ local=c; break; }
}
if(local){
  const err=Ref();
  if(store.removeCalendarCommitError(local,true,err)) console.log("removed_local=1");
  else throw new Error("remove failed: "+(err[0]?U(err[0].localizedDescription):"unknown"));
} else {
  console.log("removed_local=0");
}
JXA
```

## Policy going forward

- Refer to calendars/reminder lists **by name** (“AutoLife”, “LazyingArt”). Avoid baking IDs into scripts—iCloud can change IDs per machine.
- Ensure there are no duplicate calendar names across local/iCloud sources before relying on name-only routing.
- Mail/automation pipelines should point to these names (update `defaultCalendar` / reminder list settings accordingly).
