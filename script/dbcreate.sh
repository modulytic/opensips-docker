spawn opensips-cli -x database create
#spawn opensipsdbctl create
expect "Please provide the URL of the SQL database: "
send "mysql://root:mysql@localhost\n"
expect EOF
