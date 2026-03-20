#!/bin/sh
git add -A
git commit -m "Update"
git checkout upstream
rm -Rf pgraft
git clone https://github.com/pgElephant/pgraft.git

cd pgraft
OrigTAG=$(git describe --tags --abbrev=0)
rm -Rf .git

echo "Enter version " $OrigTAG " : "
read TAG
git tag $TAG 
git add -A
git commit -m "Update upstream"
git push
git push origin $TAG 
cd ../

git checkout main
git merge upstream -m "Merge with upstream $TAG"
cd pgraft/src/
rm -Rf vendor
go mod tidy -v
go mod vendor -v
cd ../../

git tag -d $(git tag -l "postgres*")
git push origin --delete $(git ls-remote --refs origin postgres* | cut -d$'\t' -f2)

gear-store-tags -ac
git add -A
git commit -m "Update Vendor $TAG"
gear-create-tag -n "postgrespro-1c-18" -s pgver=postgrespro-1c-18
gear-create-tag -n "postgresql17" -s pgver=postgresql17
git push
git push origin --tags

