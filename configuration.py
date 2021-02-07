# coding: utf-8
"""Load and save settings and configuration.

Theae function load and save user-modifiable and configuration settings.
Configuration file: config/config.ini
"""

from ast import literal_eval
import configparser


def load_config():
    """Return configuration parser for other functions."""
    parser = configparser.ConfigParser()
    parser.read('config/config.ini')
    return parser


def get_settings():
    """Return settings from configuration file as a tuple."""
    parser = load_config()
    settings = parser['SETTINGS']
    # ast.literal_eval returns a tuple from the string
    background_color = literal_eval(settings['background_color'])
    color3 = literal_eval(settings['color3'])
    color4 = literal_eval(settings['color4'])
    text_color = int(settings['text_color'])
    difficulty = int(settings['difficulty'])
    username = settings['username']
    first_time = settings.getboolean('first_time')

    return (background_color, color3, color4, text_color, difficulty, username, first_time)


def save_settings(settings_tuple):
    """Save modified settings to configuation file"""
    background_color = settings_tuple[0]
    color3 = settings_tuple[1]
    color4 = settings_tuple[2]
    text_color = settings_tuple[3]
    difficulty = settings_tuple[4]
    username = settings_tuple[5]
    first_time = settings_tuple[6]

    parser = load_config()
    settings = parser['SETTINGS']

    settings['background_color'] = str(background_color)
    settings['color3'] = str(color3)
    settings['color4'] = str(color4)
    settings['text_color'] = str(text_color)
    settings['difficulty'] = str(difficulty)
    settings['username'] = username
    settings['first_time'] = str(first_time)

    with open('config/config.ini', 'w') as file:
        parser.write(file)


def get_layout(size_class):
    """Return layout data from configuration file as a tuple"""
    parser = load_config()
    section = ('LAYOUT_SMALL', 'LAYOUT_LARGE')[size_class]
    return (literal_eval(value) for (option, value) in parser.items(section))


def get_sounds():
    """Return sound names from configuration file as a tuple"""
    parser = load_config()
    section = 'SOUNDS'
    return (value for (option, value) in parser.items(section))


def get_text(section):
    """Return text choices from configuration file as a tuple"""
    parser = load_config()
    return (value for (option, value) in parser.items(section))
