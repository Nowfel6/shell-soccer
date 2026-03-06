# ⚽ ShellSoccer

![Bash](https://img.shields.io/badge/Language-Bash-4EAA25?style=flat-square&logo=gnu-bash&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Linux%20%2F%20macOS-000000?style=flat-square&logo=linux&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-blue?style=flat-square)

**ShellSoccer** is a feature-rich, local multiplayer arcade game running entirely in your terminal. It features a custom physics engine, user authentication, and persistent stat tracking without any external dependencies.

---

## 📸 Screenshots

<!-- Upload images to your repository and link them here -->
![Main Menu](https://via.placeholder.com/800x400?text=ShellSoccer+Main+Menu+Screenshot)

---

## ✨ Features

*   **🎮 Local Multiplayer:** Simultaneous 1v1 gameplay on a single keyboard with zero input lag using buffer draining techniques.
*   **👤 User System:** Full registration and login system with password protection.
*   **📊 Persistent Stats:** Tracks **Wins**, **Losses**, and **Draws** for every registered profile in a local database.
*   **🏆 Global Leaderboard:** Dynamic top-10 ranking system based on player wins using Linux sort utilities.
*   **💾 State Management:** Pause and Resume functionality that saves the exact game state (ball position, velocity, scores) to disk.

---

## 🚀 Installation

### Prerequisites
*   Linux, macOS, or WSL (Windows Subsystem for Linux).
*   **Terminal Size:** Your terminal window must be at least **110 columns x 24 rows**. The game includes an auto-check on startup.

### Steps

1.  **Clone the repository**
    ```bash
    git clone https://github.com/YOUR_USERNAME/ShellSoccer.git
    cd ShellSoccer
    ```

2.  **Make the script executable**
    ```bash
    chmod +x football.sh
    ```

3.  **Run the game**
    ```bash
    ./football.sh
    ```

---

## 🕹️ Controls

| Action | Player 1 (Cyan) | Player 2 (Magenta) |
| :--- | :---: | :---: |
| **Move Up** | `W` | `I` |
| **Move Down** | `S` | `K` |
| **Move Left** | `A` | `J` |
| **Move Right**| `D` | `L` |

### System Controls
*   **`P`** : **Pause & Save** (Returns to Main Menu, allowing you to Resume later).
*   **`Q`** : **Forfeit Match** (Records stats, deletes save file, and returns to Main Menu).

---

## 📂 File Structure

The game generates local files to manage state and user data. **Do not delete these manually** if you want to keep your save data.

*   `football.sh` - The main game executable.
*   `profiles.ssc` - Database storing user credentials and match stats (CSV format).
*   `savegame.ssc` - Temporary state file created when a match is paused; automatically deleted upon match completion.

---

## 🧠 Technical Highlights

This project demonstrates advanced Bash scripting concepts:
*   **ANSI Escape Codes (`\e[Y;XH`)**: Used for drawing the UI and entities without screen flickering.
*   **Input Handling**: Uses `read -t 0.001` inside a `while` loop to process simultaneous keystrokes.
*   **File Manipulation**: Uses `grep`, `cut`, and `sort` to manage the database and leaderboard.
*   **State Persistence**: Uses `source` to load variables dynamically from a save file.

---

## 🤝 Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## 📄 License

[MIT](https://choosealicense.com/licenses/mit/)
