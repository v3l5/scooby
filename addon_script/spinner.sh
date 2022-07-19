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