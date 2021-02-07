# coding: utf-8
"""Start and finish element module.

Represents the start and finsh elements on the sides of the grid.
"""

from scene import *
from common import *


class StartFinish (SpriteNode):
    """Represents the start and finsh elements on the sides of the grid.

    These must align with a row in the grid. Positioning is managed by the Game class, which initialises this class with a row number.
    """

    def __init__(self, row, type):
        if type == "start":
            self.anchor_point = (0.9375, 0.5)
            self.position = (top_left[0] - square_size,
                             top_left[1] - square_size * (row - 1))
            self.color = color4
        elif type == "finish":
            self.anchor_point = (0.0625, 0.5)
            self.position = (top_left[0] + square_size *
                             cols, top_left[1] - square_size * (row - 1))
            self.color = color2
        self.size = (8 * square_size + 2, square_size)
        self.z_position = 0.45
        self.row = row
