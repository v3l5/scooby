# spinner()
# {
#     pid=$!
#     delay=0.1
#     declare -a spin=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
#     while [ "$(ps a | awk '{print $1}' | grep $pid)" ]
#     do
#         for i in "${spin[@]}"
#         do
#             echo -n "$i\b"
#             sleep $delay
#         done
#     done
#     echo -n "\b"
# }

#cat $local/recur1_active.txt | sed 's/https:\/\///g' | sed 's/http:\/\///g' > $local/recur1_active_final.txt

# function scrape_js() {

#     echo -n "\n${fgYellow}Subdomain Enumeration : Spidering subdomains${txReset} "
    
#     axiom-scan $local/subdomain_results.txt -m httpx -random-agent -retries 2 -no-color -fc 500,501,502 -silent -o $local/probed_tmp_scrap.txt > /dev/null 2>&1
    
#     axiom-scan $local/probed_tmp_scrap.txt -m gospider --js -t 50 -d 3 --sitemap --robots -w -r -o $local/gospider_results > /dev/null 2>&1
    
#     echo -n "${fgGreen} --> done"

#     echo -n "\n${fgYellow}Subdomain Enumeration : Scraping JS files${txReset} "
    
#     cat $local/gospider_results/* | grep -Eo 'https?://[^ ]+' | sed 's/]$//' | unfurl -u domains | grep ".$domain$" | sort -u > $local/gospider_sd.txt
#     cat $local/gospider_sd.txt | anew $local/subdomain_results.txt > $local/gospider_sd_new.txt
    
#     echo -n "${fgRed} --> Discovered $(wc -l <$local/gospider_sd_new.txt) new subdomains"
#     echo -n "${fgGreen} --> done"
# }

# function analystics_probing() {

#     axiom-select scooby01 > /dev/null 2>&1
    
#     echo -n "\n${fgYellow}Subdomain Enumeration : Checking google analytics${txReset} "
    
#     analyticsrelationships --url https://www.$domain > $local/analytics_sd.txt
    
#     cat $local/analytics_sd.txt | grep ".$domain$" | sed 's/|__ //g' | sed 's/\[-\] Analyzing url: https:\/\///g' > $local/analytics_sd_sorted.txt
#     cat $local/analytics_sd_sorted.txt | anew $local/subdomain_results.txt > $local/analytics_sd_new.txt 2>&1
    
#     echo -n "${fgRed} --> Discovered $(wc -l <$local/analytics_sd_new.txt) new subdomains"
#     echo -n "${fgGreen} --> done"
# }

#axiom-scan $local/subdomain_results.txt -m puredns-resolve "-t 800" --rate-limit-trusted 1000 --resolvers /home/op/lists/resolvers.txt -o $local/subdomain_perm_active.txt --quiet > /dev/null

# check other tool - try dnsx - dnsx is cool
# wildcard tests - fixed - -wd on dnsx solved
