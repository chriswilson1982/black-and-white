import pickle

# Select difficulty and run script to see high score table

difficulty = 2  # Change this (1-easy, 2-regular, 3-hard)

with open("bwsave"+str(difficulty)+".dat", "rb") as in_file:
    test = pickle.load(in_file)

for x in sorted(test, reverse=True):
    print('{} - {}'.format(*x))
