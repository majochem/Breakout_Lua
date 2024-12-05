# Breakout Lua

**Breakout Lua** is a classic brick-breaking game inspired by Atari's *Breakout*. The player controls a paddle to bounce a ball and break bricks while preventing the ball from falling to the bottom. The game is being developed in Lua using the Love2D framework as a learning project. This project is very much still a Work in Progress. I do not recommend actually running the code on your system until I get a more stable version.

## Features
- **Scoring System**: Points are awarded based on the strength of the bricks.
- **Lives**: The player starts with 3 lives, losing one when the ball falls below the paddle.
- **Speed Dynamics**: The ball speeds up with every paddle hit but resets upon losing a life or completing a level.
- **Levels**:
  - Includes 5 pre-defined levels.
  - Planned feature: Auto-generated, increasingly difficult levels.
- **High Score Tracking**: Keeps a record of the highest score achieved in a session.

## Controls
- **Menu Navigation**: Use the arrow keys and Enter/Escape to navigate.
- **In-Game**:
  - Move paddle: Left/Right arrow keys.
  - Launch ball: Spacebar (if reset).
  - Pause: Escape key.
- **Debugging**: Some additional controls are implemented for development purposes.

## Requirements
- [Love2D](https://love2d.org/) must be installed to run the game.
- Additional dependencies: SQLite3 and lunajson.

## How to Play
1. Clone the repository:
   ```bash
   git clone https://github.com/username/Breakout-Lua.git
   cd Breakout-Lua

2. Run the game with Love2D: ```bash love . ```

## Technologies Used 
- **[Lua](https://www.lua.org/)**: The core programming language. 
- **[Love2D](https://love2d.org/)**: A 2D game framework. 
- **[SQLite3](https://www.sqlite.org/)**: For managing save data. 
- **[lunajson](https://github.com/grafi-tt/lunajson)**: To handle JSON-based high-score tracking.

### Dependencies

This repository includes the following third-party libraries:

- **SQLite3**: Used for managing save data.  
  Source: [SQLite](https://sqlite.org/)  
  License: [Public Domain](https://sqlite.org/copyright.html)

- **lunajson**: A lightweight JSON library for Lua.  
  Source: [GitHub](https://github.com/grafi-tt/lunajson)  
  License: MIT License  

These libraries are bundled in the repository for convenience. Their respective licenses allow redistribution and usage. Please refer to their documentation for more details.



## Development Goals 
This project aims to: 
- Build foundational programming skills. 
- Practice Lua scripting and Love2D game development. 
- Explore file handling with SQLite3 and JSON. 
- Gain hands-on experience with (very basic) custom physics and UI systems.

## Acknowledgments 
- **Background Music**: *Stereotypical 90s Space Shooter Music* by Jan125.     
Licensed under [CC0](https://creativecommons.org/publicdomain/zero/1.0/).     
Available at: [Open Game Art](https://opengameart.org/content/stereotypical-90s-space-shooter-music)

## License 
This project is released under the "Do What You Want" license. You are free to use, modify, and share my code (so, not the included libraries) without restrictions.

## Screenshots 
*(Coming Soon)*
