# coding: utf-8
"""Square module.

Represents the squares on the game grid.
"""

from scene import *
from common import *
import sound

class Square (SpriteNode):
    """Represents the squares on the game grid.

    Main properties are their row and column (used for path calculation) and state (corresponds to color in the game).
    """

    def __init__(self, row, col, position, size, state, color):
        self.row = row
        self.col = col
        self.position = position
        self.size = size
        self.color = color
        self.z_position = 0.2
        self.state = state
        self.last_state = state
        self.press = False
        self.star = False
        if self.state == 1:
            self.color = color1
        if self.state == 2:
            self.color = color2

    def set_color(self):
        self.color = all_colors[self.state - 1]

    # Find neighbouring white squares
    def white_neighbours(self, square_list):
        white_neighbours = []
        for s in square_list:
            if (((s.row == self.row - 1) and (s.col == self.col)) or ((s.row == self.row + 1) and (s.col == self.col)) or ((s.row == self.row) and (s.col == self.col - 1)) or ((s.row == self.row) and (s.col == self.col + 1))) and s.state == 2:
                white_neighbours.append(s)
        return white_neighbours

    # Find squares to toggle when square pressed
    def toggle_neighbours(self, squares):
        for square in squares:
            if square.row >= self.row - 1 and square.row <= self.row + 1 and square.col >= self.col - 1 and square.col <= self.col + 1 and not (square.row == self.row and square.col == self.col) and (square.state == 1 or square.state == 2):
                square.toggle()

    # Square pressed
    def pressed(self):
        # If power-up 3 active
        if self.parent.can_flip:
            self.toggle()
            sound.play_effect(reds_away)
            return
        # State saved so power-up 2 can unlock
        self.last_state = self.state

        self.press = True
        self.z_position = 0.3
        self.run_action(pressed_action_1)
        self.state = 0
        self.color = color3

        # Bonus star destroyed if star square pressed
        if self.star:
            self.star = False
            self.parent.star_square = None
            self.star_icon.run_action(
                A.sequence(A.scale_to(0, 0.5), A.remove()))
            sound.play_effect(star_away_sound)
            self.parent.level_label.text = "Goodbye star!"
        else:
            sound.play_effect(tap_sound)

    # Square toggles between black and white
    def toggle(self):
        # Ignore if square already pressed
        if self.state == 0:
            return
        if self.rotation == 0:
            self.run_action(toggle_action_1)
        else:
            self.run_action(toggle_action_2)
        if self.state == 1:
            self.state = 2
            self.color = color2
        elif self.state == 2:
            self.state = 1
            self.color = color1
        if self.star:
            self.go_star()
        self.scene.sparkle(self.color, self.position, image='shp:RoundRect', spread=square_size, n=2)

    # Creates star icon if this square is the randomly selected star square
    def go_star(self):
        # Remove star icon first, if it exists
        try:
            self.star_icon.run_action(A.remove())
        except:
            pass
        self.star = True

        # Star icon depends on square color
        if self.state == 1:
            tex = Texture('typw:Star')
        elif self.state == 2:
            tex = Texture('typb:Star')
        self.star_icon = SpriteNode(
            texture=tex, position=self.position, size=(square_size - 5, square_size - 5))
        self.star_icon.z_position = 0.6
        self.parent.add_child(self.star_icon)
