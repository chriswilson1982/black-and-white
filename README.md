# Black & White
## A grid-based game for Pythonista on iOS

Author: Chris Wilson (chriswilson1982)

Contributors: cclauss, omz

Last updated: 16 March 2016

***

## About the game

Black & White is a grid-based game created using [Pythonista](http://omz-software.com/pythonista/) on iOS. This code is intended to be used within the Pythonista app.

It has also been published on the [App Store](https://geo.itunes.apple.com/gb/app/black-white-grid-based-puzzle/id1102097118?mt=8), using the [Pythonista XCode template](https://github.com/omz/PythonistaAppTemplate).

## Instructions

The goal is to score points by clearing a white path across the black and white grid. Tapping a square locks it and toggles the eight surrounding squares. 

When you are ready, press the central button at the bottom of the screen. This will happen automatically if the timer expires, as shown by the circle at the bottom.

If successful, tapping the timer will proceed to the next level. Otherwise, tap it to start a new game. The timer gets quicker with each level! Tapping the exit icon at the top right will exit the game.

### Power-Ups

There are three power-ups at the top of the screen. You can get more by collecting stars. They can be very helpful, but not using them may have other advantages! The power-ups are ae shown below:

1. Toggle all squares
2. Unlock a tapped square
3. Toggle a single square (but not its neighbours)

### Scoring

Points are awarded for maximising the number of squares in the path, and points are deducted for unused white squares and locked squares (ones you have tapped). It's possible to lose points in a given round, but you might need to in order to progress!

### Settings

The cog icon in the top left will take you to the settings screen where you can select a difficulty level (which affects time and power-ups) and set a custom color scheme.

### Highscores

The highscore table can be viewed by tapping the icon in the bottom right. There is a separate table for each difficulty setting.
