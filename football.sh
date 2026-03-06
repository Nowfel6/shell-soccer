#!/usr/bin/env bash



_title="ShellSoccer"
_ver="1.0"

# Game name and directory path
_name=$(basename "$0")
_path=$(dirname "$0")

# Files needed for saving game and profiles 
score_file="$_path/scores.ssc"
save_file="$_path/savegame.ssc"
profiles_file="$_path/profiles.ssc"
# Game Pieces
p1_piece="P1"
p2_piece="P2"
ball="()"
wall="#"
goal="  " 

#Arena Size
arena_width=80
arena_height=20
goal_top=9
goal_bottom=14
#player position
p1_y=$(( arena_height / 2 ))
p1_x=5
p2_y=$(( arena_height / 2 ))
p2_x=$(( arena_width - 5 )) # 5 spaces away from the right wall
 
# Ball position
ball_y=$(( arena_height / 2 ))
ball_x=$(( arena_width / 2 ))
ball_dx=1
ball_dy=1
#score tracking
p1_score=0
p2_score=0

# Game colors using an Associative Array
declare -A colors
colors[$p1_piece]="\e[1;36;40m"     # Bright cyan on black
colors[$p2_piece]="\e[1;35;40m"     # Bright magenta on black
colors[$ball]="\e[1;33;40m"         # Bright yellow on black
colors[$wall]="\e[1;91;40m"         # Bright Red on white background for the field walls
colors["intro"]="\e[1;32;40m"       # Bright green on black
colors["outro"]="\e[1;37;41m"       # Bright white on red

# Useful ANSI strings
clr_screen="\e[2J\e[H"
clr_down="\e[J"
clr_eol="\e[0K"
clr_line="\e[2K"
color_off="\e[0m"
curs_off="\e[?25l"
curs_on="\e[?25h"
# 1. Store the entire UI in a variable using a Heredoc
IFS= read -r -d '' ARENA_UI <<EOF 
#################################################################################
#                                                                               #
#                                                                               #
#                                                                               #
#                                                                               #
#                                                                               #
#                                                                               #
#                                                                               #
                                                                                 
                                                                                 
                                                                                 
                                                                                 
                                                                                 
                                                                                 
#                                                                               #
#                                                                               #
#                                                                               #
#                                                                               #
#                                                                               #
#################################################################################
EOF
# save the last postion of cursor before entering the game and remove echo 
old_stty=$(stty -g)
stty -echo
#on exit 
on_exit()
{
stty "$old_stty"
printf '\e[?25h\e[2J\e[H'
}
#trap signal
trap "on_exit" EXIT
# Initialization 
init_game() {
    #check terminal size 
    read -r tty_rows tty_cols <<< "$(stty size)"
    
    if [[ $tty_rows -lt 24 || $tty_cols -lt 110 ]]; then
        printf "\e[1;31mError: Your terminal is too small to play ShellSoccer!\e[0m\n"
        printf "Please resize your window to at least \e[1;33m110x24\e[0m.\n"
        printf "Your current size is: ${tty_cols}x${tty_rows}\n"
        exit 1
    fi

    # Ensure files are present or not
    if [[ ! -f "$profiles_file" ]]; then
        touch "$profiles_file"
    fi
}

draw_arena() {
   local i
   printf "${curs_off}"
   printf "${clr_screen}"
  printf "${colors[$wall]}"
  for((i=1;i<=arena_width;i++));do
   printf "\e[1;${i}H${wall}"
   printf "\e[${arena_height};${i}H${wall}"
  done
for (( i=2; i<=arena_height; i++ )); do
        if [[ $i -lt $goal_top || $i -gt $goal_bottom ]]; then
            printf "\e[${i};1H${wall}"                 
            printf "\e[${i};${arena_width}H${wall}"    
        else
            printf "\e[${i};1H "                 
            printf "\e[${i};${arena_width}H "    
        fi
    done
    printf "$color_off"
}
show_intro() {
    draw_arena
    local i row=5 col=20
    sleep .75
    declare -a text=(
		' ___  _  _  ___  _    _    '
		'/ __|| || || __|| |  | |   '
		'\__ \| __ || _| | |__| |__ '
		'|___/|_||_||___||____|____|'
		'!'
		' ___  ___   ___  ___  ___  ___ '
		'/ __|/ _ \ / __|/ __|| __|| _ \'
		'\__ \ (_) | (__| (__ | _| |   /'
		'|___/\___/ \___|\___||___||_|_\'
		'!' '!' )
    printf "${colors["intro"]}"
    for i in "${text[@]}";do
       if [[ "$i" != "!" ]]; then
          printf "\e[${row};${col}H"
          printf '%s' "$i"
          ((row++))
       else 
          sleep .75
       fi
     done

    printf "$color_off"
    printf "\e[17;20H Press any key to start! "
    sleep 3    
    read -r -s -n 1 key
    draw_arena
}
draw_entities() {
    printf "\e[$((p1_y-1));${p1_x}H${colors[$p1_piece]}||${color_off}" 
    printf "\e[${p1_y};${p1_x}H${colors[$p1_piece]}${p1_piece}${color_off}"
    printf "\e[$((p1_y+1));${p1_x}H${colors[$p1_piece]}||${color_off}"
    
   
    printf "\e[$((p2_y-1));${p2_x}H${colors[$p2_piece]}||${color_off}"
    printf "\e[${p2_y};${p2_x}H${colors[$p2_piece]}${p2_piece}${color_off}" 
    printf "\e[$((p2_y+1));${p2_x}H${colors[$p2_piece]}||${color_off}" 
    
    # Draw Ball
    printf "\e[${ball_y};${ball_x}H${colors[$ball]}${ball}${color_off}"
}

clear_entities() {
    printf "\e[$((p1_y-1));${p1_x}H  "
    printf "\e[${p1_y};${p1_x}H  "
    printf "\e[$((p1_y+1));${p1_x}H  "

    
    printf "\e[$((p2_y-1));${p2_x}H  "
    printf "\e[${p2_y};${p2_x}H  "
    printf "\e[$((p2_y+1));${p2_x}H  "

    # Clear Ball
    printf "\e[${ball_y};${ball_x}H  "
}

draw_side_panel() {
    local sp_start=82
    local sp_end=106
    
    for (( i=sp_start; i<=sp_end; i++ )); do
        printf "\e[1;${i}H${colors[$wall]}=${color_off}"
        printf "\e[${arena_height};${i}H${colors[$wall]}=${color_off}"
    done
    
    
    for (( i=1; i<=arena_height; i++ )); do
        printf "\e[${i};${sp_start}H${colors[$wall]}|${color_off}"
        printf "\e[${i};${sp_end}H${colors[$wall]}|${color_off}"
    done


    printf "\e[3;85H\e[1;33m   SCOREBOARD   \e[0m"
    # The %-10s means "Cut the name if it is longer than 10 letters so it fits!"
    printf "\e[5;85H\e[1;36m%-10s: %2d\e[0m" "${p1_name:0:10}" "$p1_score"
    printf "\e[6;85H\e[1;35m%-10s: %2d\e[0m" "${p2_name:0:10}" "$p2_score"
    
    printf "\e[9;85H\e[1;33m    CONTROLS    \e[0m"
    printf "\e[11;85H P1: W,A,S,D"
    printf "\e[12;85H P2: I,J,K,L"
    
    printf "\e[15;85H\e[1;32m [P] Pause/Save \e[0m"
    printf "\e[16;85H\e[1;31m [Q] Quit Match \e[0m"
}

show_goal() {
    local scorer="$1"  
    
    clear_entities
    

    printf "\e[8;25H\e[1;32;40m   ____  ___    _    _      \e[0m"
    printf "\e[9;25H\e[1;32;40m  / ___|/ _ \  / \  | |     \e[0m"
    printf "\e[10;25H\e[1;32;40m | |  _| | | |/ _ \ | |     \e[0m"
    printf "\e[11;25H\e[1;32;40m | |_| | |_| / ___ \| |___  \e[0m"
    printf "\e[12;25H\e[1;32;40m  \____|\___/_/   \_\_____| \e[0m"
    
    printf "\e[14;32H\e[1;37;41m  $scorer SCORED!  \e[0m"
    sleep 3    
    printf "\e[17;20H Press any key to start! "
    

    read -r -s -n 1 key

    
    #reset the ball
    ball_y=$(( arena_height / 2 ))
    ball_x=$(( arena_width / 2 ))
    

    draw_arena
    draw_side_panel
}

reset_positions() {
    p1_y=$(( arena_height / 2 )); p1_x=5
    p2_y=$(( arena_height / 2 )); p2_x=$(( arena_width - 5 ))
    ball_y=$(( arena_height / 2 )); ball_x=$(( arena_width / 2 ))
    ball_dx=1; ball_dy=1
}

save_game() {
    # file manipulation
    echo "p1_name=\"$p1_name\"" > "$save_file"
    echo "p2_name=\"$p2_name\"" >> "$save_file"
    echo "p1_score=$p1_score" >> "$save_file"
    echo "p2_score=$p2_score" >> "$save_file"
    echo "p1_y=$p1_y" >> "$save_file"; echo "p1_x=$p1_x" >> "$save_file"
    echo "p2_y=$p2_y" >> "$save_file"; echo "p2_x=$p2_x" >> "$save_file"
    echo "ball_y=$ball_y" >> "$save_file"; echo "ball_x=$ball_x" >> "$save_file"
    echo "ball_dx=$ball_dx" >> "$save_file"; echo "ball_dy=$ball_dy" >> "$save_file"
}
record_match() {
    if [[ "$p1_name" == "$p2_name" ]]; then return; fi

    local p1_db p2_db
    local p1_pass p1_w p1_l p1_d
    local p2_pass p2_w p2_l p2_d

    # 1. Extract their current stats from the database
    p1_db=$(grep "^${p1_name}," "$profiles_file")
    p2_db=$(grep "^${p2_name}," "$profiles_file")

    # 2. Split the text into variables
    p1_pass=$(echo "$p1_db" | cut -d',' -f2); p1_w=$(echo "$p1_db" | cut -d',' -f3); p1_w=${p1_w:-0}
    p1_l=$(echo "$p1_db" | cut -d',' -f4); p1_l=${p1_l:-0}; p1_d=$(echo "$p1_db" | cut -d',' -f5); p1_d=${p1_d:-0}
    
    p2_pass=$(echo "$p2_db" | cut -d',' -f2); p2_w=$(echo "$p2_db" | cut -d',' -f3); p2_w=${p2_w:-0}
    p2_l=$(echo "$p2_db" | cut -d',' -f4); p2_l=${p2_l:-0}; p2_d=$(echo "$p2_db" | cut -d',' -f5); p2_d=${p2_d:-0}

    # 3. Determine who wins
    if [[ $p1_score -gt $p2_score ]]; then
        ((p1_w++)); ((p2_l++))   
    elif [[ $p2_score -gt $p1_score ]]; then
        ((p2_w++)); ((p1_l++))   
    else
        ((p1_d++)); ((p2_d++))   
    fi

    # 4. Remove the old rows from profiles
    grep -v -e "^${p1_name}," -e "^${p2_name}," "$profiles_file" > "$_path/tmp.ssc"
    mv "$_path/tmp.ssc" "$profiles_file"

    # 5. Append  updated rows
    echo "${p1_name},${p1_pass},${p1_w},${p1_l},${p1_d}" >> "$profiles_file"
    echo "${p2_name},${p2_pass},${p2_w},${p2_l},${p2_d}" >> "$profiles_file"


    printf "\e[10;30H\e[1;37;44m  MATCH RESULTS RECORDED!  \e[0m"
    sleep 2
}

game_loop() {
    while true; do
        
        sleep 0.05
        
        
        clear_entities

       
        while read -rsn1 -t 0.001 key; do
            case "$key" in
                #player 1
                w|W) [[ $((p1_y - 1)) -gt 2 ]] && ((p1_y--)) ;; 
                s|S) [[ $((p1_y + 1)) -lt $(($arena_height - 1)) ]] && ((p1_y++)) ;; 
                a|A) [[ $p1_x -gt 2 ]] && ((p1_x--)) ;; 
                d|D) [[ $p1_x -lt $((arena_width / 2 - 2)) ]] && ((p1_x++)) ;; 
                
                # Player 2 
                i|I) [[ $((p2_y - 1)) -gt 2 ]] && ((p2_y--)) ;; 
                k|K) [[ $((p2_y + 1)) -lt $(($arena_height - 1)) ]] && ((p2_y++)) ;; 
                j|J) [[ $p2_x -gt $((arena_width / 2 + 1)) ]] && ((p2_x--)) ;; 
                l|L) [[ $p2_x -lt $((arena_width - 2)) ]] && ((p2_x++)) ;; 
                p|P)
                    save_game
                    break 2
                    ;;               
                q|Q)
                    clear_entities
                    record_match 
                    rm -f "$save_file"
                    break 2 ;;
            esac
        done
# BALL
        
        ((ball_x += ball_dx))
        ((ball_y += ball_dy))

        # Bounce off 
        if [[ $ball_y -le 2 || $ball_y -ge $((arena_height - 1)) ]]; then
            ((ball_dy *= -1))       
            ((ball_y += ball_dy))   
        fi

        # 3. Check Goal
            if [[ $ball_x -le 2 ]]; then
               
                if [[ $ball_y -ge $goal_top && $ball_y -le $goal_bottom ]]; then
                    ((p2_score++))         
                    show_goal "PLAYER 2"   
                else
                    ((ball_dx *= -1))      
                    ((ball_x += ball_dx)) 
                fi
                
            elif [[ $ball_x -ge $((arena_width - 3)) ]]; then
                
                if [[ $ball_y -ge $goal_top && $ball_y -le $goal_bottom ]]; then
                    ((p1_score++))         
                    show_goal "PLAYER 1"   
                else
                    ((ball_dx *= -1))      
                    ((ball_x += ball_dx)) 
                fi
            fi

            # Bounce off from player 1
            if [[ $ball_y -ge $((p1_y - 1)) && $ball_y -le $((p1_y + 1)) && $ball_x -ge $p1_x && $ball_x -le $((p1_x + 1)) ]]; then
                ((ball_dx *= -1))
                ((ball_x += ball_dx)) 
            fi

            #  Bounce off Player 2
            if [[ $ball_y -ge $((p2_y - 1)) && $ball_y -le $((p2_y + 1)) && $ball_x -ge $p2_x && $ball_x -le $((p2_x + 1)) ]]; then
                ((ball_dx *= -1))
                ((ball_x += ball_dx)) 
            fi

       
        draw_entities
    done
}


authenticate_player() {
    local player_num="$1"   
    local user pass db_pass

    while true; do
        printf "\e[5;30H\e[1;32m=== PLAYER $player_num LOGIN ===\e[0m"
        
        printf "${curs_on}"; stty echo
        printf "\e[8;30H Enter Username: "
        read user
        
        # Blank not allowed
        if [[ -z "$user" ]]; then continue; fi

        # check user exist or not
        if grep -q "^${user}," "$profiles_file" 2>/dev/null; then
            
            printf "\e[10;30H Welcome back! Enter Password: "
            stty -echo; read pass; stty echo  
            
            # Extract the actual password from the database to compare
            db_pass=$(grep "^${user}," "$profiles_file" | cut -d',' -f2)
            
            if [[ "$pass" == "$db_pass" ]]; then
                printf "\e[12;30H\e[1;32m Login Successful!\e[0m"
                sleep 1
                break
            else
                printf "\e[12;30H\e[1;31m Wrong Password! Try again.\e[0m"
                sleep 2
            fi
        else
            # New User
            printf "\e[10;30H New Player! Create a Password: "
            stty -echo; read pass; stty echo
            
            # Save them to the profiles
            echo "${user},${pass},0,0,0" >> "$profiles_file"
            printf "\e[12;30H\e[1;32m Registered & Logged In!\e[0m"
            sleep 1
            break
        fi
    done
    
    # Turn off the typing cursor agian
    printf "${curs_off}"; stty -echo
    
    # Assign player 1 and 2
    if [[ "$player_num" == "1" ]]; then
        p1_name="$user"
    else
        p2_name="$user"
    fi
}

start_new_game() {
    printf "${clr_screen}"
    draw_arena
    authenticate_player 1
    printf "${clr_screen}"
    draw_arena
    authenticate_player 2   
    # Set scores 
    p1_score=0; p2_score=0
    reset_positions
    
    draw_arena
    draw_side_panel
    game_loop
}

show_leaderboard() {
    printf "${clr_screen}"
    draw_arena
    printf "\e[3;20H\e[1;33m================================================\e[0m"
    printf "\e[4;20H\e[1;33m           GLOBAL LEADERBOARD                   \e[0m"
    printf "\e[5;20H\e[1;33m================================================\e[0m"
    
    # Table Header
    printf "\e[7;20H\e[1;37m %-15s | %-6s | %-6s | %-6s \e[0m" "USERNAME" "WINS" "LOSSES" "DRAWS"
    printf "\e[8;20H------------------------------------------------"
    
    local row=10
    
    if [[ -f "$profiles_file" ]]; then
        # sort command 
        sort -t',' -k3,3nr "$profiles_file" | head -n 10 | while IFS=',' read -r u p w l d; do
            # Provide defaults value
            w=${w:-0}; l=${l:-0}; d=${d:-0}
            printf "\e[${row};20H\e[1;36m %-15s \e[1;37m| \e[1;32m%-6s \e[1;37m| \e[1;31m%-6s \e[1;37m| \e[1;33m%-6s \e[0m" "${u:0:15}" "$w" "$l" "$d"
            ((row++))
        done
    else
        printf "\e[12;30H\e[1;31m No players registered yet! \e[0m"
    fi
    
    printf "\e[18;20H\e[1;32m Press M  to return to Main Menu... \e"
    read -rsn1 key
}

main_menu() {
    while true; do
        printf "${clr_screen}"
        draw_arena
        printf "\e[5;30H\e[1;33m==========================\e[0m"
        printf "\e[6;30H\e[1;33m       SHELL SOCCER       \e[0m"
        printf "\e[7;30H\e[1;33m==========================\e[0m"
        
        printf "\e[10;32H 1. New Game "
        printf "\e[12;32H 2. Resume Paused Game "
        printf "\e[14;32H 3. Leaderboard "
        printf "\e[16;32H 4. Quit App "
        
        printf "\e[19;30H Select an option (1-4): "
        
        
        read -rsn1 choice
        case "$choice" in
            1) 
                start_new_game 
                ;;
            2) 
                
              
                if [[ -f "$save_file" ]]; then
                    # source executes the code in the save file
                    source "$save_file"   
                    draw_arena
                    draw_side_panel
                    game_loop
                else
                    printf "\e[12;55H\e[1;31mNo saved game found!\e[0m"
                    sleep 2
                fi
                ;;
            3)
                
                show_leaderboard
                sleep 2
                ;;
            4)
                # Quit 
                break 
                ;;
        esac
    done
}
init_game
show_intro
main_menu
