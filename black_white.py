# coding: utf-8

#---Black & White: A Game by Chris Wilson

from scene import *
from math import pi
from random import choice, randint, randrange, random, uniform
from time import sleep, time
from datetime import date
import dialogs, mysqldb, pickle, sound, ui, webbrowser

#---Load Configuation
first_time = False
try:
	with open("bwconfig.dat", "rb") as in_file:
		data = pickle.load(in_file)
	background_color, color3, color4, difficulty, text_color, username = data
except:
	with open("bwconfig_default.dat", "rb") as default_file:
		data = pickle.load(default_file)
	background_color, color3, color4, difficulty, text_color, username = data
	first_time = True

#---Load Data & Color Setup
color1 = "#000000"
color2 = "#ffffff"
background_color, color3, color4, difficulty, text_color, username = data
colors = (color1, color2)
all_colors = (color1, color2, color3, color4)

#---Screen Size Setup and size classes
rows = 10
cols = 6
screen_w, screen_h = min(get_screen_size()), max(get_screen_size())

if screen_w >= 768:
	size_class = 0 # iPad
	centre = (screen_w / 2.0, screen_h / 2.0)
	square_size = int(screen_w / 14)
	title_font_size = 72
	title_position = (screen_w / 2, screen_h - 60)
	powerup_vertical = screen_h - 120
	bottom_vertical = 64
	label_height = 120
	label_font_size = 32
	counter_font_size = 36
	score_label_font_size = 60
	score_label_gap = 60
	set_high_pos = 40

elif screen_w >= 375:
	size_class = 1 # iPhone 6/6s/6 Plus/6s Plus
	centre = (screen_w / 2.0, screen_h / 2.0)
	square_size = int(screen_w / 8 - 4)
	title_font_size = 46
	title_position = (screen_w / 2, screen_h - 32)
	powerup_vertical = screen_h - 80
	bottom_vertical = 40
	label_height = 88
	label_font_size = 20
	counter_font_size = 30
	score_label_font_size = 40
	score_label_gap = 50
	set_high_pos = 20

elif screen_h >= 568:
	size_class = 2 # iPhone 5/5s
	centre = (screen_w / 2.0, screen_h / 2.0)
	square_size = int(screen_w / 8 - 6)
	title_font_size = 36
	title_position = (screen_w / 2, screen_h - 26)
	powerup_vertical = screen_h - 70
	bottom_vertical = 36
	label_height = 82
	label_font_size = 16
	counter_font_size = 22
	score_label_font_size = 36
	score_label_gap = 40
	set_high_pos = 20

elif screen_h >= 480:
	size_class = 3 # iPhone 4S)
	centre = (screen_w / 2.0, screen_h / 2.0 + 20)
	square_size = int(screen_w / 8 - 8)
	title_font_size = 26
	title_position = (screen_w / 2, screen_h + 100) # Off screen due to space constraints
	powerup_vertical = screen_h - 24
	bottom_vertical = 30
	label_height = 70
	label_font_size = 16
	counter_font_size = 22
	score_label_font_size = 34
	score_label_gap = 34
	set_high_pos = 20

top_left = (centre[0] - square_size * (cols / 2.0 - 0.5), (centre[1] + square_size * (rows / 2.0 - 0.5)))

#---Sounds
tap_sound = 'digital:PhaseJump1'
button_sound = 'ui:click1'
win_sound = 'digital:PowerUp1'
fail_sound = 'digital:ZapThreeToneDown'
no_white_sound = 'digital:PowerUp11'
new_game_sound = 'digital:PowerUp5'
flip_sound = 'digital:PowerUp4'
reds_away = 'digital:ThreeTone1'
star_bonus_sound = 'digital:PowerUp3'
star_sound = 'digital:PhaserUp7'
star_away_sound = 'digital:PhaserDown3'
neg_sound = 'digital:PhaserDown3'
timer_tick = 'digital:Tone1'
powerup_sound = 'digital:PowerUp7'

#---Actions
A = Action
pressed_action_1 = A.sequence(A.scale_to(0.7, 0.1), A.scale_to(1, 0.1))
pressed_action_2 = A.sequence(A.scale_by(-0.3, 0.1), A.scale_by(0.3, 0.1))
toggle_action_1 = A.sequence(A.group(A.scale_to(0.7, 0.1), A.rotate_to(pi, 0.3)), A.scale_to(1.0, 0.1))
toggle_action_2 = A.sequence(A.group(A.scale_to(0.7, 0.1), A.rotate_to(0, 0.3)), A.scale_to(1.0, 0.1))
score_action_1 = A.sequence(A.group(A.move_by(0, centre[1] - 100, 1, TIMING_EASE_OUT_2), A.fade_to(1, 0.7)), A.wait(2), A.fade_to(0, 0.5), A.remove())
score_action_2 = A.sequence(A.group(A.move_by(0, centre[1] - 100, 1, TIMING_EASE_OUT_2), A.fade_to(0.7, 0.7)), A.wait(2), A.fade_to(0, 0.5), A.remove())

#---Text Archive
win_text = [
"Well done!",
"Nice one!",
"Keep going!",
"Excellent!",
"More points!",
"Ready for another?",
"Good work!",
"Congratulations!",
"Good!"
]
fail_text = [
"Poor show!",
"Failure!",
"Rubbish!",
"Not so good!",
"All things come to an end!",
"Better luck next time!",
"Try again!",
"Unlucky or unskilled?",
"Game over!",
"Embarrassing!"
]
zero_text = [
"Pointless!",
"Zero score!",
"Sweet nothing!",
"Exactly zero? Wow!",
"Big fat nothing!",
"Zero!",
]
neg_text = [
"You lost points!",
"You're going backwards!",
"A higher score is better!",
"Going down?",
"That's not sustainable!"
]
no_white_text = [
"White square bonus!"
]
reward_text = [
"Power-up bonus!",
]
punishment_text = [
"Time for a tiny grid!",
"Small and tricky!",
"Time for 4x4 action!",
"Small but beautiful"
]
hurry_text = [
"Hurry up!",
"The clock is ticking!",
"There's not much time!",
"Don't panic!"
]

#---Power-Ups
starting_powerups = 9 - difficulty * 3

# Texture function
def make_texture(icon_name='Cog'):
	return Texture('typ{}:{}'.format('w' if text_color else 'b', icon_name))

# MySQL functions for global high score table
def add_global_score(score):
	score = int(score)
	if score <= 0:
		return # Only records or compares positive scores!
	diff = difficulty # Assigned at start as it's possible to change difficulty setting while waiting on SQL otherwise (which would enable cheating)!
	d = str(date.today()) # Get today's date (stored in database with scores but not accessible to players)
	try: # Connect to MySQL database (user has restricted access)
		db = mysqldb.connect(host= "mysql.chrisandkathy.co.uk", user = "anonanonanon", passwd="u9ippZja", db="bw_scores", port = 3306)
		c = db.cursor()
	except:
		return # Abandon attempt if cannot connect to MySQL database
	# Get personal and global highscores to compare
	compare_score = {'global' : 0, 'personal' : 0}
	user = "\"" + username + "\"" # Add quotes required by SQL syntax
	try:
		c.execute("SELECT score FROM bw_scores_" + str(diff) + " WHERE name = " + user + " ORDER BY score DESC LIMIT 1")
		compare_score['personal'] = c.fetchall()[0][0]
	except:
		compare_score['personal'] = -1
	try:
		c.execute("SELECT score FROM bw_scores_" + str(diff) + " ORDER BY score DESC LIMIT 1")
		compare_score['global'] = c.fetchall()[0][0]
	except:
		compare_score['global'] = -1
	# Insert score into correct difficulty table
	c.execute("INSERT INTO bw_scores_" + str(diff) + " (score, name, date) VALUES (%s, %s, %s)", (score, username, d))
	db.commit()
	db.disconnect()
	# Check if highscore notification needed
	if score > compare_score['global'] and compare_score['global'] != -1 and username != "Unknown":
		try:
			sound.play_effect(star_bonus_sound)
			dialogs.alert("New Global High Score", "Well done " + username + "!\n\nThe top score is now " + str(score), "OK", hide_cancel_button = True)
		except KeyboardInterrupt:
			pass
	elif score > compare_score['personal'] and compare_score['personal'] != -1 and username != "Unknown":
		try:
			sound.play_effect(star_bonus_sound)
			dialogs.alert("New Personal High Score", "Well done " + username + "!\n\nYour best score is now " + str(score), "OK", hide_cancel_button = True)
		except KeyboardInterrupt:
			pass

def get_global_scores():
	try:
		db = mysqldb.connect(host= "mysql.chrisandkathy.co.uk", user = "anonanonanon", passwd="u9ippZja", db="bw_scores", port = 3306)
		c = db.cursor()
	
		if difficulty == 1:
			c.execute("SELECT bw.* FROM bw_scores_1 bw INNER JOIN (SELECT name, MAX(score) AS MaxScore FROM bw_scores_1 GROUP BY name) groupedbw ON bw.name = groupedbw.name AND bw.score = groupedbw.MaxScore GROUP BY NAME ORDER BY score DESC")
		elif difficulty == 2:
			c.execute("SELECT bw.* FROM bw_scores_2 bw INNER JOIN (SELECT name, MAX(score) AS MaxScore FROM bw_scores_2 GROUP BY name) groupedbw ON bw.name = groupedbw.name AND bw.score = groupedbw.MaxScore GROUP BY NAME ORDER BY score DESC")
		elif difficulty == 3:
			c.execute("SELECT bw.* FROM bw_scores_3 bw INNER JOIN (SELECT name, MAX(score) AS MaxScore FROM bw_scores_3 GROUP BY name) groupedbw ON bw.name = groupedbw.name AND bw.score = groupedbw.MaxScore GROUP BY NAME ORDER BY score DESC")
		return c.fetchall()
		db.disconnect()
	except:
		return None


#---Class: Game
class Game (Scene):
	
	def setup(self):
		# Background color
		self.background_color = background_color

		self.alpha = 0
		self.run_action(A.fade_to(1, 0.2))
		
		#---Setup: Background of random squares
		bg = ui.Path().rounded_rect(0, 0, square_size, square_size, 4)
		bg.fill()
		bg.close()
		self.bg_list = []
		for x in range(randrange(20, 100)):
			self.random_bg = ShapeNode(bg, color = choice(all_colors), position = (randint(0, screen_w), randint(0, screen_h)), size = (square_size, square_size))
			self.random_bg.alpha = 0.05 * randrange(1, 9)
			self.random_bg.speed = randrange(1,6)
			self.random_bg.z_position = 0.2
			self.add_child(self.random_bg)
			self.bg_list.append(self.random_bg)
		
		#---Setup: Title, score, labels and icons

		# Title
		self.title = LabelNode("black   white", font = ('Helvetica Neue', title_font_size), color = text_color, position = title_position)
		self.title.z_position = 1.0
		self.add_child(self.title)

		self.title2 = LabelNode("&", font = ('Helvetica-bold', title_font_size), color = text_color, position = title_position)
		self.title2.z_position = 1.0
		self.add_child(self.title2)
		
		# Settings Button
		self.settings = SpriteNode(make_texture('Cog'), position = (set_high_pos, screen_h - set_high_pos), scale = 0.6)
		if size_class == 0:
			self.settings.scale = 1
		self.settings.z_position = 0.9
		self.add_child(self.settings)

		# Highscore Button
		self.highscore_button = SpriteNode(make_texture('Group'), position = (screen_w - set_high_pos, screen_h - set_high_pos), scale = 0.6)
		if size_class == 0:
			self.highscore_button.scale = 1
		self.highscore_button.z_position = 0.9
		self.add_child(self.highscore_button)

		# Exit Button (not used in iOS version)
		self.exit_icon = SpriteNode(make_texture('Cross'), position = (screen_w - set_high_pos, screen_h - set_high_pos))
		self.exit_icon.alpha = 0
		self.exit_icon.color = text_color
		self.exit_icon.z_position = 0.9
		self.add_child(self.exit_icon)
		
		# Level and message text and background
		self.level_bg = SpriteNode(color = background_color, position = (screen_w / 2, label_height), size = (screen_w, 26), alpha = 0.7)
		self.level_bg.z_position = 0.8
		self.add_child(self.level_bg)
		
		# Set starting level
		self.level = 0
		
		self.level_label = LabelNode("Level 1", font = ('Helvetica-bold', 20), color = text_color, position = (screen_w / 2, label_height))
		self.level_label.z_position = 0.9
		self.add_child(self.level_label)
		
		#---Setup: Power-Ups
		pu = ui.Path().rounded_rect(0, 0, 50, 28, 4)
		pu.fill()
		pu.stroke()
		pu.line_width = 1
		pu.close()
		
		pu_max = ui.Path().rounded_rect(0, 0, 52, 30, 4)
		pu_max.stroke()
		pu_max.line_width = 8
		pu_max.close()
		
		# Power-Up 1
		self.powerup1_bg = ShapeNode(pu, color = color2, position = (screen_w / 2 - square_size * 2, powerup_vertical), size = (square_size, 28))
		self.powerup1_bg.stroke_color = color1
		self.powerup1_bg.alpha = 0.9
		self.powerup1_bg.z_position = 0.8
		self.add_child(self.powerup1_bg)
		
		self.p_max_1 = ShapeNode(pu_max, color = (1,1,1,0), position = self.powerup1_bg.position, size = (54, 32), alpha = 0, z_position = 0.79)
		self.p_max_1.stroke_color = color4
		self.add_child(self.p_max_1)
		
		self.powerup1 = SpriteNode(texture = Texture('typb:Shuffle'), position = (self.powerup1_bg.position - (10, 0)), scale = 0.8)
		self.powerup1.z_position = 0.9
		self.add_child(self.powerup1)
		
		self.p1_count = LabelNode(str(starting_powerups), font = ('Helvetica', 20), color = "black", position = self.powerup1.position + (24, 0))
		self.p1_count.z_position = 0.9
		self.add_child(self.p1_count)
		
		self.p1 = (self.powerup1_bg, self.powerup1, self.p1_count, self.p_max_1)
		
		# Power-Up 2
		self.powerup2_bg = ShapeNode(pu, color = color2, position = self.powerup1_bg.position + (square_size * 2, 0), size = (square_size, 28))
		self.powerup2_bg.stroke_color = color1
		self.powerup2_bg.alpha = 0.9
		self.powerup2_bg.z_position = 0.8
		self.add_child(self.powerup2_bg)
		
		self.p_max_2 = ShapeNode(pu_max, color = (1,1,1,0), position = self.powerup2_bg.position, size = (54, 32), alpha = 0, z_position = 0.79)
		self.p_max_2.stroke_color = color4
		self.add_child(self.p_max_2)
		
		self.powerup2 = SpriteNode(texture = Texture('typb:Cross'), position = (self.powerup2_bg.position - (10, 0)), scale = 0.7)
		self.powerup2.z_position = 0.9
		self.add_child(self.powerup2)
		
		self.p2_count = LabelNode(str(starting_powerups), font = ('Helvetica', 20), color = "black", position = self.powerup2.position + (24, 0))
		self.p2_count.z_position = 0.9
		self.add_child(self.p2_count)
		
		self.p2 = (self.powerup2_bg, self.powerup2, self.p2_count, self.p_max_2)
		
		# Power-Up 3
		self.powerup3_bg = ShapeNode(pu, color = color2, position = self.powerup1_bg.position + (square_size * 4, 0), size = (square_size, 28))
		self.powerup3_bg.stroke_color = color1
		self.powerup3_bg.alpha = 0.9
		self.powerup3_bg.z_position = 0.8
		self.add_child(self.powerup3_bg)
		
		self.p_max_3 = ShapeNode(pu_max, color = (1,1,1,0), position = self.powerup3_bg.position, size = (54, 32), alpha = 0, z_position = 0.79)
		self.p_max_3.stroke_color = color4
		self.add_child(self.p_max_3)
		
		self.powerup3 = SpriteNode(texture = Texture('typb:Contrast'), position = (self.powerup3_bg.position - (10, 0)), scale = 0.7)
		self.powerup3.z_position = 0.9
		self.add_child(self.powerup3)
		
		self.p3_count = LabelNode(str(starting_powerups), font = ('Helvetica', 20), color = "black", position = self.powerup3.position + (24, 0))
		self.p3_count.z_position = 0.9
		self.add_child(self.p3_count)
		
		self.p3 = (self.powerup3_bg, self.powerup3, self.p3_count, self.p_max_3)
		
		#---Setup: Square Counters
		self.black_count = LabelNode("0", font = ('Helvetica', counter_font_size), color = color2, position = (-100, -100), z_position = 0.55)
		self.add_child(self.black_count)
		
		self.white_count = LabelNode("0", font = ('Helvetica', counter_font_size), color = color1, position = (-100, -100), z_position = 0.55)
		self.add_child(self.white_count)
		
		# Empty list of squares in the grid
		self.squares = []
		
		#---Setup: Start and End Points
		self.start = StartFinish(row = randint(1, rows), type = "start")
		self.add_child(self.start)

		self.finish = StartFinish(row = randint(1, rows), type = "finish")
		self.add_child(self.finish)
		
		self.backdrop3a = SpriteNode(position = self.start.position, size = (8 * square_size, square_size + 10), color = text_color)
		self.backdrop3a.anchor_point = (0.965, 0.5)
		self.backdrop3a.z_position = 0.4
		self.add_child(self.backdrop3a)
		
		self.backdrop3b = SpriteNode(position = self.finish.position, size = (8 * square_size, square_size + 10), color = text_color)
		self.backdrop3b.anchor_point = (0.035, 0.5)
		self.backdrop3b.z_position = 0.4
		self.add_child(self.backdrop3b)
		
		#---Setup: GO Button
		bd4 = ui.Path().rounded_rect(0, 0, square_size * 2, 50, 8)
		bd4.fill()
		bd4.close()
		self.backdrop4 = ShapeNode(bd4, position = (screen_w / 2, bottom_vertical), color = color1, size = (square_size * 2, 50))
		self.backdrop4.z_position = 0.8
		self.add_child(self.backdrop4)
		
		bd5 = ui.Path().rounded_rect(0, 0, square_size * 2 - 10, 40, 4)
		bd5.fill()
		bd5.close()
		self.backdrop5 = ShapeNode(bd5, stroke_color = color2, position = (screen_w / 2, bottom_vertical), size = (2 * square_size - 10, 40))
		self.backdrop5.line_width = 2
		self.backdrop5.z_position = 0.85
		self.add_child(self.backdrop5)
		
		self.commit_button = SpriteNode(texture = make_texture('Check'), color = text_color, position = (screen_w/2, bottom_vertical), size = (square_size, square_size), z_position = 0.9)
		self.add_child(self.commit_button)
		
		#---Setup: Restart Button and Timer
		circle1 = ui.Path()
		circle1.add_arc(0,0, 24, 0, pi * 2)
		circle1.line_width = 4
		circle1.stroke()
		circle1.close()
		
		circle2 = ui.Path()
		circle2.add_arc(0,0, 15, 0, pi * 2)
		circle2.close()
		
		circle3 = ui.Path()
		circle3.add_arc(0, 0, 26, 0, 2 * pi)
		circle3.line_width = 2
		circle3.stroke()
		circle3.close()
		
		tex_res = Texture('iob:ios7_refresh_32')
		self.restart_button = SpriteNode(texture = tex_res, position = (screen_w / 2 + square_size * 2.5, bottom_vertical), scale = 1)
		self.restart_button.z_position = 0.4
		self.add_child(self.restart_button)
		
		# Timer backgrounds
		self.green_timer_background = ShapeNode(circle1, color4, color1, position = self.restart_button.position)
		self.green_timer_background.rotation = pi/2
		self.green_timer_background.z_position = 0.18
		self.add_child(self.green_timer_background)
		
		self.white_timer_background = ShapeNode(circle2, fill_color = color4, position = self.restart_button.position)
		self.white_timer_background.z_position = 0.35
		self.add_child(self.white_timer_background)
		
		# Timer
		p = ui.Path()
		p.add_arc(0, 0, 26, 0, 0)
		p.stroke()
		p.close()
		self.timer = ShapeNode(p, background_color, background_color)
		self.timer.z_position = 0.19
		self.timer.rotation = pi/2
		self.timer.position = self.restart_button.position
		self.timer.alpha = 1
		self.add_child(self.timer)
		
		# Timer stright line markings
		line = ui.Path().rect(0, 0, 4, 25)
		line.fill()
		line.close()
		self.timer_mark = ShapeNode(line, color1, color1, position = self.restart_button.position, size = (4, 25))
		self.timer_mark.anchor_point = (0.5, 0)
		self.timer_mark.z_position = 0.3
		self.add_child(self.timer_mark)
		
		self.timer_mark_2 = ShapeNode(line, color1, color1, position = self.restart_button.position, size = (4, 25))
		self.timer_mark_2.anchor_point = (0.5, 0)
		self.timer_mark_2.z_position = 0.3
		self.add_child(self.timer_mark_2)
		
		self.timer_ring = ShapeNode(circle3)
		self.timer_ring.alpha = 0
		
		#---Setup: Score
		self.score = LabelNode("0", font = ('Helvetica-bold', 40), color = text_color, position = (screen_w / 2 - square_size * 2.5, bottom_vertical), size = (square_size, square_size), z_position = 0.9)
		self.add_child(self.score)
		
		#---Setup: Initialise variables
		self.can_play = True
		self.can_settings = True
		self.can_highscore = True
		self.unlock = False
		self.can_restart = False
		self.win = False
		self.no_whites = False
		self.punishment = False
		self.reward = False
		self.can_flip = False
		self.low_time = False
		self.green_list = []

		# Start a new game!
		self.new_game(False)
		if username == "Player":
			self.get_name()

	# Prompt for name if first startup
	#@ui.in_background
	def get_name(self):
		global username
		sleep(1)
		try:
			username = dialogs.input_alert("Enter your name", "This will be used on the high score tables!")
			if username == '':
				username = 'Unknown'
			new_data = (background_color, color3, color4, difficulty, text_color, username)
			with open("bwconfig.dat", "wb") as out_file:
				pickle.dump(new_data, out_file)
		except KeyboardInterrupt:
			username = 'Unknown'
			new_data = (background_color, color3, color4, difficulty, text_color, username)
			with open("bwconfig.dat", "wb") as out_file:
				pickle.dump(new_data, out_file)

	#---Other Functions

	# GO button pressed!
	def commit(self):
		self.stop_squares_moving()
		self.destroy_crosses()
		self.can_play = False
		self.low_time = False
		self.can_settings = False
		self.highscore_button.alpha = 1
		sound.play_effect(button_sound)
		for square in self.squares:
			# Start the process with the square beside the start point
			if square.row == self.start.row and square.col == 1:
				if square.state == 2:
					square.state = 3
					square.color = color4
					self.go(square)
				else:  # Lose if starting square is not white!
					self.losing()

	# Check for adjacent squares through grid to make a path (uses a double-ended queue)
	def go(self, start_square):
		def cascade(node, progress):
			if progress == 1 and node.state == 3 and self.win:
				node.state = 4
				self.sparkle(color4, node.position, image='shp:RoundRect')
				node.color = color4
			elif progress == 1 and node.state == 4 and self.win:
				self.sparkle(color4, node.position, image='shp:RoundRect')
				node.color = color4
				self.finish.color = color4
			elif progress == 1 and node.state == 0 and not self.win:
				self.sparkle(color3, node.position, image='shp:RoundRect')
				node.color = color3

		self.green_list.append(start_square)
		index = 0.01
		while self.green_list:
			square = self.green_list.pop(randint(0, len(self.green_list) - 1))
			square.state = 3
			square.run_action(A.call(cascade, index))
			index += 0.01

			for n in square.white_neighbours(self.squares):
				if n not in self.green_list:
					self.green_list.append(n)
		# Once list is empty, check win status
		self.check_win()
		
	# Check if successful by checking state of square adjacent to end point
	def check_win(self):
		self.can_play = False
		self.can_flip = False
		self.unlock = False
		for square in self.squares:
			square.rotation = 0.0
			if square.row == self.finish.row and square.col == cols:
				if square.state == 3:
					square.state = 4
					self.win = True
					self.can_play = False
					self.winning()
					return
				elif square.state == 4:
					return		
		self.losing()

	# Success!
	def winning(self):
		square_states = [square.state for square in self.squares]
		self.black_count.text = str(square_states.count(1))
		self.white_count.text = str(square_states.count(2))
		add_score = 0
		for square in self.squares:
			if square.state >= 3:
				add_score += 1

		self.commit_button.texture = make_texture('Right')
		self.restart_button.texture = Texture('iob:checkmark_circled_32')

		if self.star_square:
			if self.star_square.state >= 3:
				self.sparkle(text_color, self.star_square.position, image='shp:Star', spread = 40, z_position = 0.99)
				p_list = []
				for item in (self.p1_count, self.p2_count, self.p3_count):
					if int(item.text) < 9:
						p_list.append(item)
				if not p_list:
					p_list.append(self.score)
				
				powerup = choice(p_list)
				pos = powerup.position

				self.powerup_indicator = powerup
				if text_color == 1:
					self.star_square.star_icon.scale = 0.8
					self.star_square.star_icon.texture = Texture('typw:Star')

				self.star_square.star_icon.z_position = 0.9
				self.star_square.star_icon.run_action(A.sequence(A.scale_by(0.2, 0.1), A.scale_by(-0.2, 0.1), A.group(A.move_to(pos[0], pos[1], 1.8, TIMING_SINODIAL), A.fade_to(0, 1.8, TIMING_EASE_IN), A.rotate_by(2 * pi, 2)), A.remove()))
				if powerup != self.score:
					powerup.run_action(A.sequence(A.wait(1.8), A.scale_to(1.5, 0.2, TIMING_BOUNCE_IN_OUT), A.scale_to(1, 0.2)))
			
				if powerup == self.score:
					self.score.text = str(int(self.score.text)+ self.level)
					self.ten = LabelNode("+"+str(self.level), font = ('Helvetica-bold', 30), position = self.star_square.position + (0, 30), color = text_color, z_position = 0.81)
					self.add_child(self.ten)
					self.ten.run_action(A.sequence(A.wait(0.2), A.group(A.move_to(pos[0], pos[1]+30, 1.8, TIMING_SINODIAL), A.fade_to(0, 1.9, TIMING_EASE_IN)), A.remove()))
					
					for item in (self.p_max_1, self.p_max_2, self.p_max_3):
						self.sparkle(color4, item.position, image='shp:Star') 
						item.run_action(A.sequence(A.scale_to(1.2, 0.4), A.scale_to(1, 0.4)))
				else:
					def powerup_increment(node, progress):
						if progress == 1 and int(node.text) < 9:
							sound.play_effect(powerup_sound)
							node.text = str(int(node.text) + 1)
					powerup.run_action(A.call(powerup_increment, 1.8))
		
		for bg in self.bg_list:
			bg.color = color4
		self.backdrop5.color = color4
		self.move_counters()
		self.score_change(add_score, self.win)
		self.sound_player()

	# Losing
	def losing(self):
		score_value = int(self.score.text)
		self.green_timer_background.fill_color = color3
		for square in self.squares:
			if square.star:
				square.star_icon.z_position = 1
				square.star_icon.run_action(A.sequence(A.scale_to(0, 1), A.remove()))
			if square.state == 3:
				square.state = 0
			if square.state == 0:
				square.z_position = 0.25
				bg_target = choice(self.bg_list).position
				square.run_action(A.sequence(A.wait(random() + 1),A.group(A.scale_to(0, 3), A.fade_to(0, 2), A.move_to(bg_target[0], bg_target[1], 2, TIMING_SINODIAL)), A.remove()))
		self.start.color = color3
		self.score.color = color3
		self.backdrop5.color = color3
		self.commit_button.texture = make_texture('Cross')
		self.level_label.text = choice(fail_text)
		self.move_counters()
		self.save(score_value)
		for bg in self.bg_list:
			bg.color = color3
		self.can_settings = True
		self.sound_player()

	# Change and animate scores
	def score_change(self, num, win):
		if num > 0:
			text = "+"+str(num)
		elif num < 0:
			text = str(num)
		else:
			text = ""
		
		red_count = len([square for square in self.squares if square.state == 0])
		if win:	
			self.score_label1 = LabelNode(text, font = ('Helvetica', score_label_font_size), color = color4, position = (screen_w / 2, 100 + score_label_gap), size = (square_size, square_size), z_position = 0.8, alpha = 0)
			self.add_child(self.score_label1)
			self.score_label1.run_action(score_action_1)
		
			self.score_label2 = LabelNode("-"+str(self.white_count.text), font = ('Helvetica', score_label_font_size), color = color2, position = (screen_w / 2, 100), size = (square_size, square_size), z_position = 0.8, alpha = 0)
			self.add_child(self.score_label2)
			self.score_label2.run_action(score_action_1)
	
			self.score_label3 = LabelNode("-"+str(red_count), font = ('Helvetica', score_label_font_size), color = color3, position = (screen_w / 2, 100 - score_label_gap), size = (square_size, square_size), z_position = 0.8, alpha = 0)
			self.add_child(self.score_label3)
			self.score_label3.run_action(score_action_1)
			
			sq = ui.Path().rounded_rect(0, 0, square_size * 4 - 12, square_size * 4 - 12, 4)
			sq.fill()
			sq.close()
			
			self.score_label_back = ShapeNode(sq, color = color1, position = (screen_w / 2, 100), alpha = 0)
			self.score_label_back.z_position =  0.7
			self.score_label_back.size = (4 * square_size - 14, 4 * square_size - 14)
			self.add_child(self.score_label_back)
			self.score_label_back.run_action(score_action_2)
			
			if self.no_whites:
				self.score_label2.text = "+" + str(rows + cols)
				num += rows + cols
			
			total_score_change = num - int(self.white_count.text) - red_count
		
			self.total_score_change_label = LabelNode("+"+str(total_score_change), font = ('Helvetica-bold', 40), color = text_color, position = self.score.position)
			self.total_score_change_label.z_position = 0.6
			
			if self.no_whites:
				if total_score_change < rows * cols:
					self.level_label.text = choice(no_white_text)
				else:
					self.reward = True
					if int(self.p1_count.text) + int(self.p2_count.text) + int(self.p3_count.text) < 18:
						self.level_label.text = choice(reward_text)
					else:
						self.level_label.text = choice(no_white_text)

					for item in (self.p1_count, self.p2_count, self.p3_count):
						if int(item.text) < 9:
							item.text = str(int(item.text) + 1)
							item.run_action(A.sequence(A.scale_to(1.5, 0.2, TIMING_BOUNCE_IN_OUT), A.scale_to(1, 0.2)))
							self.sparkle(color4, item.position - (square_size/4.0, 0), image = 'shp:RoundRect')
			else:
				if total_score_change > 0:
					self.level_label.text = choice(win_text)
					self.total_score_change_label.text = "+" + str(total_score_change)
				elif total_score_change == 0:
					self.level_label.text = choice(zero_text)
					self.total_score_change_label.text = "+" + str(total_score_change)
					self.punishment = True
				elif total_score_change < 0:
					self.level_label.text = choice(neg_text)
					self.total_score_change_label.text = str(total_score_change)
					self.total_score_change_label.color = color3
					self.punishment = True
		else:
			total_score_change = -1 * int(self.score.text)
			self.total_score_change_label = LabelNode(str(total_score_change), font = ('Helvetica-bold', 40), color = color3, position = self.score.position)
		self.add_child(self.total_score_change_label)
		
		self.score.text = str(int(self.score.text) + total_score_change)
		self.total_score_change_label.run_action(A.sequence(A.fade_to(1, 0.1), A.wait(1), A.move_to(screen_w / 2, bottom_vertical, 2, TIMING_EASE_IN_OUT), A.remove()))
		self.score.run_action(A.sequence(A.fade_to(0, 0), A.wait(1.8),A.fade_to(1, 0.5)))

	# Start a new game
	def new_game(self, win):
		self.can_restart = False
		for item in (self.timer_mark, self.timer_mark_2):
			item.alpha = 1
			item.run_action(A.sequence(A.scale_y_to(0.6, 0), A.scale_y_to(1, 0.3)))
		for item in (self.green_timer_background, self.white_timer_background):
			item.run_action(A.sequence(A.scale_to(0.6, 0), A.scale_to(1, 0.3)))
		self.restart_button.texture = Texture('iob:ios7_refresh_32')
		
		# Alert if score would be reset
		if self.can_play and self.score.text != '0':
			for square in self.squares:
				square.rotation = 0
			try:
				dialogs.alert("Do you want to start again?", "Your score will be reset to zero!", "Restart")
				self.level = 0
				self.level_label.text = 'level ' + str(self.level)
				self.losing()
			except KeyboardInterrupt:
				self.can_restart = True
				return

		# Alter variables
		self.can_play = False
		self.no_whites = False
		self.win = False
		self.level += 1
		self.level_label.text = 'Level ' + str(self.level)

		# Reset timer elements
		self.white_timer_background.fill_color = color2
		self.green_timer_background.fill_color = color4
		p = ui.Path()
		p.add_arc(0, 0, 28.0, 0, 0)
		p.stroke()
		p.close()
		self.timer.path = p
		self.timer.position = self.restart_button.position
		self.timer_mark_2.rotation = 0
		
		# Move background squares
		for bg in self.bg_list:
			bg.run_action(A.move_to(randint(0, screen_w), randint(0, screen_h), random()))
			bg.color = choice(all_colors)
		
		# Make a new grid
		self.make_grid()
		
		# Remove score popup if still present
		try:
			for item in (self.score_label1, self.score_label2, self.score_label3, self.score_label_back):
				item.run_action(A.remove())
		except:
			pass
		
		# Reset score and level if previous round not won
		if not win:
			self.score.text = "0"
			self.level = 1
			self.level_label.text = 'Level ' + str(self.level)
			self.p1_count.text = str(starting_powerups)
			self.p2_count.text = str(starting_powerups)
			self.p3_count.text = str(starting_powerups)
			self.can_settings = True
		
		# Move black & white square counters
		self.move_counters()
		
		self.score.color = text_color
		self.backdrop5.color = color4
		self.commit_button.texture = make_texture('Check')
		self.restart_button.remove_all_actions()
		
		# New game sound!
		sound.play_effect(new_game_sound)

	# Make a new grid of squares
	def make_grid(self):
		global rows, cols, top_left
		
		if self.punishment:
			rows, cols = 4, 4
			self.level_label.text = choice(punishment_text)
		else:
			rows = randrange(4, 11, 2)
			if rows == 4:
				cols = 6
			else:
				cols = randrange(4, 7, 2)

		top_left = (centre[0] - square_size * (cols / 2.0 - 0.5), (centre[1] + square_size * (rows / 2.0 - 0.5)))
		
		for square in self.squares:
			bg_target = choice(self.bg_list).position
			square.alpha = 0.6
			square.scale = 0.6
			square.run_action(A.sequence(A.group(A.scale_to(0, 2), A.fade_to(0, 2), A.move_to(bg_target[0], bg_target[1], 2, TIMING_SINODIAL)), A.remove()))
		
		self.start.row = randint(1, rows)
		self.start.color = color4
		self.finish.row = randint(1, rows)
		self.finish.color = color2
		
		border = ui.Path().rounded_rect(0, 0, cols * square_size + 20, rows * square_size + 20, 4)
		border.line_width = 6
		border.stroke()
		border.close()
		
		fine_border = ui.Path().rect(0, 0, cols * square_size, rows * square_size)
		fine_border.line_width = 1
		fine_border.stroke()
		fine_border.close()
		
		try:
			self.backdrop.run_action(A.remove())
			self.backdrop2.run_action(A.remove())
		except:
			pass
		
		self.backdrop = ShapeNode(border, (0,0,0,0), text_color, position = centre, size = (square_size * cols + 20, square_size * rows + 20))
		self.backdrop.blend_mode = BLEND_NORMAL
		self.backdrop.z_position = 0.3
		self.add_child(self.backdrop)
		
		self.backdrop2 = ShapeNode(fine_border, (0,0,0,0), text_color, position = centre, size = (square_size * cols, square_size * rows))
		self.backdrop2.z_position = 0.2
		self.add_child(self.backdrop2)

		self.start.run_action(A.move_to(top_left[0] - square_size, top_left[1] - square_size * (self.start.row - 1), 0.3))
		self.finish.run_action(A.move_to(top_left[0] + square_size * cols, top_left[1] - square_size * (self.finish.row - 1), 0.3))
		self.backdrop3a.run_action(A.move_to(top_left[0] - square_size, top_left[1] - square_size * (self.start.row - 1), 0.3))
		self.backdrop3b.run_action(A.move_to(top_left[0] + square_size * cols, top_left[1] - square_size * (self.finish.row - 1), 0.3))
		
		horizontal = top_left[0]
		vertical = top_left[1]
		self.squares = []
		for x in range(cols):
			for y in range(rows):
				self.square = Square(col = x + 1, row = y + 1, position = (horizontal, vertical), size = (square_size, square_size), state = choice((1, 2)), color = None)
				self.square.z_position = 0.5
				self.add_child(self.square)
				self.squares.append(self.square)
				vertical -= square_size
			vertical = top_left[1]
			horizontal += square_size

		longest_square = choice(self.squares)
		for square in self.squares:
			bg_target = choice(self.bg_list).position
			pos = square.position
			if square != longest_square:
				square.run_action(A.sequence(A.group(A.scale_to(0, 0), A.fade_to(0, 0), A.rotate_to(randrange(0, 6), 0), A.move_to(bg_target[0], bg_target[1], 0)), A.group(A.scale_to(1, randrange(5, 10) * 0.1), A.fade_to(0.8, randrange(1, 10) * 0.1), A.rotate_to(0, randrange(1, 10) * 0.1), A.move_to(pos[0], pos[1], randrange(1, 10) * 0.1, TIMING_SINODIAL))))
			elif square == longest_square:
				def now_can_play():
					self.can_play = True
					self.can_restart = True
					self.timestamp = self.t
				square.run_action(A.sequence(A.group(A.scale_to(0, 0), A.fade_to(0, 0), A.rotate_to(randrange(0, 6), 0), A.move_to(bg_target[0], bg_target[1], 0)), A.group(A.scale_to(1, 1), A.fade_to(0.8, 1), A.rotate_to(0, 1), A.move_to(pos[0], pos[1], 1, TIMING_SINODIAL)), A.wait(0.2), A.call(now_can_play)))
		try:
			self.star_square.star_icon.run_action(A.sequence(A.group(A.scale_to(0.3, 1), A.fade_to(0, 1)), A.remove()))
		except:
			pass
		if randrange(1, 3) == 1:
			self.star_square = choice(self.squares)
			self.star_square.go_star()
		else: self.star_square = None
		
		self.punishment = False
		self.reward = False
		self.can_flip = False
		self.unlock = False

	# Move black and white square counters
	def move_counters(self):
		black_list = [square for square in self.squares if square.state == 1]
		white_list = [square for square in self.squares if square.state == 2]
		self.black_count.text = str(len(black_list))
		self.white_count.text = str(len(white_list))
		
		wc = len(white_list)
		
		# Prevents the square counters appearing on top of the star, if it exists.
		try:
			if self.star_square:
				if self.star_square in black_list:
					black_list.remove(self.star_square)
				elif self.star_square in white_list:
					white_list.remove(self.star_square)
		except:
			pass
		try:
			b = choice(black_list)
			self.black_count.position = b.position
		except:
			self.black_count.position = (-100, -100) # Off screen if no black squares
			
		try:
			w = choice(white_list)
			self.white_count.position = w.position
		except:
			self.white_count.position = (-100, -100) # Off screen if no white squares
		
		if not wc:
			self.no_whites = True # Set no_whites flag for bonus

	# Save to global highscore table
	@ui.in_background
	def save(self, number):
		add_global_score(number)

	# Show global highscore table
	#@ui.in_background
	def display_scores(self):
		all_scores = get_global_scores()
		if all_scores == None:
			sound.play_effect(fail_sound)
			dialogs.hud_alert("Network Error", icon="error")
			self.highscore_button.alpha = 1
			self.can_highscore = True
			return
		if self.can_play:
			can_play_marker = True
			self.can_play = False
		else:
			can_play_marker = False
			if not self.win:
				for square in self.squares:
					if square.state == 0:
						square.run_action(A.fade_to(0, 0.2))
		paused_time = self.t
		display = ["RANK".ljust(12, " ") + "\t" + "SCORE".ljust(12, " ") + "\t" + "PLAYER".ljust(22, " "), ""]
		rank = 1
		for item in all_scores:
			display.append((str(rank)+" :").ljust(12, " ") + "\t" + str(item[0]).ljust(12, " ") + "\t\t" + str(item[1]).ljust(22, " "))
			rank += 1
		
		text = {1:"Easy", 2:"Regular", 3:"Hard"}
		try:
			dialogs.list_dialog("High Scores - "+text[difficulty], display)
		except KeyboardInterrupt:
			sound.play_effect(button_sound)
		if can_play_marker:
			self.can_play = True
		self.can_restart = True
		self.can_highscore = True
		self.highscore_button.alpha = 1
		self.timestamp += self.t - paused_time


	# Use timestamp for countdown. This is called with each update
	def timing(self):
		if self.can_play:
			time_allowed = 61 - (difficulty * 10) - (self.level * 0.5 * difficulty)
			time_allowed = max(time_allowed, 5)
			
			time_elapsed = self.t - self.timestamp
			
			angle = 2 * pi * time_elapsed / time_allowed
			
			if time_elapsed >= time_allowed:
				self.can_play = False
				self.timer_mark.run_action(A.fade_to(0,0))
				self.timer_mark_2.run_action(A.fade_to(0,0))
				self.sparkle(color3, self.restart_button.position, image='shp:Circle', spread = 50, z_position = 0.2, n = 20)
				self.commit()
				return
			
			elif time_elapsed > time_allowed - 5 and not self.low_time:
				self.low_time = True
				self.green_timer_background.fill_color = color3
				self.timer_sound()
			
			# Draw arc of timer (this is a background-colored (invisible) arc that grows from 12 o'clock position clockwise to cover the coloured timer background)
			radius = 28.0
			p = ui.Path()
			p.add_arc(0, 0, radius, 0, angle)
			p.stroke()
			p.close()
			self.timer.path = p
			mid_frame = (self.timer.frame[2]/2.0, self.timer.frame[3]/2.0)
			rp = self.restart_button.position
			
			# Timer position needs to change as size changes throughout animation as anchor point would cause it to move erratically
			if angle < pi:
				self.timer.position = (rp[0] + mid_frame[0], rp[1] + radius - mid_frame[1])
			else:
				self.timer.position = (rp[0] + radius - mid_frame[0], rp[1] + radius - mid_frame[1])
				
			# The motion is smoothed by rotating the second black mark over the leading edge of the timer
			self.timer_mark_2.rotation = 2 * pi - (time_elapsed/time_allowed * 2 * pi)

	# Low time warning sound
	@ui.in_background
	def timer_sound(self):
		if randrange(1, 3) == 1:
			countdown_flag = True
		else:
			countdown_flag = False
			self.level_label.text = choice(hurry_text)
		self.highscore_button.alpha = 0.2
		marker = 5
		for x in range(5):
			if self.can_play and self.low_time:
				if countdown_flag:
					self.level_label.text = str(marker)
				sound.play_effect(timer_tick)
				marker -= 1
				sleep(0.98)
			else:
				return

	# Destroy locked square crosses that are created when power-up 2 active
	def destroy_crosses(self):
		for square in self.squares:
			try:
				square.cross.run_action(A.sequence(A.scale_to(0, 0.2), A.remove()))
			except:
				pass
	
	# Stop square animations
	def stop_squares_moving(self):
		for square in self.squares:
			square.remove_all_actions()
			square.scale = 1
		try:
			if self.star_square and self.can_play:
				self.star_square.star_icon.remove_all_actions()
		except:
			pass
		self.black_count.remove_all_actions()
		self.white_count.remove_all_actions()
	
	# Provides particle effects
	def sparkle(self, color, position, image = 'shp:sparkle', spread = 40, z_position = 0.6, n = 6):
		for i in xrange(n):
			p = SpriteNode(image, position=position, color=color, z_position = z_position, alpha = 0.7)
			r = spread
			dx, dy = uniform(-r, r), uniform(-r, r)
			p.run_action(A.sequence(A.group(A.scale_to(0, 0.8), A.move_by(dx, dy, 0.8, TIMING_EASE_OUT_2)), A.remove()))
			self.add_child(p)
	
	# Decides which sound to play at end of game
	def sound_player(self):
		if self.win:
			if self.star_square and self.star_square.state >= 3:
				if self.powerup_indicator == self.score:
					sound.play_effect(star_bonus_sound)
					return
				else:
					sound.play_effect(star_sound)
			if self.no_whites:
				sound.play_effect(no_white_sound)
				return
			if int(self.total_score_change_label.text) <= 0:
				sound.play_effect(neg_sound)
				return
			sound.play_effect(win_sound)
		else:
			sound.play_effect(fail_sound)
			
		
	#---Update

	# Updated every frame
	def update(self):
		for bg in self.bg_list:
			if self.bg_list.index(bg) % 2 == 0:
				bg.position += (gravity()[0] * 0.1 * bg.speed, gravity()[1] * 0.1 * bg.speed)
			else:
				bg.position += (gravity()[0] * -0.1 * bg.speed, gravity()[1] * -0.1 * bg.speed)

		self.settings.alpha = 1 if self.can_settings else 0.2
		
		for square in self.squares:
			if square.state == 2:
				square.alpha = 0.8
			else:
				square.alpha = 1.0

		self.powerup2_bg.color = color3 if self.unlock else color2
		
		if self.can_flip:
			self.powerup3_bg.color = color1
			self.powerup3.texture = Texture('typw:Contrast')
			self.p3_count.color = color2
		else:
			self.powerup3_bg.color = color2
			self.powerup3.texture = Texture('typb:Contrast')
			self.p3_count.color = color1

		if self.unlock:
			self.powerup2_bg.color = color3
		else:
			self.powerup2_bg.color = color2
		
		# Powerup max indicators
		for item in (self.p1, self.p2, self.p3):
			item[3].alpha = int(item[2].text >= "9")
		
		self.timing() # Call timing method every frame
	
	
	#---Settings Menu
	
	# Settings menu - calls a pyui file
	def settings_options(self):
		# Cannot change settings while game in progress
		if not self.can_settings:
			return
		
		# Pause timer
		self.can_play = False
		self.pause_time = self.t
		
		# Initialise target box for color sliders
		target = None
		
		# Cancel without applying new settings
		def cancel(sender):
			sound.play_effect(button_sound)
			view.close()
			self.new_game(self.win)
		
		# Shown instructions
		def how_to_play(sender):
			def close(sender):
				sound.play_effect(button_sound)
				view2.close()
				return
			def review(sender):
				sound.play_effect(button_sound)
				webbrowser.open("itms-apps://itunes.apple.com/app/viewContentsUserReviews?id=1102097118")
			sound.play_effect(button_sound)
			view2 = ui.load_view("info")
			view2.present('full_screen', hide_title_bar = True, animated = True)
			close_button = view2["close_button"]
			review_button = view2["review_button"]
			webview = view2["webview"]
			webview.load_html("<html><head><body><br><br><br><br><h1 align=\"center\" style=\"font-family:Helvetica; font-size:60px\">Loading...</h1></body></head></html>")
			try:
				webview.load_url("http://www.chrisandkathy.co.uk/blackwhite/info.html")
			except:
				webview.load_html("<html><head><body><br><br><br><br><h1 align=\"center\" style=\"font-family:Helvetica; font-size:60px\">Network Error</h1><p align=\"center\" style=\"font-family:Helvetica; font-size:20px\">Tap \'Close' to continue</p></body></head></html>")

		# Reset to default color scheme
		def default(sender):
			global target
			sound.play_effect(button_sound)
			text_color_selector.selected_index = 0
			view.background_color = 1
			color_3.background_color = '#ff0000'
			color_3.border_width = 2
			color_4.background_color = '#00ff00'
			color_4.border_width = 2
			bg_color.background_color = '#ffffff'
			bg_color.border_width = 2
			
			for item in (label1, label2, label3, label4):
				item.text_color = text_color_selector.selected_index
			for item in (c3_button, c4_button, bg_button):
				item.tint_color = text_color_selector.selected_index
			red.value = 0.5
			green.value = 0.5
			blue.value = 0.5
			target = None

		# Reset to current active color scheme
		def current(sender):
			global target
			sound.play_effect(button_sound)
			text_color_selector.selected_index = text_color
			view.background_color = background_color
			color_3.background_color = color3
			color_3.border_width = 2
			color_4.background_color = color4
			color_4.border_width = 2
			bg_color.background_color = background_color
			bg_color.border_width = 2
			
			for item in (label1, label2, label3, label4):
				item.text_color = text_color_selector.selected_index
			for item in (c3_button, c4_button, bg_button):
				item.tint_color = text_color_selector.selected_index
			red.value = 0.5
			green.value = 0.5
			blue.value = 0.5
			target = None
			
		# Selected color applied to target box continuously while sliders moved
		def get_color(sender):
			global target
			try:
				target.background_color = (red.value, green.value, blue.value, 1)
				if target == bg_color:
					view.background_color = (red.value, green.value, blue.value, 1)
			except:
				pass
		
		# Set which color box the color sliders apply to
		def set_target(sender):
			global target
			sound.play_effect(button_sound)
			for item in color_group:
				item.border_width = 2
			if sender == c3_button:
				target = color_3
			elif sender == c4_button:
				target = color_4
			elif sender == bg_button:
				target = bg_color
			target.border_width = 5
			red.value = target.background_color[0]
			green.value = target.background_color[1]
			blue.value = target.background_color[2]
		
		# Settings only applied if save button pressed
		def save_settings(sender):
			global all_colors
			global text_color
			global color3
			global color4
			global background_color
			global text_color
			global difficulty
			global starting_powerups
			global username
			
			sound.play_effect(button_sound)
			
			text_color = text_color_selector.selected_index
			for item in (self.title, self.title2, self.score, self.level_label, self.backdrop3a, self.backdrop3b, self.commit_button):
				item.color = text_color
			
			for item in (self.backdrop, self.backdrop2):
				item.stroke_color = text_color
			
			self.exit_icon.texture = make_texture('Cross')
			self.settings.texture = make_texture('Cog')
			self.highscore_button.texture = make_texture('Group')

			color3 = color_3.background_color
			color4 = color_4.background_color
			
			background_color = bg_color.background_color
			self.background_color = background_color
			self.level_bg.color = background_color
			self.timer.stroke_color = background_color
			self.timer.fill_color = background_color
			self.green_timer_background.fill_color = color4
			
			for item in (self.p1, self.p2, self.p3):
				item[3].stroke_color = color4
			
			difficulty = diff_selector.selected_index + 1
			starting_powerups = 9 - difficulty * 3
			
			all_colors = (color1, color2, color3, color4)
			
			username = name_box.text
			
			# Close settings and start a new game
			view.close()
			self.new_game(self.win)
			
			# Configuration data saved for next startup
			data = (background_color, color3, color4, difficulty, text_color, username)
			with open("bwconfig.dat", "wb") as out_file:
				pickle.dump(data, out_file)
		
		# Update colors when any button pressed
		def press_button(sender):
			sound.play_effect(button_sound)
			for item in (c3_button, c4_button, bg_button):
				item.tint_color = text_color_selector.selected_index
			for item in (label1, label2, label3, label4):
				item.text_color = text_color_selector.selected_index
			
		self.can_play = False
		sound.play_effect(button_sound)
		
		# Settings user interface setup
		if screen_w >= 375:
			view = ui.load_view("bw_settings_375x667.pyui")
		else:
			view = ui.load_view("bw_settings_320x480.pyui")
		view.alpha = 1
		view.present('sheet', hide_title_bar = True, animated = True)
		view.background_color = background_color
		settings_bg = view['settings_bg']
		red = view['red']
		green = view['green']
		blue = view['blue']
		color_3 = view['color_3']
		color_3.background_color = color3
		color_4 = view['color_4']
		color_4.background_color = color4
		bg_color = view['bg_color']
		bg_color.background_color = background_color
		c3_button = view['c3_button']
		c3_button.tint_color = text_color
		c4_button = view['c4_button']
		c4_button.tint_color = text_color
		bg_button = view['bg_button']
		bg_button.tint_color = text_color
		save_button = view['save_button']
		cancel_button = view['cancel_button']
		diff_selector = view['diff_selector']
		diff_selector.action = press_button
		diff_selector.selected_index = difficulty - 1
		text_color_selector = view['text_color_selector']
		text_color_selector.action = press_button
		text_color_selector.selected_index = text_color
		default_button = view['default_button']
		label1 = view['label1']
		label1.text_color = text_color
		label2 = view['label2']
		label2.text_color = text_color
		label3 = view['label3']
		label3.text_color = text_color
		label4 = view['label4']
		label4.text_color = text_color
		name_box = view['name_box']
		name_box.text = username
		color_group = (color_3, bg_color, color_4)
	
	
	#---Touch Events
	
	# Handles touch events and runs appropriate function
	def touch_began(self, touch):
		
		# Touch on GO button
		if touch.location in self.backdrop5.bbox and self.can_play:
			self.touch_go()
			
		# Touch on restart button
		elif touch.location in self.green_timer_background.bbox:
			self.touch_restart()
			
		# Touch on highscore button
		elif touch.location in self.highscore_button.bbox and self.can_highscore and not self.low_time:
			self.can_highscore = False
			self.touch_highscore()
		
		# Touch on Powerup 1
		elif touch.location in self.powerup1_bg.bbox and self.can_play and int(self.p1_count.text) > 0:
			self.touch_pu1()
			
		# Touch on Powerup 2
		elif touch.location in self.powerup2_bg.bbox and self.can_play and int(self.p2_count.text) > 0:
			self.touch_pu2()
		
		# Touch on powerup 3
		elif touch.location in self.powerup3_bg.bbox and self.can_play and int(self.p3_count.text) > 0:
			self.touch_pu3()
			
		# Touch on settings
		elif touch.location in self.settings.bbox:
			self.settings_options()
		
		# Touch on squares	
		elif self.can_play:
			self.touch_squares(touch)
	
	# Touch GO Button!
	def touch_go(self):
		self.commit_button.run_action(pressed_action_1)
		self.backdrop4.run_action(pressed_action_1)
		self.backdrop5.run_action(pressed_action_1)
			
		self.stop_squares_moving()
		self.commit()

	# Touch Restart Button
	def touch_restart(self):
		if self.can_restart:
			self.restart_button.run_action(pressed_action_1)
			self.stop_squares_moving()
			self.destroy_crosses()
			self.unlock = False
			self.can_flip = False
			sound.play_effect(button_sound)
			self.new_game(self.win)
			
	# Touch Highscore Button
	def touch_highscore(self):
		self.highscore_button.run_action(pressed_action_2)
		self.highscore_button.alpha = 0.2
		sound.play_effect(button_sound)
		#self.stop_squares_moving()
		self.display_scores()
		
	# Touch Power-Up 1
	def touch_pu1(self):
		self.stop_squares_moving()
		self.destroy_crosses()
		self.unlock = False
		self.can_flip = False
		self.level_label.text = "Flip all squares"
		self.powerup1.run_action(pressed_action_2)
		self.powerup1_bg.run_action(pressed_action_2)
		self.p1_count.run_action(pressed_action_2)
		sound.play_effect(flip_sound)
		self.p1_count.text = str(int(self.p1_count.text) - 1)
		for square in self.squares:
			if square.rotation == 0:
				square.run_action(toggle_action_1)
			else:
				square.run_action(toggle_action_2)
			if square.state == 1:
				square.state = 2
				square.color = color2
				square.alpha = 0.8
			elif square.state == 2:
				square.state = 1
				square.color = color1
				square.alpha = 1
			if square.star:
				square.go_star()
		self.move_counters()
			
		
	# Touch Power-Up 2
	def touch_pu2(self):
		self.stop_squares_moving()
		self.destroy_crosses()
		self.can_flip = False
		square_states = [square.state for square in self.squares]
		if 0 not in square_states:
			return
		sound.play_effect(button_sound)
		self.stop_squares_moving()
		self.level_label.text = "Unlock a tapped square"
		self.unlock = not self.unlock
		if not self.unlock:
			self.level_label.text = "Level " + str(self.level)
			return
			
		self.powerup2.run_action(pressed_action_2)
		self.powerup2_bg.run_action(pressed_action_2)
		self.p2_count.run_action(pressed_action_2)
			
		for square in self.squares:
			if square.state == 0 and self.unlock and square.last_state == 1:
				square.cross = SpriteNode(texture = Texture('typb:Cross'), color = color3)
				square.cross.position = square.position
				square.cross.z_position = 0.4
				self.add_child(square.cross)
				square.cross.run_action(A.repeat(A.sequence(A.scale_to(0.85, 0.4, TIMING_EASE_IN_OUT), A.scale_to(0.95, 0.4, TIMING_EASE_IN_OUT)), 0))
					
			elif square.state == 0 and self.unlock and square.last_state == 2:
				square.cross = SpriteNode(texture = Texture('typw:Cross'), color = color2)
				square.cross.position = square.position
				square.cross.z_position = 0.4
				self.add_child(square.cross)
				square.cross.run_action(A.repeat(A.sequence(A.scale_to(0.85, 0.4, TIMING_EASE_IN_OUT), A.scale_to(0.95, 0.4, TIMING_EASE_IN_OUT)), 0))
	
	# Touch Power-Up 3
	def touch_pu3(self):
		self.unlock = False
		self.stop_squares_moving()
		self.destroy_crosses()
		self.level_label.text = "Flip a single square"
		self.powerup3.run_action(pressed_action_2)
		self.powerup3_bg.run_action(pressed_action_2)
		self.p3_count.run_action(pressed_action_2)
		sound.play_effect(button_sound)
		self.can_flip = not self.can_flip
		if not self.can_flip:
			self.level_label.text = "Level " + str(self.level)
			for square in self.squares:
				square.remove_all_actions()
				square.scale = 1
			return
		for item in (self.black_count, self.white_count):
			item.run_action(A.repeat(A.sequence(A.scale_to(0.85, 0.4, TIMING_EASE_IN_OUT), A.scale_to(0.95, 0.4, TIMING_EASE_IN_OUT)), 0))
		try:
			if self.star_square:
				self.star_square.star_icon.run_action(A.repeat(A.sequence(A.scale_to(0.85, 0.4, TIMING_EASE_IN_OUT), A.scale_to(0.95, 0.4, TIMING_EASE_IN_OUT)), 0))
		except:
			pass
		for square in self.squares:
			if square.state in (1, 2):
				square.run_action(A.repeat(A.sequence(A.scale_to(0.85, 0.4, TIMING_EASE_IN_OUT), A.scale_to(0.95, 0.4, TIMING_EASE_IN_OUT)), 0))
	
	# Touch grid squares
	def touch_squares(self, touch):
		self.destroy_crosses()
		for square in self.squares:
			
			# Touch to toggle square
			if touch.location in Rect(square.bbox[0]+2, square.bbox[1]+2, square.bbox[2]-4, square.bbox[3]-4) and square.state in (1, 2):
				self.level_label.text = "Level " + str(self.level)
				square.pressed()
				if square.rotation == 0:
					square.run_action(toggle_action_1)
				else:
					square.run_action(toggle_action_2)
				
				if not self.can_flip:
					# Usual toggle sequence
					square.toggle_neighbours(self.squares)	
					
				elif self.can_flip:
					# Toggle single square
					self.p3_count.text = str(int(self.p3_count.text) - 1)
					self.stop_squares_moving()
					
				self.move_counters()
				self.unlock = False
				self.can_flip = False
				
				
			#Touch to unlock red square
			elif touch.location in square.bbox and square.state == 0 and self.unlock:
				sound.play_effect(reds_away)
						
				self.p2_count.text = str(int(self.p2_count.text) - 1)
				square.press = False
				square.state = square.last_state
				if square.state == 1:
					square.color = color1
				elif square.state == 2:
					square.color = color2
				if square.rotation == 0:
					square.run_action(toggle_action_1)
				else:
					square.run_action(toggle_action_2)
					
				self.move_counters()	
				self.unlock = False
				self.can_flip = False
				self.level_label.text = "Level " + str(self.level)


#---Class: Square
# Squares making up the grid
class Square (SpriteNode):
	def __init__(self, row, col, position, size, state, color):
		self.row = row
		self.col = col
		self.position = position
		self.size = square_size, square_size
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
			self.star_icon.run_action(A.sequence(A.scale_to(0, 0.5),A.remove()))
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
		self.star_icon = SpriteNode(texture = tex, position = self.position, size = (square_size - 5, square_size - 5))
		self.star_icon.z_position = 0.6
		self.parent.add_child(self.star_icon)
		

#---Class: Start / End Points
class StartFinish (SpriteNode):
	def __init__(self, row, type):
		if type == "start":
			self.anchor_point = (0.9375, 0.5)
			self.position = (top_left[0] - square_size, top_left[1] - square_size * (row - 1))
			self.color = color4
		elif type == "finish":
			self.anchor_point = (0.0625, 0.5)
			self.position = (top_left[0] + square_size * cols, top_left[1] - square_size * (row - 1))
			self.color = color2
		self.size = (8 * square_size + 2, square_size)
		self.z_position = 0.45
		self.row = row
