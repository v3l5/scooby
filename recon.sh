#!/bin/zsh

fgRed=$(tput setaf 161) # cherry red
fgGreen=$(tput setaf 118) # green
fgYellow=$(tput setaf 226) # yellow
fgBlue=$(tput setaf 75) # blue
fgSky=$(tput setaf 51) #skyblue
fgCyan=$(tput setaf 6) # cyan
fgOrange=$(tput setaf 208) #orange
txReset=$(tput sgr0) #reset
domain=$1

function banner(){
	printf "\n"
    printf " ${fgGreen}"
    printf " ::::::::   ::::::::   ::::::::   ::::::::  :::::::::  :::   ::: \n"
    printf " ${fgRed}"
    printf ":+:    :+: :+:    :+: :+:    :+: :+:    :+: :+:    :+: :+:   :+: \n" 
    printf " ${fgOrange}"
    printf "+:+        +:+        +:+    +:+ +:+    +:+ +:+    +:+  +:+ +:+  \n"
    printf " ${fgYellow}"
    printf "+#++:++#++ +#+        +#+    +:+ +#+    +:+ +#++:++#+    +#++:   \n"
    printf " ${fgSky}"
    printf "       +#+ +#+        +#+    +#+ +#+    +#+ +#+    +#+    +#+    \n"
    printf " ${fgBlue}"
    printf "#+#    #+# #+#    #+# #+#    #+# #+#    #+# #+#    #+#    #+#    \n"
    printf " ${fgGreen}"
    printf " ########   ########   ########   ########  #########     ###    \n"
	printf "                           ${fgYellow}by @v3l5${txReset}         \n"
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

    echo -n "\n${fgYellow}Subdomain Enumeration : Preparing${txReset} "
    
    local="/opt/recon/subdomain_enum/$domain/raw_output"
    results_local="/opt/recon/subdomain_enum/$domain/results"
    remote="/home/op/work/subdomain_enum/$domain"
    remote_amass="/home/op/work/amass"
    lists="/opt/recon/lists"
   
    cd $resolvers && git checkout &> /dev/null
    mkdir -p $local &> /dev/null
    mkdir -p $results_local &> /dev/null
    axiom-exec "mkdir -p $remote" &> /dev/null
    axiom-exec "mkdir -p $remote_amass" &> /dev/null
    axiom-scp "~/.config/amass/config.ini" "scooby*:$remote_amass/config.ini" &> /dev/null
    
    echo -n "${fgGreen} --> done" 
}

function active_amass(){

    echo -n "\n${fgYellow}Subdomain Enumeration : Selecting 1 axiom instance${txReset} "
    axiom-select scooby01 &> /dev/null
    echo -n "${fgGreen} --> done" 

    echo -n "\n${fgYellow}Subdomain Enumeration : Active recon${txReset} "
    
    axiom-exec "amass enum -active -d $domain -config ~/work/amass/config.ini -o $remote/subdomain_results.txt" &> /dev/null
    
    echo -n "${fgGreen} --> done" 

    echo -n "\n${fgYellow}Subdomain Enumeration : Fetching results${txReset} "
    
    axiom-scp scooby01:$remote/subdomain_results.txt "$local/subdomain_results.txt" &> /dev/null
    
    echo -n "${fgRed} --> Discovered $(wc -l <$local/subdomain_results.txt) subdomains"
    echo -n "${fgGreen} --> done" 
}

function recursive_enum(){

    echo -n "\n${fgYellow}Subdomain Enumeration : Selecting all available axiom instances${txReset} "
    axiom-select "scooby*" &> /dev/null
    echo -n "${fgGreen} --> done" 

    echo -n "\n${fgYellow}Subdomain Enumeration : Recursive scan - Iteration 1${txReset} "
    
    axiom-scan "$local/subdomain_results.txt" -m amass -passive -config $remote_amass/config.ini -o $local/recur1_amass.txt --quiet &> /dev/null
    
    cat $local/recur1_amass.txt | anew $local/subdomain_results.txt > $local/recur1_passive.txt
    
    axiom-scan $local/recur1_passive.txt -m dnsx -o $local/recur1_active.txt --quiet &> /dev/null

    echo -n "${fgRed} --> Discovered $(wc -l <$local/recur1_active.txt) new subdomains"
    echo -n "${fgGreen} --> done"

    if [ ! $(wc -l < $local/recur1_active.txt) -eq 0 ]
        then    
        echo -n "\n${fgYellow}Subdomain Enumeration : Recursive scan - Iteration 2${txReset} "
        
        axiom-scan "$local/recur1_active.txt" -m amass -passive -config $remote_amass/config.ini -o $local/recur2_amass.txt --quiet > /dev/null

        cat $local/recur2_amass.txt | anew $local/subdomain_results.txt > $local/recur2_passive.txt

        axiom-scan $local/recur2_passive.txt -m dnsx -o $local/recur2_active.txt --quiet &> /dev/null

        cat $local/recur2_active.txt | anew $local/subdomain_results.txt > $local/recur2_active_final.txt
             
        echo -n "${fgRed} --> Discovered $(wc -l <$local/recur2_active_final.txt) new subdomains"
        echo -n "${fgGreen} --> done"
    fi
}


function brute_generator(){

    rm -rf $local/brutelist_puredns.txt
    
    echo -n "\n${fgYellow}Subdomain Enumeration : Creating subdomains to bruteforce${txReset} "
    
    while read p; do
        echo "$p.$domain" >> $local/brutelist_puredns.txt
    done </opt/recon/lists/2m-sd.txt
    
    echo -n "${fgGreen} --> done" 
}

function resolve_brute_subdomains(){

    echo -n "\n${fgYellow}Subdomain Enumeration : Resolving subdomains (bruteforce)${txReset} "

    axiom-scan $local/brutelist_puredns.txt -m dnsx-wc $domain -o $local/brute_wc_removed_sd.txt &> /dev/null
    
    cat $local/brute_wc_removed_sd.txt | anew $local/subdomain_results.txt > $local/brute_resolved_new.txt

    rm -rf $local/brutelist_puredns.txt
    
    echo -n "${fgRed} --> Discovered $(wc -l <$local/brute_resolved_new.txt) new subdomains"
    echo -n "${fgGreen} --> done" 
}

function permutation_subdomians(){

    echo -n "\n${fgYellow}Subdomain Enumeration : Permutating subdomains${txReset} "
    
    axiom-scan $local/subdomain_results.txt -m dnsx-wc $domain -o $local/subdomain_perm_active.txt &> /dev/null

    cat $local/subdomain_perm_active.txt | sort -uf > $local/subdomain_perm_active_sorted.txt

    if [ $(wc -l < $local/subdomain_perm_active_sorted.txt) -lt 100 ]
    
    then
        gotator -sub $local/subdomain_perm_active_sorted.txt -perm /opt/recon/lists/perm.txt -depth 1 -numbers 10 -mindup -adv -md -silent > $local/perm_gotator.txt
        
        axiom-scan $local/perm_gotator.txt -m dnsx-wc $domain -o $local/perm_resolved_sd.txt &> /dev/null
        
        cat $local/perm_resolved_sd.txt | anew $local/subdomain_results.txt > $local/perm_resolved_new.txt
        
        echo -n "${fgRed} --> Discovered $(wc -l < $local/perm_resolved_new.txt) new subdomains"
        echo -n "${fgGreen} --> done"

    else
        echo -n "${fgRed} --> Found more than 100 new subdomains - Skipping"
        echo -n "${fgGreen} --> skipped"
    fi

    }

function final_resolve() {
    
    axiom-select "scooby*" > /dev/null 2>&1

    echo -n "\n${fgYellow}Subdomain Enumeration : Resolving subdomains (final)${txReset} "

    cat $local/subdomain_results.txt | sort -uf > $local/subdomain_final_sorted.txt
    
    axiom-scan $local/subdomain_final_sorted.txt -m dnsx -o $results_local/subdomain_active.txt &> /dev/null

    axiom-scan $results_local/subdomain_active.txt -m dnsx -cname -resp -o $results_local/subdomain_cname.txt &> /dev/null
  
    echo -n "${fgRed} --> Discovered a total of $(wc -l <$results_local/subdomain_active.txt) new subdomains"
    echo -n "${fgGreen} --> done"
}

function subdomain_takeover() {

    nuclei -l $results_local/subdomain_active.txt -t ~/nuclei-templates/takeovers -silent -o $results_local/possible_takeovers

}

function transfer_files() {

cp -r /opt/recon/subdomain_enum/$domain/ /media/vels/WD_BLACK/BB/$domain
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
    final_resolve
    subdomain_takeover
    transfer_files
}

main