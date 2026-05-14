
-- MINI PROJECT: SOCIAL NETWORK DATABASE

-- 1. TẠO DATABASE
CREATE DATABASE IF NOT EXISTS SocialNetworkDB;
USE SocialNetworkDB;

-- 2. TẠO BẢNG

-- Bảng users
CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    password VARCHAR(255) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Bảng posts
CREATE TABLE posts (
    post_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    content TEXT NOT NULL,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_posts_user
        FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE
);

-- Bảng likes
CREATE TABLE likes (
    like_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    post_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_likes_user
        FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_likes_post
        FOREIGN KEY (post_id)
        REFERENCES posts(post_id)
        ON DELETE CASCADE
);

-- Bảng comments
CREATE TABLE comments (
    comment_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    post_id INT NOT NULL,
    comment_text TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_comments_user
        FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_comments_post
        FOREIGN KEY (post_id)
        REFERENCES posts(post_id)
        ON DELETE CASCADE
);

-- Bảng friends
CREATE TABLE friends (
    friend_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    friend_user_id INT NOT NULL,
    status ENUM('pending', 'accepted', 'blocked') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_friends_user
        FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_friends_friend
        FOREIGN KEY (friend_user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE
);

-- 3. INDEX

CREATE INDEX idx_posts_created_at
ON posts(created_at);

-- 4. MOCK DATA

-- Users
INSERT INTO users(username, password, email)
VALUES
('alice', 'alice123', 'alice@gmail.com'),
('bob', 'bob123', 'bob@gmail.com'),
('charlie', 'charlie123', 'charlie@gmail.com');

-- Posts
INSERT INTO posts(user_id, content)
VALUES
(1, 'Hello everyone!'),
(2, 'Learning MySQL Views'),
(3, 'Social Network Project');

-- Likes
INSERT INTO likes(user_id, post_id)
VALUES
(2, 1),
(3, 1),
(1, 2);

-- Comments
INSERT INTO comments(user_id, post_id, comment_text)
VALUES
(2, 1, 'Nice post!'),
(3, 1, 'Great content!'),
(1, 2, 'Good luck!');

-- Friends
INSERT INTO friends(user_id, friend_user_id, status)
VALUES
(1, 2, 'accepted'),
(1, 3, 'accepted'),
(2, 3, 'pending');

-- 5. VIEW: view_user_info

CREATE VIEW view_user_info AS
SELECT
    user_id,
    username,
    email,
    created_at
FROM users;

-- 6. VIEW: view_post_statistics

CREATE VIEW view_post_statistics AS
SELECT
    p.post_id,
    u.username,
    p.content,

    COUNT(DISTINCT l.like_id) AS total_likes,
    COUNT(DISTINCT c.comment_id) AS total_comments,

    p.created_at

FROM posts p

LEFT JOIN users u
    ON p.user_id = u.user_id

LEFT JOIN likes l
    ON p.post_id = l.post_id

LEFT JOIN comments c
    ON p.post_id = c.post_id

WHERE p.is_deleted = FALSE

GROUP BY
    p.post_id,
    u.username,
    p.content,
    p.created_at;

-- 7. STORED PROCEDURE: sp_add_user

DELIMITER //

CREATE PROCEDURE sp_add_user(
    IN p_username VARCHAR(50),
    IN p_password VARCHAR(255),
    IN p_email VARCHAR(100)
)
BEGIN

    DECLARE email_count INT;

    SELECT COUNT(*)
    INTO email_count
    FROM users
    WHERE email = p_email;

    IF email_count > 0 THEN

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Email đã được sử dụng';

    ELSE

        INSERT INTO users(username, password, email)
        VALUES(p_username, p_password, p_email);

    END IF;

END //

DELIMITER ;

-- 8. STORED PROCEDURE: sp_create_post

DELIMITER //

CREATE PROCEDURE sp_create_post(
    IN p_user_id INT,
    IN p_content TEXT,
    OUT p_new_post_id INT
)
BEGIN

    INSERT INTO posts(user_id, content)
    VALUES(p_user_id, p_content);

    SET p_new_post_id = LAST_INSERT_ID();

END //

DELIMITER ;

-- 9. STORED PROCEDURE: sp_get_friends

DELIMITER //

CREATE PROCEDURE sp_get_friends(
    IN p_user_id INT,
    IN p_limit INT,
    IN p_offset INT
)
BEGIN

    SELECT
        u.user_id,
        u.username,
        u.email,
        f.created_at

    FROM friends f

    INNER JOIN users u
        ON f.friend_user_id = u.user_id

    WHERE f.user_id = p_user_id
        AND f.status = 'accepted'

    LIMIT p_limit OFFSET p_offset;

END //

DELIMITER ;

-- 10. TEST VIEW

SELECT * FROM view_user_info;

SELECT * FROM view_post_statistics;

-- 11. TEST PROCEDURE

-- Test add user
CALL sp_add_user(
    'david',
    'david123',
    'david@gmail.com'
);

-- Test duplicate email
CALL sp_add_user(
    'test',
    '123',
    'alice@gmail.com'
);

-- Test create post
SET @new_post_id = 0;

CALL sp_create_post(
    1,
    'This is a new post',
    @new_post_id
);

SELECT @new_post_id;

-- Test get friends
CALL sp_get_friends(
    1,
    10,
    0
);

-- 12. TEST SOFT DELETE

UPDATE posts
SET is_deleted = TRUE
WHERE post_id = 1;

SELECT * FROM view_post_statistics;