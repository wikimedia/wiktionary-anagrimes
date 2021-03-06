DROP TABLE IF EXISTS articles_temp, mots_temp, langues_temp ;
SELECT '- Potential temporary tables dropped' AS '' ;

CREATE TABLE articles_temp LIKE articles;
SELECT '- Filling the temporary ARTICLES table...' AS '' ;
LOAD /* SLOW_OK */ DATA LOCAL INFILE '/mnt/user-store/Wiktionnaire/anagrimes/tables/current_articles.csv'
INTO TABLE articles_temp FIELDS
        TERMINATED BY ','
        ENCLOSED BY '"' LINES
        TERMINATED BY '\n'
(titre, r_titre, titre_plat, r_titre_plat, transcrit_plat, r_transcrit_plat, anagramme_id);

CREATE TABLE mots_temp LIKE mots;
SELECT '- Filling the temporary MOTS table...' AS '' ;
LOAD /* SLOW_OK */ DATA LOCAL INFILE '/mnt/user-store/Wiktionnaire/anagrimes/tables/current_mots.csv'
INTO TABLE mots_temp FIELDS
	TERMINATED BY ','
	ENCLOSED BY '"' LINES
	TERMINATED BY '\n'
(titre, langue, type, pron, pron_simple, r_pron_simple, rime_pauvre, rime_suffisante, rime_riche, rime_voyelle, syllabes, num, flex, loc, gent, rand);

SELECT '- Filling the temporary LANGUES table...' AS '' ;
CREATE TABLE langues_temp LIKE langues;
LOAD DATA LOCAL INFILE '/mnt/user-store/Wiktionnaire/anagrimes/tables/current_langues.csv'
INTO TABLE langues_temp FIELDS
	TERMINATED BY ','
	ENCLOSED BY '"' LINES
	TERMINATED BY '\n'
(langue,num,num_min);

SELECT 'TABLES IMPORTED IN TEMP' AS '' ;
