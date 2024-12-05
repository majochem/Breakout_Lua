CREATE TABLE IF NOT EXISTS ball (
    id INTEGER PRIMARY KEY,
    x INTEGER,
    y INTEGER,
    angle_rad REAL,
    speed INTEGER
);

CREATE TABLE IF NOT EXISTS grid (
    id INTEGER PRIMARY KEY
);


-- Grid data structure for rows
CREATE TABLE IF NOT EXISTS grid_row (
    id INTEGER PRIMARY KEY,
    grid_id INTEGER NOT NULL, -- Link to parent grid
    y_index INTEGER NOT NULL, -- 1 to N indicating row number in the grid
    FOREIGN KEY (grid_id) REFERENCES grid (id)
);

CREATE TABLE IF NOT EXISTS grid_brick (
    id INTEGER PRIMARY KEY,
    row_id INTEGER NOT NULL, -- references the parent row
    x_index INTEGER NOT NULL,
    variant TEXT NOT NULL, -- maximum 1 character
    current_hp INTEGER NOT NULL,
    destroyed INTEGER NOT NULL, -- 1 for true, 0 for false
    FOREIGN KEY (row_id) REFERENCES grid_row (id)
);

CREATE TABLE IF NOT EXISTS player (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    paddle_x INTEGER NOT NULL,
    score INTEGER DEFAULT 0,
    level INTEGER DEFAULT 1,
    lives INTEGER NOT NULL,
    ball_id INTEGER NOT NULL,
    FOREIGN KEY (ball_id) REFERENCES ball (id)
);

CREATE TABLE IF NOT EXISTS game (
    id INTEGER PRIMARY KEY,
    date_time TEXT NOT NULL, -- ISO 8601 format suggested
    player_id INTEGER NOT NULL,
    FOREIGN KEY (player_id) REFERENCES player (id)
);


