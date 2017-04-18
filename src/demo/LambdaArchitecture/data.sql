set foreign_key_checks=0; 

INSERT INTO `Machine` (pk, `Start`) VALUE (0, 0);

INSERT INTO `State` (pk, `Machine`, `name`) VALUE (0, 0, "Open");
INSERT INTO `State` (pk, `Machine`, `name`) VALUE (1, 0, "Closed");
INSERT INTO `State` (pk, `Machine`, `name`) VALUE (2, 0, "Locked");

set foreign_key_checks=1; 
