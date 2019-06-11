
# redis
echo > redis.json '[{ "protocol": "tcp", "destination": "172.20.0.0/16", "ports": "6379", "description": "Allow Redis traffic" }]'
cf create-security-group redis_networking redis.json
cf bind-security-group redis_networking demo --lifecycle running
cf bind-security-group redis_networking demo --lifecycle staging

# mongodb
echo > mongodb.json '[{ "protocol": "tcp", "destination": "172.20.0.0/16", "ports": "27017", "description": "Allow MongoDB traffic" }]'
cf create-security-group mongodb_networking mongodb.json
cf bind-security-group mongodb_networking demo --lifecycle running
cf bind-security-group mongodb_networking demo --lifecycle staging

# MariaDB
echo > mariadb.json '[{ "protocol": "tcp", "destination": "172.20.0.0/16", "ports": "3306", "description": "Allow MariaDB traffic" }]'
cf create-security-group mariadb_networking mariadb.json
cf bind-security-group mariadb_networking demo --lifecycle running
cf bind-security-group mariadb_networking demo --lifecycle staging

# PostgreSQL
echo > postgresql.json '[{ "protocol": "tcp", "destination": "172.20.0.0/16", "ports": "5432", "description": "Allow PostgreSQL traffic" }]'
cf create-security-group postgresql_networking mariadb.json
cf bind-security-group postgresql_networking demo --lifecycle running
cf bind-security-group postgresql_networking demo --lifecycle staging


