#!/bin/bash
set -o xtrace

cat >   /usr/lib/systemd/system/opt-data.mount << "EOF"
[Unit]
Description=Synology mount for application configs
Documentation=man:hier(7)
DefaultDependencies=no
Conflicts=umount.target
Wants=network-online.target
Requires=network-online.target
Before=local-fs.target umount.target docker.service
After=syslog.target network.target network-online.target

[Mount]
What=172.28.1.220:/volume1/htpc_server_data
Where=/opt/data/
Type=nfs4
#Options=rw,hard,nointrbg,proto=tcp,lazytime,minorversion=1
Options=auto,nofail,noatime,nolock,intr,tcp,actimeo=1800

[Install]
WantedBy=network-online.target
WantedBy=multi-user.target
EOF

cat >   /usr/lib/systemd/system/opt-data.automount << "EOF"
[Unit]
Description=Synology mount for application configs

[Automount]
Where=/opt/data/

[Install]
WantedBy=multi-user.target
EOF

cat >   /usr/lib/systemd/system/mnt-books.mount << "EOF"
[Unit]
Description=Synology mount for books
Documentation=man:hier(7)
DefaultDependencies=no
Conflicts=umount.target
Wants=network-online.target
Requires=network-online.target
Before=local-fs.target umount.target docker.service
After=syslog.target network.target network-online.target

[Mount]
What=172.28.1.220:/volume1/books
Where=/mnt/books/
Type=nfs4
#Options=rw,hard,nointrbg,proto=tcp,lazytime,minorversion=1
Options=auto,nofail,noatime,nolock,intr,tcp,actimeo=1800

[Install]
WantedBy=network-online.target
WantedBy=multi-user.target
EOF

cat >   /usr/lib/systemd/system/mnt-books.automount << "EOF"
[Unit]
Description=Synology automount for books

[Automount]
Where=/mnt/books/

[Install]
WantedBy=multi-user.target
EOF

cat >   /usr/lib/systemd/system/mnt-comics.mount << "EOF"
[Unit]
Description=Synology mount for comics
Documentation=man:hier(7)
DefaultDependencies=no
Conflicts=umount.target
Wants=network-online.target
Requires=network-online.target
Before=local-fs.target umount.target docker.service
After=syslog.target network.target network-online.target

[Mount]
What=172.28.1.220:/volume1/comics
Where=/mnt/comics/
Type=nfs4
#Options=rw,hard,nointrbg,proto=tcp,lazytime,minorversion=1
Options=auto,nofail,noatime,nolock,intr,tcp,actimeo=1800

[Install]
WantedBy=network-online.target
WantedBy=multi-user.target
EOF

cat >   /usr/lib/systemd/system/mnt-comics.automount << "EOF"
[Unit]
Description=Synology automount for comics

[Automount]
Where=/mnt/comics/

[Install]
WantedBy=multi-user.target
EOF


cat >   /usr/lib/systemd/system/mnt-homemovies.mount << "EOF"
[Unit]
Description=Plex automount Home Movies
Documentation=man:hier(7)
DefaultDependencies=no
Conflicts=umount.target
Wants=network-online.target
Requires=network-online.target
Before=local-fs.target umount.target docker.service
After=syslog.target network.target network-online.target

[Mount]
What=172.28.1.220:/volume1/HomeMovies
Where=/mnt/homemovies
Type=nfs4
#Options=rw,hard,nointrbg,proto=tcp,lazytime,minorversion=1
Options=auto,nofail,noatime,nolock,intr,tcp,actimeo=1800

[Install]
WantedBy=network-online.target
WantedBy=multi-user.target
EOF

cat >   /usr/lib/systemd/system/mnt-homemovies.automount << "EOF"
[Unit]
Description=Synology automount for home movies

[Automount]
Where=/mnt/homemovies/

[Install]
WantedBy=multi-user.target
EOF

cat >  /usr/lib/systemd/system/mnt-movies.mount << "EOF"
[Unit]
Description=Plex Movies
Documentation=man:hier(7)
DefaultDependencies=no
Conflicts=umount.target
Wants=network-online.target
Requires=network-online.target
Before=local-fs.target umount.target docker.service
After=syslog.target network.target network-online.target

[Mount]
What=172.28.1.220:/volume1/Movies
Where=/mnt/movies
Type=nfs4
#Options=rw,hard,nointrbg,proto=tcp,lazytime,minorversion=1
Options=auto,nofail,noatime,nolock,intr,tcp,actimeo=1800

[Install]
WantedBy=network-online.target
WantedBy=multi-user.target
EOF

cat >   /usr/lib/systemd/system/mnt-movies.automount << "EOF"
[Unit]
Description=Synology automount for movies

[Automount]
Where=/mnt/movies/

[Install]
WantedBy=multi-user.target
EOF

cat >  /usr/lib/systemd/system/mnt-pictures.mount << "EOF"
[Unit]
Description=Plex Pictures
Documentation=man:hier(7)
DefaultDependencies=no
Conflicts=umount.target
Wants=network-online.target
Requires=network-online.target
Before=local-fs.target umount.target docker.service
After=syslog.target network.target network-online.target

[Mount]
What=172.28.1.220:/volume1/Pictures
Where=/mnt/pictures
Type=nfs4
#Options=rw,hard,nointrbg,proto=tcp,lazytime,minorversion=1
Options=auto,nofail,noatime,nolock,intr,tcp,actimeo=1800

[Install]
WantedBy=network-online.target
WantedBy=multi-user.target
EOF

cat >   /usr/lib/systemd/system/mnt-pictures.automount << "EOF"
[Unit]
Description=Synology automount for pictures

[Automount]
Where=/mnt/pictures/

[Install]
WantedBy=multi-user.target
EOF

cat >  /usr/lib/systemd/system/mnt-processing.mount << "EOF"
[Unit]
Description=Working Directories for downloaders
Documentation=man:hier(7)
DefaultDependencies=no
Conflicts=umount.target
Wants=network-online.target
Requires=network-online.target
Before=local-fs.target umount.target docker.service
After=syslog.target network.target network-online.target

[Mount]
What=172.28.1.220:/volume1/Processing
Where=/mnt/processing
Type=nfs4
#Options=rw,hard,nointrbg,proto=tcp,lazytime,minorversion=1
Options=auto,nofail,noatime,nolock,intr,tcp,actimeo=1800

[Install]
WantedBy=network-online.target
WantedBy=multi-user.target
EOF

cat >   /usr/lib/systemd/system/mnt-processing.automount << "EOF"
[Unit]
Description=Synology automount for processing

[Automount]
Where=/mnt/processing/

[Install]
WantedBy=multi-user.target
EOF

cat >  /usr/lib/systemd/system/mnt-tv.mount << "EOF"
[Unit]
Description=Plex TV Shows
Documentation=man:hier(7)
DefaultDependencies=no
Conflicts=umount.target
Wants=network-online.target
Requires=network-online.target
Before=local-fs.target umount.target docker.service
After=syslog.target network.target network-online.target

[Mount]
What=172.28.1.220:/volume1/TVShows
Where=/mnt/tv
Type=nfs4
#Options=rw,hard,nointrbg,proto=tcp,lazytime,minorversion=1
Options=auto,nofail,noatime,nolock,intr,tcp,actimeo=1800

[Install]
WantedBy=network-online.target
WantedBy=multi-user.target
EOF

cat >   /usr/lib/systemd/system/mnt-tv.automount << "EOF"
[Unit]
Description=Synology automount for tv shows

[Automount]
Where=/mnt/tv/

[Install]
WantedBy=multi-user.target
EOF

cat >  /usr/lib/systemd/system/mnt-music.mount << "EOF"
[Unit]
Description=Plex Music
Documentation=man:hier(7)
DefaultDependencies=no
Conflicts=umount.target
Wants=network-online.target
Requires=network-online.target
Before=local-fs.target umount.target docker.service
After=syslog.target network.target network-online.target

[Mount]
What=172.28.1.220:/volume1/music
Where=/mnt/music
Type=nfs4
#Options=rw,hard,nointrbg,proto=tcp,lazytime,minorversion=1
Options=auto,nofail,noatime,nolock,intr,tcp,actimeo=1800

[Install]
WantedBy=network-online.target
WantedBy=multi-user.target
EOF

cat >   /usr/lib/systemd/system/mnt-music.automount << "EOF"
[Unit]
Description=Synology automount for music

[Automount]
Where=/mnt/music/

[Install]
WantedBy=multi-user.target
EOF

cat >  /usr/lib/systemd/system/mnt-moviesbackup.mount << "EOF"
[Unit]
Description=Plex Movies Backup (older) mount
Documentation=man:hier(7)
DefaultDependencies=no
Conflicts=umount.target
Wants=network-online.target
Requires=network-online.target
Before=local-fs.target umount.target docker.service
After=syslog.target network.target network-online.target

[Mount]
What=172.28.1.226:/mnt/md0/moviesbackup
Where=/mnt/moviesbackup/
Type=nfs
#Options=rw,hard,nointrbg,proto=tcp,lazytime,minorversion=1
Options=auto,nofail,noatime,nolock,intr,tcp,actimeo=1800

[Install]
WantedBy=network-online.target
WantedBy=multi-user.target
EOF

cat >   /usr/lib/systemd/system/mnt-moviesbackup.automount << "EOF"
[Unit]
Description=Synology automount for movies

[Automount]
Where=/mnt/moviesbackup/

[Install]
WantedBy=multi-user.target
EOF

cat >  /usr/lib/systemd/system/mnt-tvshowsbackup.mount << "EOF"
[Unit]
Description=Plex TV Shows Backup Mount
Documentation=man:hier(7)
DefaultDependencies=no
Conflicts=umount.target
Wants=network-online.target
Requires=network-online.target
Before=local-fs.target umount.target docker.service
After=syslog.target network.target network-online.target

[Mount]
What=172.28.1.226:/mnt/md0/tvshowsbackup
Where=/mnt/tvshowsbackup
Type=nfs4
#Options=rw,hard,nointrbg,proto=tcp,lazytime,minorversion=1
Options=auto,nofail,noatime,nolock,intr,tcp,actimeo=1800

[Install]
WantedBy=network-online.target
WantedBy=multi-user.target
EOF

cat >   /usr/lib/systemd/system/mnt-tvshowsbackup.automount << "EOF"
[Unit]
Description=Synology automount for tv shows

[Automount]
Where=/mnt/tvshowsbackup/

[Install]
WantedBy=multi-user.target
EOF

systemctl enable systemd-networkd-wait-online.service

systemctl daemon-reload

systemctl disable opt-data.mount
systemctl disable mnt-books.mount
systemctl disable mnt-comics.mount
systemctl disable mnt-homemovies.mount
systemctl disable mnt-movies.mount
systemctl disable mnt-pictures.mount
systemctl disable mnt-processing.mount
systemctl disable mnt-tv.mount
systemctl disable mnt-music.mount
systemctl disable mnt-moviesbackup.mount
systemctl disable mnt-tvshowsbackup.mount

systemctl disable opt-data.automount
systemctl disable mnt-books.automount
systemctl disable mnt-comics.automount
systemctl disable mnt-homemovies.automount
systemctl disable mnt-movies.automount
systemctl disable mnt-pictures.automount
systemctl disable mnt-processing.automount
systemctl disable mnt-tv.automount
systemctl disable mnt-music.automount
systemctl disable mnt-moviesbackup.automount
systemctl disable mnt-tvshowsbackup.automount

systemctl enable opt-data.mount
systemctl enable mnt-books.mount
systemctl enable mnt-comics.mount
systemctl enable mnt-homemovies.mount
systemctl enable mnt-movies.mount
systemctl enable mnt-pictures.mount
systemctl enable mnt-processing.mount
systemctl enable mnt-tv.mount
systemctl enable mnt-music.mount
systemctl enable mnt-moviesbackup.mount
systemctl enable mnt-tvshowsbackup.mount

systemctl enable opt-data.automount
systemctl enable mnt-books.automount
systemctl enable mnt-comics.automount
systemctl enable mnt-homemovies.automount
systemctl enable mnt-movies.automount
systemctl enable mnt-pictures.automount
systemctl enable mnt-processing.automount
systemctl enable mnt-tv.automount
systemctl enable mnt-music.automount
systemctl enable mnt-moviesbackup.automount
systemctl enable mnt-tvshowsbackup.automount

systemctl start opt-data.mount
systemctl start mnt-books.mount
systemctl start mnt-comics.mount
systemctl start mnt-homemovies.mount
systemctl start mnt-movies.mount
systemctl start mnt-pictures.mount
systemctl start mnt-processing.mount
systemctl start mnt-tv.mount
systemctl start mnt-music.mount
systemctl start mnt-moviesbackup.mount
systemctl start mnt-tvshowsbackup.mount

systemctl start opt-data.automount
systemctl start mnt-books.automount
systemctl start mnt-comics.automount
systemctl start mnt-homemovies.automount
systemctl start mnt-movies.automount
systemctl start mnt-pictures.automount
systemctl start mnt-processing.automount
systemctl start mnt-tv.automount
systemctl start mnt-music.automount
systemctl start mnt-moviesbackup.automount
systemctl start mnt-tvshowsbackup.automount