# Update zig
sudo snap refresh
echo "zig" `zig version`

# Update zls
pushd ../zls
md5sum /usr/local/bin/zls
git pull
zig build
sudo rm -f              /usr/local/bin/zls
sudo cp zig-out/bin/zls /usr/local/bin
md5sum /usr/local/bin/zls
echo "zls" `zls --version`
popd
