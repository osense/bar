#!/usr/bin/bash

# Run it as:
# example.sh | lemonbar -fMonospace:size=10 -fFontAwesome:size=12 eDP1 | zsh
#
# Requires: termite, nmtui, alsautils, mailcheck, font awesome

PAD="  "
BAT_BIAS=3 # My battery often decides to stop charging at what is reported as 97-99%
IW="wlp2s0"

Clock() {
    DATE=$(date "+%{T2}\uf017%{T1}  %a %b %d  %H:%M")
    echo -ne "$DATE"
}

Battery() {
    BAT=$(cat /sys/class/power_supply/BAT0/capacity)
    BAT=$(((BAT + BAT_BIAS) >= 100 ? 100 : BAT))
    case $BAT in
        8* | 9* | 100)  echo -ne '%{T2}\uf240%{T1}';;
        6* | 7*)        echo -ne '%{T2}\uf241%{T1}';;
        4* | 5*)        echo -ne '%{T2}\uf242%{T1}';;
        1* | 2* | 3*)   echo -ne '%{T2}\uf243%{T1}';;
        *)              echo -ne '%{T2}\uf244%{T1}';;
    esac
    echo -n " $BAT %"
}

Wifi() {
    WIFI_SSID=$(iw $IW link | grep 'SSID' | sed 's/SSID: //' | sed 's/\t//')
    #WIFI_SIGNAL=$(iw $IW link | grep 'signal' | sed 's/signal: //' | sed 's/ dBm//' | sed 's/\t//')
    echo -ne '%{A:termite -e nmtui:}%{T2}\uf1eb%{T1}' $WIFI_SSID '%{A}'
}

Sound() {
    STATUS=$(amixer get Master | grep 'Left: Playback' | grep -o '\[on]')
    VOLUME=$(amixer get Master | grep 'Left: Playback' | grep -o '...%' | sed 's/\[//' | sed 's/%//' | sed 's/ //')
    if [ "$STATUS" = "[on]" ] && [ $VOLUME -gt 0 ]; then
        echo -ne '%{T2}\uf028%{T1}' $VOLUME%
    else
        echo -ne '%{T2}\uf026%{T1}' "off"
    fi
}

Backlight() {
    STATUS=$(xbacklight | awk '{print int($1+0.5)}')
    echo -ne '%{T2}\uf185%{T1}' $STATUS%
}

Weather() {
    URL='http://www.accuweather.com/en/cz/brno/123291/weather-forecast/123291'
    WEATHER=$(wget -q -O- "$URL" | awk -F\' '/acm_RecentLocationsCarousel\.push/{print $2 " "  $14", "$12"°" }'| head -1)
    NIGHT=$(echo $WEATHER | cut -d " " -f1)
    WEATHER=$(echo $WEATHER | cut -d " " -f1 --complement)
    shopt -s nocasematch
    case $WEATHER in
        *fog*) echo -ne '%{T2}\uf070%{T1}';;
        *storm*) echo -ne '%{T2}\uf0e7%{T1}';;
        *rain*) echo -ne '%{T2}\uf043%{T1}';;
        *cloud*) echo -ne '%{T2}\uf0c2%{T1}';;
        *snow*) echo -ne '%{T2}\uf069%{T1}';;
        *sun* | *clear*)
            if [ "$NIGHT" == "night" ]; then
                echo -ne '%{T2}\uf186%{T1}'
            else
                echo -ne '%{T2}\uf185%{T1}'
            fi;;
    esac
    echo -n " $WEATHER"
}

Mail() {
    MAIL=$(mailcheck -c)
    if [ "$MAIL" != "" ]; then
        MAILS=$(echo $MAIL | cut -d " " -f 3)
        echo -ne "%{T2}\uf0e0%{T1} $MAILS new"
    fi
}


c=0
while true; do
    if [ $((c % 10)) -eq 0 ]; then clock="$(Clock)"; fi
    if [ $((c % 15)) -eq 0 ]; then wifi="$(Wifi)"; fi
    if [ $((c % 60)) -eq 0 ]; then battery="$(Battery)"; fi
    if [ $((c % 60)) -eq 0 ]; then mail="$(Mail)"; fi
    if [ $((c % 900)) -eq 10 ]; then weather="$(Weather)"; fi
    echo -n "%{l}"$PAD" $clock "$PAD" $weather %{r}$mail "$PAD" $(Sound) "$PAD" $wifi "$PAD" $battery "$PAD""
    echo -e "%{A2:poweroff:}%{A3:reboot:} "$PAD" %{T2}\uf011%{T1} "$PAD" %{A}%{A}"
    c=$((c+1));
    sleep 1;
done
