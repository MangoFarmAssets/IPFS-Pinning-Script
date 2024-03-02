#!/bin/bash

path="/home/ubuntu/Pinner"
echo "Generating list of unique IPFS hashes from Ravencoin assets..."
raven-cli listassets | sed 's/"//g' | sed 's/,//g' | xargs -i raven-cli getassetdata {} | grep ipfs_hash | sed 's/"//g' | sed 's/,//g' | sed 's/ipfs_hash://g' | sed 's/ //g' | sort | uniq > $path/tmp/RVN_hashlist.txt
sleep 5
echo "    Done!"
echo -n "    hashes found: " ; wc -l <$path/tmp/RVN_hashlist.txt

echo "Generating list of IPFS pins on our node..."
ipfs pin ls | sed 's/ indirect//g' | sed 's/ recursive//g' | sort | uniq > $path/tmp/IPFS_pinlist.txt
sleep 5
echo "    Done!"
echo -n "    hashes found: " ; wc -l <$path/tmp/IPFS_pinlist.txt

echo "Comparing lists to find unpinned hashes..."
comm -23 <(sort $path/tmp/RVN_hashlist.txt) <(sort $path/tmp/IPFS_pinlist.txt) > $path/tmp/unpinned_hashes.txt
sleep 5
echo "    Done!"

echo -n "    total unpinned hashes: " ; wc -l <$path/tmp/unpinned_hashes.txt

echo "Excluding hashes lost to history"
echo -n "    total hashes excluded: " ; wc -l <$path/lost_hashes/lost_hashes.txt
comm -23 <(sort $path/tmp/unpinned_hashes.txt) <(sort $path/lost_hashes/lost_hashes.txt) > $path/tmp/new_pins.txt
sleep 5

WC=$(wc -l <$path/tmp/new_pins.txt)
echo "Attempting to pin $WC new hashes to IPFS..."

while read line; do
        echo "***Attempting to locate and pin $line"
        ipfs pin add $line --timeout 30s
sleep 3
done < $path/tmp/new_pins.txt
echo -n "   Done!"
sleep 3

echo $(date -u) >> $path/logs/log.txt
echo "     Total hashes attempted: $WC" >> $path/logs/log.txt
sleep 3

echo -n "Cleaning up"
sudo rm -r $path/tmp/RVN_hashlist.txt $path/tmp/IPFS_pinlist.txt $path/tmp/unpinned_hashes.txt $path/tmp/new_pins.txt
echo "     Pinning complete." >> $path/logs/log.txt
