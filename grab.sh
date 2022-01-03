#!/bin/bash
# Grab steam group ID's automatically
# this will get your IP blocked by Steam depending on how often you run this.
# Might have issues on larger lists
funny="76561197960265728" # Convert 64 to 32 (vice versa)
RD=$(tput setaf 1)
GR=$(tput setaf 2)
RE=$(tput sgr0)

function getSteamIDs() {
    if [ -f groups ]; then
        echo $GR"Grabbing group member ID's..."$RE
        for i in $(seq $(wc -l <groups)); do
            LINE=$(head -n "$i" groups | tail -n +"$i")
            echo $GR"Grabbing $LINE"$RE
            curl --connect-timeout 5 https://steamcommunity.com/groups/"$LINE"/memberslistxml/?xml=1 | grep 'steamID64' | tr -d '</>,' | sed 's/steamID64//g' >>64ids.tmp
        done
        tr -d '\r' <64ids.tmp >64ids.tmp2
        sort -u -n 64ids.tmp2 >Group/64ids # that was easy
        rm 64ids.*
    else
        echo $RD"Missing groups file, Quitting!"$RE
        exit 0
    fi
}
# Input STEAM ID64 to get STEAM ID32
function convertToSteamID32() {
      STEAMID32=$(($1 - funny))
      echo $STEAMID32
}
# Input STEAM ID32 to get STEAM ID64
function convertToSteamID64() {
      STEAMID64=$(($1 + funny))
      echo $STEAMID64
}

# Input STEAM ID64 to get STEAM ID
function convertToSteamID() {
      STEAMID32=$(convertToSteamID32 $1)
      if [ $(($STEAMID32 % 2)) -eq 0 ]; then
            AUTHID=0
      else
            AUTHID=1
      fi
      STEAMID=$((STEAMID32 - AUTHID))
      OUTPUT=$((STEAMID / 2))
      echo STEAM_0:$AUTHID:$OUTPUT
}

function Convert(){
    if [ -f Group/64ids ]; then
        for i in $(seq "$(wc -l <Group/64ids)"); do
            # we have to do this since the loop includes a \r
            LINE=$(head -n "$i" Group/64ids | tail -n +"$i")
            STEAMID32=$(convertToSteamID32 $LINE)
            # Now do some quick maths to output the correct format
            # (if steamid is not >= max 32int)
            if [[ ! "$STEAMID32" -ge "2147483647" ]]; then
                echo $STEAMID32 >>Group/32ids
            else
                echo $RD"Wrong format! $STEAMID32"$RE
            fi
        done
    else
        echo $RD"Missing Group/64ids!, Quitting!"$RE
        exit 0
    fi
    # Sort found SteamIDs32/64 and check for duplicates
    # We have to do this since we copied over the ids with >> (which makes them repeat)
    # shitpost code
    cat Group/32ids >>OUT/32ids.tmp
    cat Group/64ids >>OUT/64ids.tmp
    cat OUT/32ids.tmp | sort -un >OUT/32ids.tmp2
    cat OUT/64ids.tmp | sort -un >OUT/64ids.tmp2
    mv OUT/32ids.tmp2 OUT/32ids
    mv OUT/64ids.tmp2 OUT/64ids
    mv OUT/32ids ../TacobotList/32ids
    mv OUT/64ids ../TacobotList/64ids
    # Alright we're done here
    rm OUT/*.tmp*
    # Convert 32ids for TF2BD
    php convert.php >../TacobotList/playerlist.tacobot.json
}


function CommitAndPush() {
    if [ -f Group/OLD ]; then
        rm Group/OLD
    fi
    wget --quiet -O Group/OLD https://raw.githubusercontent.com/d3fc0n6/TacobotList/master/32ids
    NEW=$(wc -l <"OUT/32ids")
    OLD=$(wc -l <"Group/OLD")
    DIF=$((NEW - OLD))
    echo $OLD/$NEW
    echo $DIF
    cd ../TacobotList
    git add 32ids 64ids playerlist.tacobot.json
    git commit --quiet -m "Added $DIF entries. There are now $NEW entries"
    git push
}


# You come here often?
if [ ! -d Group/ ]; then
    echo $RD"Missing Group folder!, Creating.."$RE
    mkdir Group/
fi
if [ ! -d OUT/ ]; then
    echo $RD"Missing OUT folder!, Creating.."$RE
    mkdir OUT/
fi

getSteamIDs
Convert
CommitAndPush
