FROM golang:1.22 AS builder

# Install deps for SQLite
RUN apt update && apt install -y git gcc libsqlite3-dev make npm

# Build as per https://writefreely.org/docs/latest/developer/setup
WORKDIR /app
RUN git clone https://github.com/writefreely/writefreely.git /app && \
    cd /app && \
    go build -v -tags='sqlite' ./cmd/writefreely/

RUN npm install -g less@3.5.3
RUN npm install -g less-plugin-clean-css

RUN cd /app/less && \
    CSSDIR=../static/css && \
    lessc app.less --clean-css="--s1 --advanced" ${CSSDIR}/write.css && \
    lessc fonts.less --clean-css="--s1 --advanced" ${CSSDIR}/fonts.css && \
    lessc icons.less --clean-css="--s1 --advanced" ${CSSDIR}/icons.css && \
    lessc prose.less --clean-css="--s1 --advanced" ${CSSDIR}/prose.css

# Add dummy config file
RUN cat << 'EOF' > /app/config.ini
[server]
hidden_host          =
port                 = 8080
bind                 = 0.0.0.0
tls_cert_path        =
tls_key_path         =
autocert             = false
templates_parent_dir =
static_parent_dir    =
pages_parent_dir     =
keys_parent_dir      =
hash_seed            =
gopher_port          = 0

[database]
type     = sqlite3
filename = /data/writefreely.db
username =
password =
database =
host     = localhost
port     = 3306
tls      = false

[app]
site_name             = Testing 123
site_description      =
host                  = http://localhost:8080
theme                 = write
editor                =
disable_js            = false
webfonts              = true
landing               =
simple_nav            = false
wf_modesty            = false
chorus                = false
forest                = false
disable_drafts        = false
single_user           = true
open_registration     = false
open_deletion         = false
min_username_len      = 3
max_blogs             = 1
federation            = false
public_stats          = true
monetization          = false
notes_only            = false
private               = false
local_timeline        = false
user_invites          =
default_visibility    =
update_checks         = false
disable_password_auth = false

[email]
smtp_host             =
smtp_port             = 0
smtp_username         =
smtp_password         =
smtp_enable_start_tls = false
domain                =
mailgun_private       =
mailgun_europe        = false

[oauth.slack]
client_id          =
client_secret      =
team_id            =
callback_proxy     =
callback_proxy_api =

[oauth.writeas]
client_id          =
client_secret      =
auth_location      =
token_location     =
inspect_location   =
callback_proxy     =
callback_proxy_api =

[oauth.gitlab]
client_id          =
client_secret      =
host               =
display_name       =
callback_proxy     =
callback_proxy_api =

[oauth.gitea]
client_id          =
client_secret      =
host               =
display_name       =
callback_proxy     =
callback_proxy_api =

[oauth.generic]
client_id          =
client_secret      =
host               =
display_name       =
callback_proxy     =
callback_proxy_api =
token_endpoint     =
inspect_endpoint   =
auth_endpoint      =
scope              =
allow_disconnect   = false
map_user_id        =
map_username       =
map_display_name   =
map_email          =
EOF

# Final image
FROM debian:bookworm-slim

RUN apt update && apt install -y ca-certificates sqlite3 && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/writefreely /app/writefreely
COPY --from=builder /app/config.ini /app/config.ini
COPY --from=builder /app/templates /app/templates
COPY --from=builder /app/static /app/static
COPY --from=builder /app/pages /app/pages
COPY --from=builder /app/keys /app/keys

WORKDIR /app

# Create /start.sh with executable content
RUN cat << 'EOF' > /start.sh
#!/bin/bash
echo "Init files..."
DB_DIR="/data"
DB_PATH="$DB_DIR/writefreely.db"

if [ ! -d "$DB_DIR" ]; then
  echo "ERROR: Database directory '$DB_DIR' does not exist. Is the PVC mounted?"
  exit 1
fi

if [ ! -f "$DB_PATH" ]; then
  echo "Creating empty SQLite DB file at $DB_PATH"
  touch "$DB_PATH"
  chmod 660 "$DB_PATH"  # Optional: set permissions
fi

echo "Starting WriteFreely..."
cd /app
./writefreely db init
./writefreely --gen-keys
./writefreely user create --admin $WF_ADMIN_USER:$WF_ADMIN_PASS
./writefreely
# your commands here
EOF

# Make script executable
RUN chmod +x /start.sh

# Accept admin credentials as environment variables
ENV WF_ADMIN_USER=wf_admin
ENV WF_ADMIN_PASS=changeme

EXPOSE 8080

CMD ["/start.sh"]
