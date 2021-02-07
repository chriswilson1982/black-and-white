# coding: utf-8
"""Common global constants.

Constants that need to be accessed from other modules are initialised here.
Many are imported or adapted from the configuration file.
"""

from scene import *
from configuration import get_settings, get_layout, get_sounds, get_text
from math import pi


# Load Configuation
background_color, color3, color4, text_color, difficulty, username, first_time = get_settings()

# Color Setup
color1 = (0, 0, 0, 1)  # Black
color2 = (1, 1, 1, 1)  # White
color2_trans = (1, 1, 1, 0.8)
colors = (color1, color2)
all_colors = (color1, color2, color3, color4)

# Screen layout and size classes
rows = 10
cols = 6
screen_w, screen_h = min(get_screen_size()), max(get_screen_size())
centre = (screen_w / 2, screen_h / 2)

# Set size class
if screen_w >= 768:
    # Larger screens
    size_class = 1
    square_size = int(screen_w / 14)
elif screen_w >= 375:
    # Smaller screens
    size_class = 0
    square_size = int(screen_w / 8 - 4)

# Get variable values from config file
title_font_size, title_from_top, powerup_from_top, bottom_vertical, label_height, label_font_size, counter_font_size, score_label_font_size, score_label_gap, top_button_top_gap, top_button_side_gap, top_button_scale = get_layout(
    size_class)

# Values derived from above variables
title_position = (screen_w / 2, screen_h - title_from_top)
powerup_vertical = screen_h - powerup_from_top

# Top left is starting point for grid
top_left = (centre[0] - square_size * (cols / 2.0 - 0.5),
            (centre[1] + square_size * (rows / 2.0 - 0.5)))

# Sounds
tap_sound, button_sound, win_sound, fail_sound, no_white_sound, new_game_sound, flip_sound, reds_away, star_bonus_sound, star_sound, star_away_sound, neg_sound, timer_tick, powerup_sound = get_sounds()

# Actions
A = Action
pressed_action_1 = A.sequence(A.scale_to(0.7, 0.1), A.scale_to(1, 0.1))
pressed_action_2 = A.sequence(A.scale_to(0.9, 0.1), A.scale_to(1, 0.1))
pressed_action_3 = A.sequence(A.scale_to(0.5, 0.1), A.scale_to(0.7, 0.1))
toggle_action_1 = A.sequence(
    A.group(A.scale_to(0.7, 0.1), A.rotate_to(pi, 0.3)), A.scale_to(1.0, 0.1))
toggle_action_2 = A.sequence(
    A.group(A.scale_to(0.7, 0.1), A.rotate_to(0, 0.3)), A.scale_to(1.0, 0.1))
score_action_1 = A.sequence(A.group(A.move_by(
    0, centre[1] - 100, 1, TIMING_EASE_OUT_2), A.fade_to(1, 0.7)), A.wait(2), A.fade_to(0, 0.5), A.remove())
score_action_2 = A.sequence(A.group(A.move_by(
    0, centre[1] - 100, 1, TIMING_EASE_OUT_2), A.fade_to(0.7, 0.7)), A.wait(2), A.fade_to(0, 0.5), A.remove())

# Text Archive
win_text = list(get_text('WIN_TEXT'))
fail_text = list(get_text('FAIL_TEXT'))
zero_text = list(get_text('ZERO_TEXT'))
neg_text = list(get_text('NEG_TEXT'))
no_white_text = list(get_text('NO_WHITE_TEXT'))
reward_text = list(get_text('REWARD_TEXT'))
punishment_text = list(get_text('PUNISHMENT_TEXT'))
hurry_text = list(get_text('HURRY_TEXT'))
zero_fail_text = list(get_text('ZERO_FAIL_TEXT'))
neg_fail_text = list(get_text('NEG_FAIL_TEXT'))
quick_fail_text = list(get_text('QUICK_FAIL_TEXT'))

# Power-Ups
starting_powerups = 9 - difficulty * 3


def make_texture(icon_name='Cog', text_color=(0, 0, 0, 1)):
    """Return a texture in the appropriate black or white colour"""
    return Texture('typ{}:{}'.format('w' if text_color else 'b', icon_name))
