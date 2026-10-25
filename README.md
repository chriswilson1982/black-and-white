# Black & White
## A colourful grid-based puzzle game for Pythonista on iOS by Chris Wilson

Black & White is a colourful grid-based puzzle game created using [Pythonista](http://omz-software.com/pythonista/) on iOS. This code is intended to be used within the Pythonista app.

***

<img src="https://user-images.githubusercontent.com/17131659/189770225-919836e7-4f4a-4c53-97ef-55518bcd731c.png" width="200" />

***

### Installation

Download or clone the repository to Pythonista's file system and run ```main.py``` using the Python 3 interpreter.

[Pythonista Tools Installer](https://github.com/ywangd/pythonista-tools-installer) provides an easy way to do this. *Black & White* is listed in the library under *Games*.

***

### Configuration

The *config.ini* file contains modifiable configuration information. There are currently settings for two size classes in the `[LAYOUT_SMALL]` and `[LAYOUT_LARGE]` sections. These may need to be adjused for different screen sizes. You can also customise in-game messages and other aspects of the game.

***

### Instructions

- The aim is to score points by clearing a white path across the black and white grid. Tapping a square locks it and toggles the colour of the eight surrounding squares. 

- When the path is cleared, tap the central button at the bottom of the screen. This happens automatically when the timer runs out.

- If successful, tapping the timer will proceed to the next level. Otherwise, tap it to start a new game. The timer gets quicker with each level!

- There are three power-ups at the top of the screen. You can get more by collecting stars. They can be very helpful, but not using them may have other advantages! The power-ups effects are as follows: 
    - Toggle all squares
    - Unlock a tapped square
    - Toggle a single square (but not its neighbours)

- Points are awarded for maximising the number of squares in the path, and points are deducted for unused white squares and locked squares (ones you have tapped). Your score in a round may end up negative!

***

### Settings

The cog icon in the top left will take you to the settings screen where you can select a difficulty level (which affects timer speed and power-ups), change the username and set a custom colour scheme. For more detailed instructions, you can view the in-game help screen by tapping the **?** button on the settings screen.

***

### Highscores

The high score leaderboard can be viewed by tapping the icon in the top right. There is a separate table for each difficulty setting. Scores are stored for each user name using a local SQLite database.
