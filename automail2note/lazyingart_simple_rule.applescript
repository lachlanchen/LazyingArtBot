use scripting additions

property automationScript : "/Users/lachlan/.openclaw/workspace/automation/lazyingart_simple.py"
property pythonPath : "/Users/lachlan/.openclaw/workspace/.venv/bin/python"
property logPath : "/Users/lachlan/.openclaw/workspace/logs/lazyingart_simple_rule.log"
property lockDir : "/tmp/lazyingart_simple_rule.lock"
property defaultCalendar : "LazyingArt"
property triggerWaitSeconds : 180
property triggerPollSeconds : 10
property triggerGraceSeconds : 45
property lockWaitSeconds : 120

on appendLog(textLine)
	do shell script "mkdir -p " & quoted form of "/Users/lachlan/.openclaw/workspace/logs"
	set ts to do shell script "date '+%Y-%m-%d %H:%M:%S'"
	do shell script "printf '%s %s\\n' " & quoted form of ts & quoted form of textLine & " >> " & quoted form of logPath
end appendLog

on oneLine(rawText)
	set txt to rawText as text
	set txt to do shell script "printf '%s' " & quoted form of txt & " | tr '\\r\\n' '  '"
	return txt
end oneLine

on acquireLock()
	try
		do shell script "mkdir " & quoted form of lockDir
		return true
	on error
		return false
	end try
end acquireLock

on acquireLockWithRetry(maxSeconds)
	repeat with i from 1 to maxSeconds
		if (my acquireLock()) is true then return true
		delay 1
	end repeat
	return false
end acquireLockWithRetry

on releaseLock()
	try
		do shell script "rmdir " & quoted form of lockDir & " 2>/dev/null || true"
	end try
end releaseLock

on pipelineCommand(triggerEpoch)
	set baseCmd to quoted form of pythonPath & " " & quoted form of automationScript & " --latest-email"
	if (defaultCalendar as text) is not "" then
		set baseCmd to baseCmd & " --default-calendar " & quoted form of (defaultCalendar as text)
	end if
	set baseCmd to baseCmd & " --trigger-epoch " & quoted form of (triggerEpoch as text)
	set baseCmd to baseCmd & " --trigger-wait-seconds " & quoted form of (triggerWaitSeconds as text)
	set baseCmd to baseCmd & " --trigger-poll-seconds " & quoted form of (triggerPollSeconds as text)
	set baseCmd to baseCmd & " --trigger-grace-seconds " & quoted form of (triggerGraceSeconds as text)
	return baseCmd
end pipelineCommand

using terms from application "Mail"
	on perform mail action with messages theMessages for rule theRule
		set triggerCount to count of theMessages
		set triggerEpoch to do shell script "date +%s"
		if (my acquireLockWithRetry(lockWaitSeconds)) is false then
			my appendLog("skip_lock_timeout trigger_count=" & triggerCount & " trigger_epoch=" & triggerEpoch)
			return
		end if

		try
			my appendLog("trigger_received count=" & triggerCount & " trigger_epoch=" & triggerEpoch)
			repeat with i from 1 to triggerCount
				try
					set outputText to do shell script my pipelineCommand(triggerEpoch)
					my appendLog("processed_ok idx=" & i & "/" & triggerCount & " output=" & my oneLine(outputText))
				on error errMsg number errNum
					my appendLog("processed_error idx=" & i & "/" & triggerCount & " code=" & errNum & " msg=" & my oneLine(errMsg))
					exit repeat
				end try
			end repeat
		on error errMsg number errNum
			my appendLog("processed_error code=" & errNum & " msg=" & my oneLine(errMsg))
		end try

		my releaseLock()
	end perform mail action with messages
end using terms from
