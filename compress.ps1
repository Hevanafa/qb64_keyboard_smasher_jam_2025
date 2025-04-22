Copy-Item .\main.exe .\main_packed.exe
upx --best .\main_packed.exe
