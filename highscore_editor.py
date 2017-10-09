import pickle

# Select difficulty and run script to reset highscore table to data below

difficulty = 2  # Change this (1-easy, 2-regular, 3-hard)

scores = [
    [100, "Player"],
    [200, "Player"],
    [300, "Player"],
    [400, "Player"],
    [500, "Player "],
    [600, "Player"],
    [700, "Player"],
    [800, "Player"],
    [900, "Player"],
    [1000, "Player"]
]

with open("bwsave"+str(difficulty)+".dat", "wb") as in_file:
    pickle.dump(scores, in_file)
