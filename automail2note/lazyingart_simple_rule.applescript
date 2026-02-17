use scripting additions

property automationScript : "/Users/lachlan/.openclaw/workspace/automation/lazyingart_simple.py"
property pythonPath : "/Users/lachlan/.openclaw/workspace/.venv/bin/python"
property logPath : "/Users/lachlan/.openclaw/workspace/logs/lazyingart_simple_rule.log"
property lockDir : "/tmp/lazyingart_simple_rule.lock"

on appendLog(textLine)
	do shell script "mkdir -p " & quoted form of "/Users/lachlan/.openclaw/workspace/logs"
	set ts to do shell script "date '+%Y-%m-%d %H:%M:%S'"
	do shell script "printf '%s %s\\n' " & quoted form of ts & quoted form of textLine & " >> " & quoted form of logPath
end appendLog

on acquireLock()
	try
		do shell script "mkdir " & quoted form of lockDir
		return true
	on error
		return false
	end try
end acquireLock

on releaseLock()
	try
		do shell script "rmdir " & quoted form of lockDir & " 2>/dev/null || true"
	end try
end releaseLock

on pipelineCommand()
	return quoted form of pythonPath & " " & quoted form of automationScript & " --latest-email"
end pipelineCommand

using terms from application "Mail"
	on perform mail action with messages theMessages for rule theRule
		set triggerCount to count of theMessages
		if (my acquireLock()) is false then
			my appendLog("skip_lock_busy trigger_count=" & triggerCount)
			return
		end if

		try
			my appendLog("trigger_received count=" & triggerCount)
			set outputText to do shell script my pipelineCommand()
			my appendLog("processed_ok output=" & outputText)
		on error errMsg number errNum
			my appendLog("processed_error code=" & errNum & " msg=" & errMsg)
		end try

		my releaseLock()
	end perform mail action with messages
end using terms from
