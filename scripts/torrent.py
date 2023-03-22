import os
import sys
import time
import qbittorrentapi

magnet_uri = sys.argv[1]

qbt = qbittorrentapi.Client(
  host='torrent',
  port=8080,
  username='admin',
  password='adminadmin'
)

try:
  qbt.auth_log_in()
except qbittorrentapi.LoginFailed as e:
  print(e)

qbt.torrents.add(urls=magnet_uri)

completed = False
while not completed:
  for torrent in qbt.torrents.info.completed():
    if torrent.magnet_uri == magnet_uri:
      completed = True
  time.sleep(5)
