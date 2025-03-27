# config/initializers/mailcow_db.rb
MAILCOW_DB_CONFIG = {
  adapter:  "mysql2",
  host:     "127.0.0.1",
  port:     13306,
  database: "mailcow",
  username: "mailcow",
  password: "xTXfua5bRPqCsKpliaq0B2W1kVMU",
  pool:     5,
  timeout:  5000
}
