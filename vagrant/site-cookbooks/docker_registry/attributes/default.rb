override[:ntp][:servers] = %w(ntp.nict.jp, ntp.jst.mfeed.ad.jp)

override[:docker][:group_members] = %w(vagrant)

default["docker_registry"]["packages"] = %w(
vim
curl
)
