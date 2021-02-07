# coding: utf-8
"""Entry point to launch game."""

from black_white import *


def start_game():
    """Run game in portrait orientation."""
    run(Game(), PORTRAIT)


if __name__ == '__main__':
    start_game()
