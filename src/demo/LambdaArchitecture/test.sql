set foreign_key_checks=0;

CREATE TABLE `Machine` (
  pk INT NOT NULL, PRIMARY KEY (pk),
  `start` INT NOT NULL, FOREIGN KEY (`start`) REFERENCES `State`(pk)
);
CREATE TABLE `State` (
  pk INT NOT NULL, PRIMARY KEY (pk),
  `machine` INT NOT NULL, FOREIGN KEY (`machine`) REFERENCES `Machine`(pk),
  `name` VARCHAR(255) NOT NULL 
);
CREATE TABLE `Trans` (
  pk INT NOT NULL, PRIMARY KEY (pk),
  `event` VARCHAR(255) NOT NULL ,
  `from` INT NOT NULL, FOREIGN KEY (`from`) REFERENCES `State`(pk),
  `to` INT NOT NULL, FOREIGN KEY (`to`) REFERENCES `State`(pk)
);

set foreign_key_checks=1
