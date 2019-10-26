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
Options=rw,hard,nointr,rsize=65536,wsize=65536,bg,proto=tcp,lazytime,minorversion=1

[Install]
WantedBy=network-online.target
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
Options=rw,hard,nointr,rsize=65536,wsize=65536,bg,proto=tcp,lazytime,minorversion=1

[Install]
WantedBy=network-online.target
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
Options=rw,hard,nointr,rsize=65536,wsize=65536,bg,proto=tcp,lazytime,minorversion=1

[Install]
WantedBy=network-online.target
WantedBy=multi-user.target
EOF

cat >   /usr/lib/systemd/system/mnt-homemovies.mount << "EOF"
[Unit]
Description=Plex Home Movies
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
Options=rw,hard,nointr,rsize=65536,wsize=65536,bg,proto=tcp,lazytime,minorversion=1

[Install]
WantedBy=network-online.target
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
Options=rw,hard,nointr,rsize=65536,wsize=65536,bg,proto=tcp,lazytime,minorversion=1

[Install]
WantedBy=network-online.target
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
Options=rw,hard,nointr,rsize=65536,wsize=65536,bg,proto=tcp,lazytime,minorversion=1

[Install]
WantedBy=network-online.target
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
Options=rw,hard,nointr,rsize=65536,wsize=65536,bg,proto=tcp,lazytime,minorversion=1

[Install]
WantedBy=network-online.target
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
Options=rw,hard,nointr,rsize=65536,wsize=65536,bg,proto=tcp,lazytime,minorversion=1

[Install]
WantedBy=network-online.target
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
Options=rw,hard,nointr,rsize=65536,wsize=65536,bg,proto=tcp,lazytime,minorversion=1

[Install]
WantedBy=network-online.target
WantedBy=multi-user.target
EOF

systemctl enable systemd-networkd-wait-online.service

systemctl disable opt-data.mount
systemctl disable mnt-books.mount
systemctl disable mnt-comics.mount
systemctl disable mnt-homemovies.mount
systemctl disable mnt-movies.mount
systemctl disable mnt-pictures.mount
systemctl disable mnt-processing.mount
systemctl disable mnt-tv.mount
systemctl disable mnt-music.mount


systemctl enable opt-data.mount
systemctl enable mnt-books.mount
systemctl enable mnt-comics.mount
systemctl enable mnt-homemovies.mount
systemctl enable mnt-movies.mount
systemctl enable mnt-pictures.mount
systemctl enable mnt-processing.mount
systemctl enable mnt-tv.mount
systemctl enable mnt-music.mount


systemctl start opt-data.mount
systemctl start mnt-books.mount
systemctl start mnt-comics.mount
systemctl start mnt-homemovies.mount
systemctl start mnt-movies.mount
systemctl start mnt-pictures.mount
systemctl start mnt-processing.mount
systemctl start mnt-tv.mount
systemctl start mnt-music.mount