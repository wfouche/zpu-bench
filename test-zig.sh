rm -f -r hello-world
mkdir hello-world
pushd hello-world
zig init-exe
zig build run
zig build test
popd
