#!/bin/zsh

fgRed=$(tput setaf 161) # cherry red
fgGreen=$(tput setaf 118) # green
fgYellow=$(tput setaf 226) # yellow
fgBlue=$(tput setaf 69) # blue
fgSky=$(tput setaf 51) #skyblue
fgCyan=$(tput setaf 6) # cyan
fgOrange=$(tput setaf 208) #orange
txReset=$(tput sgr0) #reset
domain=$1

function banner(){
	printf "\n${fgOrange}"
    printf "  ::::::::   ::::::::   ::::::::   ::::::::  :::::::::  :::   ::: \n"
    printf " :+:    :+: :+:    :+: :+:    :+: :+:    :+: :+:    :+: :+:   :+: \n" 
    printf " +:+        +:+        +:+    +:+ +:+    +:+ +:+    +:+  +:+ +:+  \n"
    printf " +#++:++#++ +#+        +#+    +:+ +#+    +:+ +#++:++#+    +#++:   \n"
    printf "        +#+ +#+        +#+    +#+ +#+    +#+ +#+    +#+    +#+    \n"
    printf " #+#    #+# #+#    #+# #+#    #+# #+#    #+# #+#    #+#    #+#    \n"
    printf "  ########   ########   ########   ########  #########     ###    \n"
	printf "                        by @v3l5${txReset}                        \n"
}

function check_for_help(){

    if [ $# -eq 0 ]
        then
            echo "\n${fgSky} Hey domain, Where are you ! ${fgGreen}Scooby needs one to start the mystery machine${txReset}"
            echo "\n${fgRed} Usage: puppy_power.sh greenvan.com${txReset}"
            exit 1
    fi
}

function prep(){

    #axiom-fleet scooby -i 20
    echo -n "\n${fgYellow}Subdomain Enumeration : Preparing${txReset} "
    local="/opt/recon/subdomain_enum/$domain/raw_output"
    results_local="/opt/recon/subdomain_enum/$domain/results"
    remote="/home/op/work/subdomain_enum/$domain"
    remote_amass="/home/op/work/amass"

    mkdir -p $local > /dev/null 2>&1
    mkdir -p $results_local > /dev/null 2>&1
    axiom-exec "mkdir -p $remote" > /dev/null 2>&1
    axiom-exec "mkdir -p $remote_amass" > /dev/null 2>&1
    axiom-scp "~/.config/amass/config.ini" "scooby*:$remote_amass/config.ini" > /dev/null 2>&1
    echo -n "${fgGreen} --> done" 
}

function active_amass(){

    echo -n "\n${fgYellow}Subdomain Enumeration : Selecting 1 axiom instance${txReset} "
    axiom-select scooby01 > /dev/null 2>&1
    echo -n "${fgGreen} --> done" 

    echo -n "\n${fgYellow}Subdomain Enumeration : Active recon${txReset} "
    axiom-exec "amass enum -active -d $domain -config ~/work/amass/config.ini -o $remote/subdomain_results.txt" > /dev/null 2>&1
    echo -n "${fgGreen} --> done" 

    echo -n "\n${fgYellow}Subdomain Enumeration : Fetching results${txReset} "
    axiom-scp scooby01:$remote/subdomain_results.txt "$local/subdomain_results.txt" > /dev/null 2>&1
    echo -n "${fgRed} --> Discovered $(wc -l <$local/subdomain_results.txt) subdomains"
    echo -n "${fgGreen} --> done" 
}

function recursive_enum(){

    echo -n "\n${fgYellow}Subdomain Enumeration : Selecting all available axiom instances${txReset} "
    axiom-select "scooby*" > /dev/null 2>&1
    echo -n "${fgGreen} --> done" 

    echo -n "\n${fgYellow}Subdomain Enumeration : Recursive scan - Iteration 1${txReset} "
    axiom-scan "$local/subdomain_results.txt" -m amass -passive -config $remote_amass/config.ini -o $local/recur1_amass.txt --quiet > /dev/null
    cat $local/recur1_amass.txt | anew $local/subdomain_results.txt > $local/recur1_passive.txt
    cat $local/recur1_passive.txt | httpx -random-agent -retries 2 -no-color -fc 500,501,502 -t 150 -silent -o $local/recur1_active.txt > /dev/null
    cat $local/recur1_active.txt | sed 's/https:\/\///g' | sed 's/http:\/\///g' > $local/recur1_active_final.txt

    echo -n "${fgRed} --> Discovered $(wc -l <$local/recur1_active_final.txt) new subdomains"
    echo -n "${fgGreen} --> done"

    if [ ! $(wc -l < $local/recur1_active_final.txt) -eq 0 ]
        then    
        echo -n "\n${fgYellow}Subdomain Enumeration : Recursive scan - Iteration 2${txReset} "
        axiom-scan "$local/recur1_active_final.txt" -m amass -passive -config $remote_amass/config.ini -o $local/recur2_amass.txt --quiet > /dev/null
        cat $local/recur2_amass.txt | anew $local/subdomain_results.txt > $local/recur2_active.txt
        echo -n "${fgRed} --> Discovered $(wc -l <$local/recur2_active.txt) new subdomains"
        echo -n "${fgGreen} --> done"
    fi

    # if [ ! $(wc -l < $local/recur2_active.txt) -eq 0 ]
    #     then 
    #     echo -n "\n${fgYellow}Subdomain Enumeration : Recursive scan - Iteration 3${txReset} "
    #     axiom-scan "$local/subdomain_results.txt" -m amass -active -o $local/recur1_amass.txt --quiet > /dev/null
    #     cat $local/recur3_amass.txt | anew $local/subdomain_results.txt > $local/recur3_active.txt
    #     echo -n "${fgRed} --> Discovered $(wc -l <$local/recur2_active.txt) new subdomains"
    #     echo -n "${fgGreen} --> done"
    # fi
}


function brute_generator(){

    rm -rf $local/brutelist_puredns.txt
    
    echo -n "\n${fgYellow}Subdomain Enumeration : Creating subdomains to bruteforce${txReset} "
    while read p; do
        echo "$p.$domain" >> $local/brutelist_puredns.txt
    done </opt/recon/lists/best-dns-wordlist.txt
    echo -n "${fgGreen} --> done" 
}

function resolve_brute_subdomains(){

    echo -n "\n${fgYellow}Subdomain Enumeration : Resolving subdomains (bruteforce)${txReset} "
    axiom-scan $local/brutelist_puredns.txt -m puredns-resolve "-t 800" --rate-limit-trusted 1000 --resolvers /home/op/lists/resolvers.txt -o $local/brute_resolved_sd.txt --quiet > /dev/null
    cat $local/brute_resolved_sd.txt | anew $local/subdomain_results.txt > $local/brute_resolved_new.txt
    echo -n "${fgRed} --> Discovered $(wc -l <$local/brute_resolved_new.txt) new subdomains"
    echo -n "${fgGreen} --> done" 
}

function permutation_subdomians(){

    echo -n "\n${fgYellow}Subdomain Enumeration : Permutating subdomains${txReset} "
    axiom-scan $local/subdomain_results.txt -m puredns-resolve "-t 800" --rate-limit-trusted 1000 --resolvers /home/op/lists/resolvers.txt -o $local/subdomain_perm_active.txt --quiet > /dev/null
    gotator -sub $local/subdomain_perm_active.txt -perm /opt/recon/lists/perm.txt -depth 1 -numbers 10 -mindup -adv -md -silent > $local/perm_gotator.txt
    axiom-scan $local/perm_gotator.txt -m puredns-resolve "-t 800" --rate-limit-trusted 1000 --resolvers /home/op/lists/resolvers.txt -o $local/perm_resolved_sd.txt --quiet > /dev/null
    cat $local/perm_resolved_sd.txt | anew $local/subdomain_results.txt > $local/perm_resolved_new.txt
    echo -n "${fgRed} --> Discovered $(wc -l <$local/perm_resolved_new.txt) new subdomains"
    echo -n "${fgGreen} --> done"
}

function scrape_js() {

    echo -n "\n${fgYellow}Subdomain Enumeration : Spidering subdomains${txReset} "
    axiom-scan $local/subdomain_results.txt -m httpx -random-agent -retries 2 -no-color -fc 500,501,502 -silent -o $local/probed_tmp_scrap.txt > /dev/null 2>&1
    axiom-scan $local/probed_tmp_scrap.txt -m gospider --js -t 50 -d 3 --sitemap --robots -w -r -o $local/gospider_results > /dev/null 2>&1
    echo -n "${fgGreen} --> done"

    echo -n "\n${fgYellow}Subdomain Enumeration : Scraping JS files${txReset} "
    cat $local/gospider_results/* | grep -Eo 'https?://[^ ]+' | sed 's/]$//' | unfurl -u domains | grep ".$domain$" | sort -u > $local/gospider_sd.txt
    cat $local/gospider_sd.txt | anew $local/subdomain_results.txt > $local/gospider_sd_new.txt
    echo -n "${fgRed} --> Discovered $(wc -l <$local/gospider_sd_new.txt) new subdomains"
    echo -n "${fgGreen} --> done"
}

function analystics_probing() {

    axiom-select scooby01 > /dev/null 2>&1
    echo -n "\n${fgYellow}Subdomain Enumeration : Checking google analytics${txReset} "
    analyticsrelationships --url https://www.$domain > $local/analytics_sd.txt
    cat $local/analytics_sd.txt | grep ".$domain$" | sed 's/|__ //g' | sed 's/\[-\] Analyzing url: https:\/\///g' > $local/analytics_sd_sorted.txt
    cat $local/analytics_sd_sorted.txt | anew $local/subdomain_results.txt > $local/analytics_sd_new.txt 2>&1
    echo -n "${fgRed} --> Discovered $(wc -l <$local/analytics_sd_new.txt) new subdomains"
    echo -n "${fgGreen} --> done"
}

function final_resolve() {
    
    axiom-select "scooby*" > /dev/null 2>&1

    echo -n "\n${fgYellow}Subdomain Enumeration : Resolving subdomains (final)${txReset} "
    axiom-scan $local/subdomain_results.txt -m puredns-resolve "-t 800" --rate-limit-trusted 1000 --resolvers /home/op/lists/resolvers.txt -o $results_local/subdomain_active.txt --quiet > /dev/null
    
    axiom-select scooby01 > /dev/null 2>&1

    axiom-scp $results_local/subdomain_active.txt scooby01:$remote/subdomain_active.txt > /dev/null 2>&1
    axiom-exec "massdns -q -r /home/op/lists/resolvers.txt -o S -t A -t CNAME -s 2000 --flush $remote/subdomain_active.txt -w $remote/resolved_records.txt" > /dev/null 2>&1
    axiom-scp scooby01:$remote/resolved_records.txt "$local/resolved_records.txt" > /dev/null 2>&1
    
    cat $local/resolved_records.txt | grep '. A ' | awk '{print $3}' | sort -u > $results_local/IP_records.txt
    cat $local/resolved_records.txt | grep '. CNAME ' | sort -u > $results_local/CNAME_records.txt
    echo -n "${fgGreen} --> done"
}

function subdomain_port_scanning() {

}

main() {   
    banner
    check_for_help $domain
    prep
    active_amass
    recursive_enum
    brute_generator
    resolve_brute_subdomains
    permutation_subdomians
    scrape_js
    analystics_probing
    final_resolve
}

main