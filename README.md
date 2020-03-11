# Docker LizardFS

A Docker image that can be used to build a fully functional [LizardFS](https://lizardfs.com) cluster.

## Usage

The same Docker image is used to run each different kind of LizardFS service: `master`, `metalogger`, `chunkserver`, `cgiserver`, and `client`. You tell the container which service to run by setting the Docker command, or by passing in the service name after the image name on the commandline.

**docker-compose.yml**
```yaml
version: '3'
services:
  mfsmaster:
    image: katharostech/lizardfs
    command: master
  metalogger:
    image: katharostech/lizardfs
    command: metalogger
...
```

Or on the commandline:

```bash
$ docker run -d --name mfsmaster katharostech/lizardfs master
```

### Services

#### Master, Metalogger, and Chunkserver

The `master`, `metalogger`, and `chunkserver` services are configured using environment variables ( see [configuration](#Configuration) ).

#### CGI Server

The CGI Server, by default, starts a webserver inside the container running on port `80`. You can set the `MASTER_HOST` and `MASTER_PORT` environment variables and the container will proxy the internal port 9421 to that master host and port. The web UI will then, by default, connect to that internal proxy when connecting to the master. Alternatively, when accessing the web UI you can put the master host ( and port as well, if it is not `9421` ) in the url: `http://192.168.99.100:8080/mfs.cgi?masterhost=mfsmaster&masterport=19421`.

If you would, for any reason, like to change the port that the CGI server is running on *inside* the container, you can specify the port after `cgiserver` in the Docker command. For example:

    docker run -d --name cgiserver katharostech/lizardfs cgiserver 8080

#### Client

You can run the container with the `client` command and it will look for and connect to the `mfsmaster` and mount the filesystem into the container at `/mnt/mfs`. You can change which path the filesystem is mounted to by passing it in after `client`. The container will also need to be run as privileged and linked to the master container. For example:

```bash
$ docker run -d --name mymaster katharostech/lizardfs master
$ docker run -d --name myclient --link mymaster:mfsmaster --privileged katharostech/lizardfs client /mnt/my-alternate-moutpoint
```

All arguments passed in after `client` and the moutpoint will be passed directly to the `mfsmount` command. You can see all available options with `--help`.

```bash
$ docker run --privileged katharostech/lizardfs client --help
```

After the client has connected, you can access the LizardFS filesystem by `exec`ing into the container.

```bash
$ docker exec -it myclient bash
root@contianerid:/$ cd /mnt/mfs
root@containerid:/mnt/mfs$ echo "LizardFS file" > lizardfsfile.txt
root@containerid:/mnt/mfs$ cat lizardfsfile.txt
LizardFS file
```

## Deployment

The LizardFS Docker image is deployed easiest through [Docker Compose](https://docs.docker.com/compose/overview) or [Docker Swarm](https://docs.docker.com/engine/swarm/). We have provided a [docker-compose.yml](/docker-compose.yml) file that can be used to test a LizardFS cluster on a local Docker installation such as [Docker Machine](https://docs.docker.com/machine/overview/).

### Docker Compose

Docker Compose is the easiest way to deploy a test LizardFS cluster on a single machine. This is a great way to test the features of LizardFS. Because it only runs on a single machine this setup not useful in production. For running in production use Docker Swarm.

This repository comes with a Docker Compose file that can be used to run a test cluster. To get started just clone this repository and run `docker-compose up` in the repository root directory.

```bash
$ cd docker_lizardfs
$ docker-compose up -d --scale mfsmaster-shadow=2 --scale chunkserver=3 --scale metalogger=4
```

You can then hit the web interface on `8080` at the IP address of the server running Docker. On the "Servers" tab of the web interface you should be able to see that you have a cluster consisting of 1 master, 2 shadow masters, 3 chunkservers, and 4 metaloggers. Congratulations you are running a full LizardFS cluster!

You can experiment with the cluster by creating some files. Exec into one of the client containers and copy `/etc` inside the container to the LizardFS mountpoint at `/mnt/mfs`.

```bash
$ docker-compose exec client1 bash
root@containerid:/$ cd /mnt/mfs
root@containerid:/mnt/mfs$ cp -R /etc .
```

The web UI will show that you now have 218 chunks in your cluster.

![web-ui-screenshot](/web-ui-screenshot.png)

`exec`ing into the other client container will prove that you successfully mounted your LizardFS filesystem on two clients at the same time.

```bash
$ docker-compose exec client2 bash
root@containerid:/$ cd /mnt/mfs
root@containerid:/mnt/mfs$ ls
etc
```

### Docker Swarm

TODO

## Configuration

All of the LizardFS services can be completely configured through envronment variables. The container will generate the required config files based on the passed in environment variables.

### Skipping Configuration Generation

If you would instead prefer to mount in configuration files, you can disable config file generation by setting the `SKIP_CONFIGURE` environment variable to `"true"`.

> **Note:** Part of the configuration step is changing the owner of the storage directories to `mfs:mfs` so that LizardFS can access them. If you set `SKIP_CONFIGURE=true` this step will be skipped as well. You will have to make sure that the owner of the data directories is uid 9421 and gid 9421. For example: `chown -R 9421:9421 /data/dir`.

### Master Configuration

#### mfsmaster.cfg

The [mfsmaster.cfg](https://docs.lizardfs.com/man/mfsmaster.cfg.5.html) file is the primary config file for the LizardFS master. It is made up of a list of key-value pairs that are explained in the [documentation](https://docs.lizardfs.com/man/mfsmaster.cfg.5.html). You can add any key-value pair to the `mfsmaster.cfg` file by adding an environment variable in the format of `MFSMASTER_KEY_NAME=value`. For example, if you wanted to run a LizardFS shadow master you could do the following:

```bash
$ docker run -d --name shadow -e MFSMASTER_PERSONALITY=shadow katharostech/lizardfs
```

This you can do for any key-value pairs you want to add to the `mfsmaster.cfg` file.

#### mfsexports.cfg

The [mfsexports.cfg](https://docs.lizardfs.com/man/mfsexports.cfg.5.html) file configures access to the LizardFS filesystem. Each line in the file allows access to a portion of the filesystem according to the given rules. You set the lines in the file by adding environment variables in the format of `MFSEXPORTS_LINE_NUMBER='line contents'`. The first two lines, `MFSEXPORTS_1` and `MFSEXPORTS_2`, are preset to the LizardFS defaults:

```ini
*                       /       rw,alldirs,maproot=0
*                       .       rw
```

This exports the root filesystem and the metadata path to any ip address and gives read-write access. These lines can be overwritten by setting the values of `MFSEXPORTS_1` and `MFSEXPORTS_2`. Additional lines can also be added by setting `MFSEXPORTS_3`, `MFSEXPORTS_4`, and so on for however many rules are desired.

#### mfsgoals.cfg

The [mfsgoals.cfg](https://docs.lizardfs.com/man/mfsgoals.cfg.5.html) file configures replication goals for LizardFS. More information about configuring replication goals can be found in the [LizardFS documentation](https://docs.lizardfs.com/adminguide/replication.html).

The lines of this file can be configured using environment variables ( see [mfsexports.cfg](#mfsexports.cfg) ). The first five lines are preset to the LizardFS defaults:

```
1 1 : _
2 2 : _ _
3 3 : _ _ _
4 4 : _ _ _ _
5 5 : _ _ _ _ _
```

> **Warning:** When setting goals that require the use of the `$` sign, such as erasure coding rules. Be sure to escape the `$` sign if setting the value in a Docker Compose file. To put a literal `$` in an environment variable in a compose file you use `$$`. For example:
>
> ```yaml
> ...
> environment:
>   MFSGOALS_5: "5 erasure_coding_rule : $$ec(3,1)"
> ...
> ```

#### mfstopology.cfg

The [mfstopology.cfg](https://docs.lizardfs.com/man/mfstopology.cfg.5.html) file allows you to optionally assign different IP addresses to different network locations.

The lines of this file can be configured using environment variables ( see [mfexports.cfg](#mfsexports.cfg) ). This file has no entries by default.

### Metalogger Configuration

#### mfsmetalogger.cfg

The [mfsmetalogger.cfg](https://docs.lizardfs.com/man/mfsmetalogger.cfg.5.html) file is made up of a list of key-value pairs used to configure the Metalogger service.

This file can be configured using environment variables ( see [mfsmaster.cfg](#mfsmaster.cfg) ).

### Chunkserver Configuration

#### mfschunkserver.cfg

The [mfschunkserver.cfg](https://docs.lizardfs.com/man/mfschunkserver.cfg.5.html) is made up of a list of key-value pairs used to configure the Chunkserver service.

This file can be configured using environment variables ( see [mfsmaster.cfg](#mfsmaster.cfg) ).

#### mfshdd.cfg

The [mfshdd.cfg](https://docs.lizardfs.com/man/mfshdd.cfg.5.html) file is a list of mountpoints or directories that LizardFS will use for storage. In general these should be dedicated drives formatted as either XFS or ZFS. Each line should be a path that will be used for storage. A path prefixed with a `*` will be evacuated and all data will be replicated to different drives.

The lines of this file can be configured using environment variables ( see [mfexports.cfg](#mfsexports.cfg) ). This file has no entries by default.
