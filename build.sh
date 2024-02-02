#echo "Linux"
zig build-exe src/main.zig -target x86_64-linux-gnu
mv main zpu-bench

#echo "Windows"
#zig build-exe src/main.zig -target x86_64-windows-gnu 

#echo "Linux"
time ./zpu-bench

#echo "Windows"
#time wine ./main.exe
