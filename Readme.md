# GCE Account

Initialized with `default` and `orichaud@gmail.com`. Source hosting not selected. Command to initialize the cloud:
``` sh
gcloud init
gcloud auth login
```

# Git:

* [https://github.com/orichaud/gce.git](https://github.com/orichaud/gce.git)

``` sh
git init
git add .
git commit -m "initialization"
git remote add origin https://github.com/orichaud/gce.git
git remote -v
git push origin master

```

# Creating a VM formation

``` sh
./create_stack.sh
```
