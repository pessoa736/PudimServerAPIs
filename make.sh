
version="0.3.1-1"
project="pudimserver"


rockspecLocation="./rockspecs/$project-$version.rockspec"

mode="$1"


updateProject(){
    ./luarocks make "$rockspecLocation"
}


upload(){
    ./luarocks upload "$rockspecLocation"
}

if [[ "$mode" == "upload" ]]; then
    upload
elif [[ "$mode" == "run" ]]; then
    ./lua "$2"
elif [[ "$mode" == "update" ]]; then
    updateProject
fi