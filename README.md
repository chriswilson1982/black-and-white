# Black & White
## A colourful grid-based puzzle game for Pythonista on iOS by Chris Wilson

Black & White is a colourful grid-based puzzle game created using [Pythonista](http://omz-software.com/pythonista/) on iOS. This code is intended to be used within the Pythonista app.

<p align="center">
    <img src="https://www.chrisandkathy.co.uk/blackwhite/images/1.png" width="20%">
    &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
    <img src="https://www.chrisandkathy.co.uk/blackwhite/images/2.png" width="20%">
    &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
    <img src="https://www.chrisandkathy.co.uk/blackwhite/images/3.png" width="20%">
</p>

### Configuration

The *config.ini* file contains modifiable configuration information. There are currently settings for two size classes in the *[LAYOUT_SMALL]* and *[LAYOUT_LARGE]* sections. These may need to be adjused for different screen sizes. You can also customise in-game messages and other aspects of the game.

### Instructions

- The aim is to score points by clearing a white path across the black and white grid. Tapping a square locks it and toggles the colour of the eight surrounding squares. 

- When the path is cleared, tap the central button at the bottom of the screen. This happens automatically when the timer runs out.

- If successful, tapping the timer will proceed to the next level. Otherwise, tap it to start a new game. The timer gets quicker with each level!

- There are three power-ups at the top of the screen. You can get more by collecting stars. They can be very helpful, but not using them may have other advantages! The power-ups effects are as follows: 
    - Toggle all squares
    - Unlock a tapped square
    - Toggle a single square (but not its neighbours)

- Points are awarded for maximising the number of squares in the path, and points are deducted for unused white squares and locked squares (ones you have tapped). Your score in a round may end up negative!

### Settings

The cog icon in the top left will take you to the settings screen where you can select a difficulty level (which affects timer speed and power-ups), change the username and set a custom colour scheme. For more detailed instructions, you can view the in-game help screen by tapping the **?** button on the settings screen.

### Highscores

The high score leaderboard can be viewed by tapping the icon in the top right. There is a separate table for each difficulty setting. Scores are stored for each user name using a local SQLite database.

***

Black & White has also been published on the [App Store](https://geo.itunes.apple.com/gb/app/black-white-grid-based-puzzle/id1102097118?mt=8), using the [Pythonista XCode template](https://github.com/omz/PythonistaAppTemplate). As of 2021, it is proving very challenging to update so it has not had an update in a few years and will probably be removed from the App Store eventually. The [product website](https://www.chrisandkathy.co.uk/blackwhite/) includes further information and a global high score leaderboard.
