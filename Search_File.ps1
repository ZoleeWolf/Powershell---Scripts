Get-PSDrive -PSProvider FileSystem | ForEach-Object {Get-ChildItem -Path $_.Root -Recurse -ErrorAction SilentlyContinue -Force | Where-Object { $_.Name -like "*spark*.*"}}

