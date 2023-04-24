for file in "$@"
do
    mkdir -p "../graph/frontend-abi/$file/"
    cp -R "out/$file/" "../graph/frontend-abi/$file/"
    mkdir -p "../frontend/frontend-abi/$file/"
    cp -R "out/$file/" "../frontend/frontend-abi/$file/"
done