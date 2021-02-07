# coding: utf-8
"""SQLite functions for score recording and management.

Database file: db/scores.db
"""

from datetime import datetime
import sqlite3


def check_final_score(name, score, difficulty):
    """Check if final score is a personal or global high score.

    Accept name (string), score (integer) and difficulty (integer 1-3) and return a flag ('p' or 'g') if score is a personal or global high score.
    """
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
    """Return score data.

    Accept difficulty (integer 1-3) and return all score data for leaderboard.
    """
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
    """Reset score data.

    Erases all score data from all three difficulty settings.
    Not used by the game.
    """
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


def print_scores(difficulty, limit=None):
    """View score data.

    Accept difficulty (integer 1-3) and optional limit (integer) and print score data to console.
    Not used by the game.
    """
    connection = sqlite3.connect('db/scores.db')
    cursor = connection.cursor()
    diff = ["easy", "regular", "hard"][difficulty - 1]
    table = "scores_" + diff
    cursor.execute("SELECT * FROM {} ORDER BY timestamp DESC".format(table))
    data = list(cursor.fetchall())
    connection.close()
    print('\nDifficulty   | ' + diff.capitalize() +
          '\nTotal games  | ' + str(len(data)) + '\n')
    if limit and len(data) > limit:
        data = data[:limit]
        print('Showing ' + str(limit) + ' most recent games:\n')
    else:
        print('Showing all games\n')
    print('Name         | Score | Date & Time\n' + '-' * 39)
    for item in data:
        timestamp = datetime.strptime(item[2], '%Y-%m-%d %H:%M:%S.%f')
        printing_date = datetime.strftime(timestamp, '%Y-%m-%d %H:%M')
        print(str(item[0])[:12].ljust(12, ' ') + ' | ' +
              str(item[1]).rjust(5, ' ') + ' | ' + printing_date)
