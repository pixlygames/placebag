CREATE TABLE IF NOT EXISTS `placed_bags` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `item_type` VARCHAR(50) NOT NULL,
    `item_name` VARCHAR(50) NOT NULL,
    `item_amount` INT(11) NOT NULL,
    `coords` VARCHAR(255) NOT NULL,
    `placed_by` VARCHAR(50) NOT NULL,
    `placed_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
); 