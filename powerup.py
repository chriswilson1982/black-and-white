# coding: utf-8
"""Powerup module.

Represents the powerup items at the top of the screen.
"""

from scene import *
from common import *


# Path data
standard_size = (square_size + 12, 32)
max_size = (square_size + 16, 36)

pu_path = ui.Path().rounded_rect(0, 0, standard_size[0], standard_size[1], 6)
pu_path.fill()
pu_path.stroke()
pu_path.line_width = 1
pu_path.close()

pu_max = ui.Path().rounded_rect(0, 0, max_size[0], max_size[1], 8)
pu_max.stroke()
pu_max.line_width = 5
pu_max.close()


class Powerup (ShapeNode):
    """Represents the powerup items at the top of the screen.

    Maintains count of powerup and updates appearance on screen.
    They are initialised with a type (1 = flip all squares, 2 = unlock a square, 3 = flip a single square), initial count (from the starting_powerups constant) and a position.
    """

    def __init__(self, type, initial_count, position):
        super().__init__(pu_path, color=(1, 1, 1, 0.7), position=position,
                         size=standard_size, alpha=1, z_position=1)

        self.type = type
        self.max_count = 9
        self.position = position

        self.path = pu_path
        self.max_path = pu_max

        self.stroke_color = color1
        self.fill_color = color2_trans
        self.z_position = 1.0

        self._count = initial_count

        self.max_outline = ShapeNode(pu_max, color=(1, 1, 1, 0), position=(
            0, 0), size=max_size, alpha=0.8, z_position=0.6)

        self.max_outline.fill_color = (1, 1, 1, 0)
        self.max_outline.stroke_color = color4
        self.add_child(self.max_outline)

        texture = ['typb:Shuffle', 'typb:Cross', 'typb:Contrast'][type - 1]

        self.icon = SpriteNode(texture=Texture(
            texture), position=(-10, 0), scale=0.7)
        self.icon.z_position = 0.9
        self.add_child(self.icon)

        self.label = LabelNode(str(self.count), font=(
            'Helvetica', 20), color=color1, position=(14, 0))
        self.label.z_position = 0.9
        self.add_child(self.label)

    @property
    def count(self):
        """Powerup count property (get)"""
        return self._count

    @count.setter
    def count(self, value):
        """Powerup count property (set)"""
        if value < 0:
            self._count = 0
        elif value > 9:
            self._count = 9
        else:
            self._count = value
        self.label.text = str(self._count)
