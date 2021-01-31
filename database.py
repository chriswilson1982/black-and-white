# coding: utf-8

# SQLite functions for high scores

from datetime import datetime
import sqlite3


def check_final_score(name, score, difficulty):
    score = int(score)
    if score <= 0:
        return ""
    diff = ["easy", "regular", "hard"][difficulty - 1]
    table = "scores_" + diff
    now = str(datetime.now())

    # Get personal and global highscores to compare
    compare_score = {'global': 0, 'personal': 0}

    # Connect to database
    connection = sqlite3.connect('db/scores.db')
    cursor = connection.cursor()

    # Get personal high score
    try:
        cursor.execute(
            "SELECT score FROM {} WHERE name=? ORDER BY score DESC LIMIT 1".format(table), (name, ))
        compare_score['personal'] = cursor.fetchall()[0][0]
    except:
        compare_score['personal'] = 0

    # Get global highscore
    try:
        cursor.execute(
            "SELECT score FROM {} ORDER BY score DESC, timestamp ASC LIMIT 1".format(table))
        compare_score['global'] = cursor.fetchall()[0][0]
    except:
        compare_score['global'] = 0

    # Save score
    cursor.execute("INSERT INTO {} (name, score, timestamp) VALUES (?, ?, ?)".format(
        table), (name, score, now))

    # Close connection
    connection.commit()
    connection.close()

    # Check if highscore notification needed
    if score > compare_score['global']:
        return "g"
    elif score > compare_score['personal']:
        return "p"
    else:
        return ""


def get_all_scores(difficulty):
    try:
        diff = ["easy", "regular", "hard"][difficulty - 1]
        table = "scores_" + diff

        # Connect to database
        connection = sqlite3.connect('db/scores.db')
        cursor = connection.cursor()

        cursor.execute(
            "SELECT name, MAX(score) AS maxscore FROM {} GROUP BY name ORDER BY maxscore DESC".format(table))

        output = cursor.fetchall()

        # Close connection
        connection.commit()
        connection.close()

        return output

    except:
        return None


def reset_highscores():
    connection = sqlite3.connect('db/scores.db')
    cursor = connection.cursor()
    if cursor.execute("DELETE FROM scores_easy"):
        print("Deleted easy high scores")
    if cursor.execute("DELETE FROM scores_regular"):
        print("Deleted regular high scores")
    if cursor.execute("DELETE FROM scores_hard"):
        print("Deleted hard high scores")
    connection.commit()
    connection.close()
    print("Operation completed")
