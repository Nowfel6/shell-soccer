#!/usr/bin/env bash
# Constants ========================================================================================

_title="ShellSoccer"
_ver="1.0"

# Command Substitution: Gets the name and folder path of this script automatically
_name=$(basename "$0")
_path=$(dirname "$0")

# Files for Sir's Conditions (Save/Resume & Leaderboard)
score_file="$_path/scores.ssc"
save_file="$_path/savegame.ssc"

# Game pieces (We make them 2 characters wide so they look square in the terminal)
p1_piece="P1"
p2_piece="P2"
ball="()"
wall="#"
goal="  "  # Empty space for the goal line

#Arena Size
arena_width=80
arena_height=20
goal_top=9
goal_bottom=14
# Game colors using an Associative Array
declare -A colors
colors[$p1_piece]="\e[1;36;40m"     # Bright cyan on black
colors[$p2_piece]="\e[1;35;40m"     # Bright magenta on black
colors[$ball]="\e[1;33;40m"         # Bright yellow on black
colors[$wall]="\e[1;91;40m"         # Bright Red on white background for the field walls
colors["intro"]="\e[1;32;40m"       # Bright green on black
colors["outro"]="\e[1;37;41m"       # Bright white on red

# Useful ANSI strings (Screen clearing, cursor hiding)
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

# 2. Function to draw the field instantly
draw_arena() {
   local i
   #Hide the blinking typing cursor
   printf "${curs_off}"
   printf "${clr_screen}"
  printf "${colors[$wall]}"
  for((i=1;i<=arena_width;i++));do
   printf "\e[1;${i}H${wall}"
   printf "\e[${arena_height};${i}H${wall}"
  done
for (( i=2; i<=arena_height; i++ )); do
        
        # If 'i' is outside the goal range, draw a wall. Otherwise, draw a space.
        if [[ $i -lt $goal_top || $i -gt $goal_bottom ]]; then
            # Draw solid wall
            printf "\e[${i};1H${wall}"                 # Left side
            printf "\e[${i};${arena_width}H${wall}"    # Right side
        else
            # Draw empty space (the goal!)
            printf "\e[${i};1H "                 
            printf "\e[${i};${arena_width}H "    
        fi
    done
    printf "$color_off"
}

# 1. Function to show the title screen
show_intro() {
    # First, draw the empty arena
    draw_arena
    local i row=5 col=20
    sleep .75
    #design
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
    
    # Move cursor to Row 12, Col 18 and print the prompt
    printf "\e[17;20H Press any key to start! "
    sleep 3    
    # Wait for the user to press exactly ONE key (no Enter needed)
    read -r -s -n 1 key
    
    # The moment they press a key, redraw the empty arena to "vanish" the text
    draw_arena
}

# 2. Call the intro function
show_intro

# ==========================================
# Game State Variables (Starting Positions)
# ==========================================
# Player 1 starts on the left side, centered vertically
p1_y=$(( arena_height / 2 ))
p1_x=5

# Player 2 starts on the right side, centered vertically
p2_y=$(( arena_height / 2 ))
p2_x=$(( arena_width - 5 )) # 5 spaces away from the right wall

# Ball starts exactly in the middle
ball_y=$(( arena_height / 2 ))
ball_x=$(( arena_width / 2 ))
ball_dx=1
ball_dy=1
#score tracking
p1_score=0
p2_score=0

# ==========================================
# Functions to Draw and Clear Entities
# ==========================================
# ==========================================
# Functions to Draw and Clear Entities
# ==========================================
draw_entities() {
    # Draw Player 1 (3 rows tall)
    printf "\e[$((p1_y-1));${p1_x}H${colors[$p1_piece]}||${color_off}" # Top
    printf "\e[${p1_y};${p1_x}H${colors[$p1_piece]}${p1_piece}${color_off}" # Middle
    printf "\e[$((p1_y+1));${p1_x}H${colors[$p1_piece]}||${color_off}" # Bottom
    
    # Draw Player 2 (3 rows tall)
    printf "\e[$((p2_y-1));${p2_x}H${colors[$p2_piece]}||${color_off}" # Top
    printf "\e[${p2_y};${p2_x}H${colors[$p2_piece]}${p2_piece}${color_off}" # Middle
    printf "\e[$((p2_y+1));${p2_x}H${colors[$p2_piece]}||${color_off}" # Bottom
    
    # Draw Ball
    printf "\e[${ball_y};${ball_x}H${colors[$ball]}${ball}${color_off}"
}

clear_entities() {
    # Clear Player 1 (3 rows)
    printf "\e[$((p1_y-1));${p1_x}H  "
    printf "\e[${p1_y};${p1_x}H  "
    printf "\e[$((p1_y+1));${p1_x}H  "

    # Clear Player 2 (3 rows)
    printf "\e[$((p2_y-1));${p2_x}H  "
    printf "\e[${p2_y};${p2_x}H  "
    printf "\e[$((p2_y+1));${p2_x}H  "

    # Clear Ball
    printf "\e[${ball_y};${ball_x}H  "
}
# ==========================================
# UI and Scoring Functions
# ==========================================
draw_score() {
    # Print the scoreboard perfectly centered on the top wall (Row 1, Col 30)
    printf "\e[1;83H\e[1;33;40m[ ${p1_piece}: ${p1_score} | ${p2_piece}: ${p2_score} ]${color_off}"
}

show_goal() {
    local scorer="$1"  # $1 grabs the first argument passed to the function
    
    # Hide the ball and players momentarily
    clear_entities
    
    # Draw a massive ASCII "GOAL!" in the center of the screen
    printf "\e[8;25H\e[1;32;40m   ____  ___    _    _      \e[0m"
    printf "\e[9;25H\e[1;32;40m  / ___|/ _ \  / \  | |     \e[0m"
    printf "\e[10;25H\e[1;32;40m | |  _| | | |/ _ \ | |     \e[0m"
    printf "\e[11;25H\e[1;32;40m | |_| | |_| / ___ \| |___  \e[0m"
    printf "\e[12;25H\e[1;32;40m  \____|\___/_/   \_\_____| \e[0m"
    
    # Announce who scored
    printf "\e[14;32H\e[1;37;41m  $scorer SCORED!  \e[0m"
    sleep 3    
     # Move cursor to Row 12, Col 18 and print the prompt
    printf "\e[17;20H Press any key to start! "
    
    # Wait for the user to press exactly ONE key (no Enter needed)
    read -r -s -n 1 key

    
    # Reset the ball to the exact center of the arena
    ball_y=$(( arena_height / 2 ))
    ball_x=$(( arena_width / 2 ))
    
    # Redraw the clean arena and the new score
    draw_arena
    draw_score
}
#draw score
draw_score

# 3. Call the draw function after the intro finishes to put them on the field!
draw_entities

# ==========================================
# Main Game Loop (Upgraded)
# ==========================================
game_loop() {
    while true; do
        # 1. This sleep controls the speed of the game (20 Frames Per Second)
        sleep 0.05
        
        # 2. Clear old positions before moving
        clear_entities

        # 3. DRAIN THE BUFFER: Read ALL keys pressed in the last 0.05 seconds
        while read -rsn1 -t 0.001 key; do
            case "$key" in
                # Player 1 Controls (Notice the - 1 and + 1 math!)
                w|W) [[ $((p1_y - 1)) -gt 2 ]] && ((p1_y--)) ;; 
                s|S) [[ $((p1_y + 1)) -lt $(($arena_height - 1)) ]] && ((p1_y++)) ;; 
                a|A) [[ $p1_x -gt 2 ]] && ((p1_x--)) ;; 
                d|D) [[ $p1_x -lt $((arena_width / 2 - 2)) ]] && ((p1_x++)) ;; 
                
                # Player 2 Controls
                i|I) [[ $((p2_y - 1)) -gt 2 ]] && ((p2_y--)) ;; 
                k|K) [[ $((p2_y + 1)) -lt $(($arena_height - 1)) ]] && ((p2_y++)) ;; 
                j|J) [[ $p2_x -gt $((arena_width / 2 + 1)) ]] && ((p2_x--)) ;; 
                l|L) [[ $p2_x -lt $((arena_width - 2)) ]] && ((p2_x++)) ;; 
                
                q|Q) break 2 ;;
            esac
        done
# --- BALL PHYSICS ---
        # 1. Move the ball automatically every frame
        ((ball_x += ball_dx))
        ((ball_y += ball_dy))

        # 2. Bounce off Top and Bottom Walls
        if [[ $ball_y -le 2 || $ball_y -ge $((arena_height - 1)) ]]; then
            ((ball_dy *= -1))       # Reverse Y direction
            ((ball_y += ball_dy))   # Nudge it out of the wall so it doesn't get stuck
        fi

        # 3. Check Left/Right Walls AND Goals
            if [[ $ball_x -le 2 ]]; then
                # Ball hit the Left side. Is it inside the goal range?
                if [[ $ball_y -ge $goal_top && $ball_y -le $goal_bottom ]]; then
                    ((p2_score++))         # Add 1 to Player 2's score
                    show_goal "PLAYER 2"   # Trigger the goal animation!
                else
                    ((ball_dx *= -1))      # Not a goal, just bounce off the wall
                    ((ball_x += ball_dx)) 
                fi
                
            elif [[ $ball_x -ge $((arena_width - 3)) ]]; then
                # Ball hit the Right side. Is it inside the goal range?
                if [[ $ball_y -ge $goal_top && $ball_y -le $goal_bottom ]]; then
                    ((p1_score++))         # Add 1 to Player 1's score
                    show_goal "PLAYER 1"   # Trigger the goal animation!
                else
                    ((ball_dx *= -1))      # Not a goal, just bounce off the wall
                    ((ball_x += ball_dx)) 
                fi
            fi

# 4. Bounce off Player 1 (Giant 3-row Hitbox!)
            if [[ $ball_y -ge $((p1_y - 1)) && $ball_y -le $((p1_y + 1)) && $ball_x -ge $p1_x && $ball_x -le $((p1_x + 1)) ]]; then
                ((ball_dx *= -1))
                ((ball_x += ball_dx)) 
            fi

            # 5. Bounce off Player 2
            if [[ $ball_y -ge $((p2_y - 1)) && $ball_y -le $((p2_y + 1)) && $ball_x -ge $p2_x && $ball_x -le $((p2_x + 1)) ]]; then
                ((ball_dx *= -1))
                ((ball_x += ball_dx)) 
            fi

        # 4. Draw characters at new positions
        draw_entities
    done
}
#call game-loop
game_loop
