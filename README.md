# Instructions

This is a WIP, but the image itself works, or if you don't trust mine, inspect the Dockerfile and build your own.

First, grab the config.ini file from this repo, put it in the same directory you will run the container from.

Then make sure you have an empty file ready for the database, e.g.
touch mydb.db

Then you can run the container:
docker run --rm -it -p 8080:8080 -v "$PWD/config.ini:/app/config.ini" -v "$PWD/mydb.db:/app/writefreely.db" -e WF_ADMIN_USER=myuser -e WF_ADMIN_PASS=mypassword ghcr.io/pintofbeer/writefreely:latest

Now go to:
http://localhost:8080/login

Next time you run it your database will persist, so you can omit the -e WF_ADMIN_USER=myuser -e WF_ADMIN_PASS=mypassword section, including it though does nothing it won't change the password once its set - nor will it create a new admin user.

# Kubernetes

Making it work in Kubernetes shouldn't be too dificult, when I get around to it I'll post the deployment files here.

# Why this exists

Essentially I wanted a simple journaling tool I could deploy on my cluster and this seemed to fit the bill nicely.

For more info see:
https://writefreely.org/

They have their own Docker setup which is probably better than mine.
