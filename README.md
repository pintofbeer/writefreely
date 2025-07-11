# Instructions

This is a WIP, but the image itself works, or if you don't trust mine, inspect the Dockerfile and build your own.

First, grab the config.ini file from this repo, put it in the same directory you will run the container from.

Then make sure you have an empty file ready for the database, e.g.
touch mydb.db

Then you can run the container:
docker run --rm -it -p 8080:8080 -v "$PWD/config.ini:/app/config.ini" -v "$PWD/mydb.db:/data/writefreely.db" -e WF_ADMIN_USER=myuser -e WF_ADMIN_PASS=mypassword ghcr.io/pintofbeer/writefreely:latest

Now go to:
http://localhost:8080/login

Next time you run it your database will persist, so you can omit the -e WF_ADMIN_USER=myuser -e WF_ADMIN_PASS=mypassword section, including it though does nothing it won't change the password once its set - nor will it create a new admin user.

# Kubernetes

Making it work in Kubernetes isn't too difficult I've included some yaml files to get you going.

Note this is a basic setup, I've only tested it with the sqlite backend, not MySQL - I may not have included relevant packages in the Dockerfile for that.

First, give it a namespace, optional but tidier.

```
kubectl create namespace writefree-blog
```

Then copy the config file (edit it first) into a secret for the deployment to access as a file. Ideally, update your host name in config.ini to the hostname it will ultimately have. I think this is only relevant for federation to work, but worth doing.

```
kubectl create secret generic writefreely-config --from-file=config.ini=./config.ini -n writefree-blog
```

Then provision some storage, this uses your default provider, for me that's longhorn.

```
kubectl apply -f ./pvc.yaml -n writefree-blog
```

Now do the deployment, update the username and password in this, as you can't change it later:

```
kubectl apply -f ./deploy.yaml -n writefree-blog
```

Finally, create a service. This sets up a ClusterIP, change it if you need LoadBalancer.

```
kubectl apply -f ./svc.yaml -n writefree-blog
```

Now if you need it set up some ingress, personally I have a Cloudflare tunnel running inside my cluster so I can just point domains to the service hostname on that (likely `writefreely.writefree-blog.svc.cluster.local` if following this guide). Saves all the faff with SSL provisioning etc.

# Why this exists

Essentially I wanted a simple journaling tool I could deploy on my cluster and this seemed to fit the bill nicely.

For more info see:
https://writefreely.org/

They have their own Docker setup which is probably better than mine.

If your curious my public version lives here:

https://dave.madel.in
