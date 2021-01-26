# coding: utf-8

from black_white import *

Game.can_play = False

# Start button (starts game from launch screen)
def start(sender):
	def fade():
		v.alpha = 0.01
	def next():
		v.close()
		v.wait_modal()
		start_game.present('full_screen', hide_title_bar = True, animated = False)
	button1.tint_color = color4
	sound.play_effect(button_sound)
	sound.play_effect(star_bonus_sound)
	ui.animate(fade, duration = 0.8)
	ui.delay(next, 0.8)

# Load launch screen
def launch_screen():
	global username
	def start(sender):
		def fade():
			v.alpha = 0.01
		def next():
			v.close()
			v.wait_modal()
			start_game.present('full_screen', hide_title_bar = True, animated = False)
		button1.tint_color = color4
		sound.play_effect(star_bonus_sound)
		ui.animate(fade, duration = 0.8)
		ui.delay(next, 0.8)
	v = ui.load_view("bw_launch.pyui")
	v.background_color = background_color
	v.present('full_screen', hide_title_bar = True, animated = False)
	button1 = v["button1"]
	button1.alpha = 1
	button1.tint_color = text_color
	button1.image = ui.Image.named('typw:Check')
	label1 = v["label1"]
	label2 = v["label2"]
	label3 = v["label3"]
	label1.text_color = text_color
	label2.text_color = not text_color
	label3.text_color = text_color
	circle = v["imageview2"]

# Define game view so it can be loaded
start_game = ui.View()
scene_view = SceneView(frame = start_game.bounds, flex='WH')
start_game.add_subview(scene_view)
scene_view.scene = Game()

#Functions for showing instructions on first startup only
#@ui.in_background
def close(sender):
	sound.play_effect(button_sound)
	view2.close()
	view2.wait_modal()
	launch_screen()

def review(sender): # Review button not displayed on first startup so tap function not needed
	pass

if first_time:
	view2 = ui.load_view("info")
	view2.present('full_screen', hide_title_bar = True, animated = False)
	close_button = view2["close_button"]
	review_button = view2["review_button"]
	review_button.y = -100 # Review button not displayed on first startup
	webview = view2["webview"]
	webview.load_html("<html><head><body><br><br><br><br><h1 align=\"center\" style=\"font-family:Helvetica; font-size:60px\">Loading...</h1></body></head></html>")
	try:
		webview.load_url("http://www.chrisandkathy.co.uk/blackwhite/info.html")
	except:
		webview.load_html("<html><head><body><br><br><br><br><h1 align=\"center\" style=\"font-family:Helvetica; font-size:60px\">Network Error</h1><p align=\"center\" style=\"font-family:Helvetica; font-size:20px\">Tap \'Close' to continue</p></body></head></html>")
else:
	launch_screen()
