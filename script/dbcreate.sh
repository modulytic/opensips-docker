spawn opensips-cli -x database create
#spawn opensipsdbctl create
expect "Please provide the URL of the SQL database: "
send "mysql://root:mysql@localhost\n"
expect "Create \[a\]ll tables or just the \[c\]urrently configured ones? (Default value is a): "
send "c\n"
expect EOF
