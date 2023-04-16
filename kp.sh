#!/bin/bash

echo -e "$SColor KP Started"

log="./logs/KPLOG.log"
> $log

rm -f db/command_post_journal.db || true
sqlite3 db/command_post_journal.db "DROP TABLE IF EXISTS Warnings_Log;"
sqlite3 db/command_post_journal.db << CREATE_WARNINGS_LOG
CREATE TABLE Warnings_Log (
	id INTEGER PRIMARY KEY,
	timestamp DATETIME NOT NULL DEFAULT (strftime('%d/%m/%Y %H:%M:%S.%3N', 'now', 'localtime')),
	system_id TEXT NOT NULL,
	information TEXT NOT NULL,
	target_id varchar(6),
	coordinates TEXT
);
CREATE_WARNINGS_LOG


sqlite3 db/command_post_journal.db "DROP TABLE IF EXISTS Targets_Log;"
sqlite3 db/command_post_journal.db << CREATE_TARGETS_LOG
CREATE TABLE Targets_Log (
	id INTEGER PRIMARY KEY,
	timestamp DATETIME NOT NULL DEFAULT (strftime('%d/%m/%Y %H:%M:%S.%3N', 'now', 'localtime')),
	system_id TEXT NOT NULL,
	status TEXT NOT NULL,
	target_id varchar(6),
	coordinates TEXT
);
CREATE_TARGETS_LOG


sqlite3 db/command_post_journal.db "DROP TABLE IF EXISTS Status_Log;"
sqlite3 db/command_post_journal.db << CREATE_STATUS_LOG
	CREATE TABLE Status_Log (
	id INTEGER PRIMARY KEY,
	timestamp DATETIME NOT NULL DEFAULT (strftime('%d/%m/%Y %H:%M:%S.%3N', 'now', 'localtime')),
	system_id TEXT NOT NULL,
	status TEXT NOT NULL,
	missiles INTEGER
);
CREATE_STATUS_LOG


targetsLog="messages/TargetsLog"
warningsLog="messages/WarningsLog"
statusLog="messages/StatusLog"

while :
do
	# Log all warnings
	for wlog_file in `ls -tr $warningsLog 2>/dev/null`
	do
		IFS=','; info=(`cat "$warningsLog/$wlog_file"`); unset IFS;
		sqlite3 db/command_post_journal.db "insert into Warnings_Log (timestamp, system_id, information, target_id, coordinates)
						values ('${info[0]}','${info[1]}', '${info[2]}', '${info[3]}', '${info[4]}');"
		echo -e "${info[0]},${info[1]},${info[2]},${info[3]},${info[4]}" >> "$log"
		rm -f "$warningsLog/$wlog_file"
	done

	# Log all targets actions
	for tlog_file in `ls -tr $targetsLog 2>/dev/null`
	do
		IFS=','; info=(`cat "$targetsLog/$tlog_file"`); unset IFS;
		sqlite3 db/command_post_journal.db "insert into Targets_Log (timestamp, system_id, status, target_id, coordinates)
						values ('${info[0]}','${info[1]}', '${info[2]}', '${info[3]}', '${info[4]}');"
		echo -e "${info[0]},${info[1]},${info[2]},${info[3]},${info[4]}" >> "$log"
		rm -f "$targetsLog/$tlog_file"
	done

	# Log all statuses
	for slog_file in `ls -tr $statusLog 2>/dev/null`
	do
		IFS=','; info=(`cat "$statusLog/$slog_file"`); unset IFS;
		sqlite3 db/command_post_journal.db "insert into Status_Log (timestamp, system_id, status, missiles)
						values ('${info[0]}','${info[1]}', '${info[2]}', '${info[3]}');"
		echo -e "${info[0]},${info[1]},${info[2]},${info[3]}" >> "$log"
		rm -f "$statusLog/$slog_file"
	done

	sleep 1.0
done


# sqlite3 db/command_post_journal.db "insert into Warning_Log (timestamp, system_id, information, target_id, coordinates)
# 			values ('$moscow_time','RLS_1', 'test_message', 'abc123', 'X69994,Y214234');"

# echo -e '.mode column\n.headers on\nselect * from Warnings_Log ORDER BY timestamp ASC;\n' | sqlite3 db/command_post_journal.db

# sqlite3 db/command_post_journal.db "insert into Status_Log (timestamp, system_id, status, missiles)
# 	values ('$moscow_time','RLS_1', 'OK', 4);"
# echo -e '.mode column\n.headers on\nselect * from Status_Log ORDER BY timestamp ASC;\n' | sqlite3 db/command_post_journal.db

# echo -e '.mode column\n.headers on\nselect * from Targets_Log ORDER BY timestamp ASC;\n' | sqlite3 db/command_post_journal.db

