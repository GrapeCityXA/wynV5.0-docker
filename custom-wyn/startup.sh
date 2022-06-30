#!/bin/bash

# run postgresql
bash /docker-entrypoint.sh postgres > /dev/null 2>&1 &
sleep 3

# run monetdbd
bash /var/tmp/init-db.sh > /dev/null 2>&1 &
sleep 2

if [ ! -d "/wyn/jre" ]; then
  mv /opt/jre /wyn/jre > /dev/null 2>&1
fi

# write config file
if [ ! -f "/wyn/Monitor/conf/Wyn.conf" ]; then
  if [ "true" != "$IMPORT_SAMPLES" ]; then
    rm -rf "/wyn/sampledata/" > /dev/null 2>/dev/null
    rm -rf "/wyn/Server/sample_files/" > /dev/null 2>/dev/null
  fi
  
  # get database connection string
  if [ "Postgres" == "$DB_PROVIDER" ]; then
    DB_CONNECTION_STRING="Host=$DB_HOST;Port=$DB_PORT;UserName=$DB_USER;Password=$DB_PASSWORD;"
  elif [ "SqlServer" == "$DB_PROVIDER" ]; then
    DB_CONNECTION_STRING="Data Source=$DB_HOST,$DB_PORT;User ID=$DB_USER;Password=$DB_PASSWORD;"
  elif [ "MySql" == "$DB_PROVIDER" ]; then
    DB_CONNECTION_STRING="Server=$DB_HOST;Port=$DB_PORT;Uid=$DB_USER;Pwd=$DB_PASSWORD;"
   elif [ "Oracle" == "$DB_PROVIDER" ]; then
    DB_CONNECTION_STRING="USER ID=$DB_USER;PASSWORD=$DB_PASSWORD;DATA SOURCE='(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=$DB_HOST)(PORT=$DB_PORT))(CONNECT_DATA=(SERVICE_NAME=$ORACLE_SERVICE_NAME)))'"
  else
    echo "Unknown database provider detected, the supported database providers are 'Postgres', 'SqlServer', 'MySql' and 'Oracle'."
    exit 1
  fi
  
  WYN_PORTAL_PORT=51980
  WYN_SERVER_PORT=51981
  WYN_REPORTING_WORKER_PORT=51982
  WYN_COT_WORKER_PORT=51983
  WYN_DASHBOARD_WORKER_PORT=51984
  WYN_DATA_SOURCE_SERVICE_PORT=51988
  
  DATABASE_WYNIS="wynis"
  DATABASE_WYNSERVER="wynserverdata"
  DATABASE_WYNDATACACHE="wyndatacache"
  if [ "true" == "$SINGLE_DATABASE_MODE" ]; then
    DATABASE_WYNIS="wyn"
    DATABASE_WYNSERVER="wyn"
    DATABASE_WYNDATACACHE="wyn"
  fi
  
  if [ "Postgres" == "$DB_PROVIDER" -o "MySql" == "$DB_PROVIDER" ]; then
    DATABASE_CONNECTIONSTRING_IS="${DB_CONNECTION_STRING}Database=$DATABASE_WYNIS;"
    DATABASE_CONNECTIONSTRING_SERVER="${DB_CONNECTION_STRING}Database=$DATABASE_WYNSERVER;"
    DATABASE_CONNECTIONSTRING_DATACACHE="${DB_CONNECTION_STRING}Database=$DATABASE_WYNDATACACHE;"
  elif [ "SqlServer" == "$DB_PROVIDER" ]; then
    DATABASE_CONNECTIONSTRING_IS="${DB_CONNECTION_STRING}Initial Catalog=$DATABASE_WYNIS;"
    DATABASE_CONNECTIONSTRING_SERVER="${DB_CONNECTION_STRING}Initial Catalog=$DATABASE_WYNSERVER;"
    DATABASE_CONNECTIONSTRING_DATACACHE="${DB_CONNECTION_STRING}Initial Catalog=$DATABASE_WYNDATACACHE;"
  elif [ "Oracle" == "$DB_PROVIDER" ]; then
    DATABASE_CONNECTIONSTRING_IS="${DB_CONNECTION_STRING}"
    DATABASE_CONNECTIONSTRING_SERVER="${DB_CONNECTION_STRING}"
    DATABASE_CONNECTIONSTRING_DATACACHE="${DB_CONNECTION_STRING}"
  fi
  
  requireHttps="false"
  if [ "true" == "$REQUIRE_HTTPS" ]; then
    requireHttps="true"
    echo "# Default server configuration
server {
  listen 443 ssl http2;

  ssl on;
  ssl_certificate /usr/local/share/ca-certificates/wyn/$SSL_CERTIFICATE_FILE;
  ssl_certificate_key /usr/local/share/ca-certificates/wyn/$SSL_CERTIFICATE_KEY_FILE;
  ssl_protocols TLSv1.2;
  server_name $SITE_NAME;
  large_client_header_buffers 4 32k;

  error_page 504 /custom_504.html;
  location = /custom_504.html {
    root /usr/share/nginx/html;
    internal;
  }

  location / {
    proxy_pass                        http://localhost:51980;
    proxy_http_version                1.1;
    proxy_set_header Upgrade          \$http_upgrade;
    proxy_set_header Connection       keep-alive;
    proxy_set_header Host             \$host;
    proxy_cache_bypass                \$http_upgrade;
    proxy_set_header X-Real-IP        \$remote_addr;
    proxy_set_header X-Forwarded-For  \$proxy_add_x_forwarded_for;
    proxy_connect_timeout             300s;
    proxy_send_timeout                300s;
    proxy_read_timeout                300s;
    send_timeout                      300s;
    sendfile                          on;
    proxy_buffer_size                 64k;
    proxy_buffers                     32 32k;
    proxy_busy_buffers_size           128k;
    fastcgi_buffers                   8 16k;
    fastcgi_buffer_size               32k;
    client_max_body_size              100M;
  }
}" > /etc/nginx/sites-available/default
    nginx -s reload
  fi
  
  echo "/opt/google/chrome/chrome" > /wyn/Server/.ChromeExecutablePath
  
  # rewrite configuration file
  echo "<?xml version=\"1.0\" encoding=\"utf-8\"?>
<SystemConfig xmlns:sys=\"https://extendedxmlserializer.github.io/system\" xmlns=\"clr-namespace:ConfigMigration.Configuration.V50;assembly=ConfigMigration\">
  <Version>5.0</Version>
  <GlobalSettings>
    <IdentityServerUrl>http://localhost:$WYN_SERVER_PORT</IdentityServerUrl>
  </GlobalSettings>
  <Services>
    <Server>
      <Urls>http://*:$WYN_SERVER_PORT</Urls>
      <DataSourceProxy>
        <URI>http://localhost:$WYN_DATA_SOURCE_SERVICE_PORT</URI>
      </DataSourceProxy>
      <Storage>
        <StorageType>$DB_PROVIDER</StorageType>
        <ConnectionString>$DATABASE_CONNECTIONSTRING_SERVER</ConnectionString>
      </Storage>
      <DataExtraction>
        <StorageType>$DB_PROVIDER</StorageType>
        <ConnectionString>$DATABASE_CONNECTIONSTRING_DATACACHE</ConnectionString>
      </DataExtraction>
      <IdentityServer>
        <StorageType>$DB_PROVIDER</StorageType>
        <ConnectionString>$DATABASE_CONNECTIONSTRING_IS</ConnectionString>
        <HideWynIcon>true</HideWynIcon>
        <HideTrialKeyButton>true</HideTrialKeyButton>
      </IdentityServer>
    </Server>
    <Portal>
      <Urls>http://*:$WYN_PORTAL_PORT</Urls>
      <RequireHttps>$requireHttps</RequireHttps>
      <HideWelcomeScreen>true</HideWelcomeScreen>
    </Portal>
    <Worker>
      <Urls>http://localhost:$WYN_REPORTING_WORKER_PORT</Urls>
    </Worker>
    <CotWorker>
      <Urls>http://localhost:$WYN_COT_WORKER_PORT</Urls>
    </CotWorker>
    <DashboardWorker>
      <Urls>http://localhost:$WYN_DASHBOARD_WORKER_PORT</Urls>
      <ChromeExecutablePath>/opt/google/chrome/chrome</ChromeExecutablePath>
    </DashboardWorker>
    <DataSourceService>
      <Urls>http://localhost:$WYN_DATA_SOURCE_SERVICE_PORT</Urls>
    </DataSourceService>
  </Services>
</SystemConfig>" > /wyn/Monitor/conf/Wyn.conf
fi

# start or stop nginx
if [ "true" == "$REQUIRE_HTTPS" ]; then
  service nginx start > /dev/null 2>&1
else
  service nginx stop > /dev/null 2>&1
fi

sleep 5

# startup wyn monitor
cd /wyn/Monitor
dotnet ServiceMonitor.dll

