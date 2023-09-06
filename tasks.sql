create database innowise;
use innowise;

CREATE TABLE Banks (
                       id BIGINT PRIMARY KEY AUTO_INCREMENT NOT NULL ,
                       name VARCHAR(255) NOT NULL
);

CREATE TABLE Cities (
                        id BIGINT PRIMARY KEY AUTO_INCREMENT NOT NULL ,
                        name VARCHAR(255) NOT NULL
);

CREATE TABLE Branches (
                          id BIGINT PRIMARY KEY AUTO_INCREMENT NOT NULL ,
                          bank_id BIGINT NOT NULL ,
                          city_id BIGINT NOT NULL ,
                          FOREIGN KEY (bank_id) REFERENCES Banks(id),
                          FOREIGN KEY (city_id) REFERENCES Cities(id)
);

CREATE TABLE SocialStatuses (
                                id BIGINT PRIMARY KEY AUTO_INCREMENT NOT NULL ,
                                name VARCHAR(255) NOT NULL
);

CREATE TABLE Clients (
                         id BIGINT PRIMARY KEY AUTO_INCREMENT NOT NULL ,
                         name VARCHAR(255) NOT NULL ,
                         social_status_id BIGINT NOT NULL ,
                         FOREIGN KEY (social_status_id) REFERENCES SocialStatuses(id)
);

CREATE TABLE Accounts (
                          id BIGINT PRIMARY KEY AUTO_INCREMENT NOT NULL ,
                          client_id BIGINT NOT NULL ,
                          balance DECIMAL(10, 2) NOT NULL ,
                          banks_id bigint NOT NULL ,
                          FOREIGN KEY (client_id) REFERENCES Clients(id),
                          FOREIGN KEY (banks_id) references Banks(id)

);

CREATE TABLE Cards (
                       id BIGINT PRIMARY KEY AUTO_INCREMENT NOT NULL ,
                       account_id BIGINT NOT NULL ,
                       balance DECIMAL(10, 2) NOT NULL ,
                       FOREIGN KEY (account_id) REFERENCES Accounts(id)
);


INSERT INTO Banks (id, name) VALUES
                                 (1, 'Беларусь банк'),
                                 (2, 'Альфа банк'),
                                 (3, 'Белагропромбанк'),
                                 (4, 'Газпромбанк'),
                                 (5, 'Приорбанк');

INSERT INTO Cities (id, name) VALUES
                                  (1, 'Гомель'),
                                  (2, 'Минск'),
                                  (3, 'Калинковичи'),
                                  (4, 'Речица'),
                                  (5, 'Могилев');

INSERT INTO Branches (id, bank_id, city_id) VALUES
                                                (1,1, 1),
                                                (2, 1, 2),
                                                (3, 2, 1),
                                                (4, 3, 2),
                                                (5, 4, 3);

INSERT INTO SocialStatuses (id, name) VALUES
                                            (1, 'Строитель'),
                                            (2, 'Бухгалтер'),
                                            (3, 'Программист'),
                                            (4, 'Экономист'),
                                            (5, 'Водитель');

INSERT INTO Clients (id, name, social_status_id) VALUES
                                                              (1, 'Жулего',  5),
                                                              (2, 'Петров',  2),
                                                              (3, 'Иванов',  3),
                                                              (4, 'Даниленко', 4),
                                                              (5, 'Китов', 5);

INSERT INTO Accounts (id, client_id, balance, banks_id) VALUES
                                                  (1, 1, 1000, 1),
                                                  (2, 2, 500, 3),
                                                  (3, 3, 1500, 2),
                                                  (4, 4, 2000, 4),
                                                  (5, 5, 2500, 5);

INSERT INTO Cards (id, account_id, balance) VALUES
                                                (1, 1, 200),
                                                (2, 2, 300),
                                                (3, 3, 400),
                                                (4, 4, 100),
                                                (5, 5, 500),
                                                (6, 1, 700);



#2 task

select ban.* from banks ban
    inner join branches branch on ban.id = branch.bank_id
    inner join Cities city on branch.city_id = city.id
             where city.name = 'Гомель';

#3 task


select card.id, card.balance, client.name, bank.name from Cards card
    inner join Accounts account on card.account_id = account.id
    inner join Banks bank on account.banks_id = bank.id
    inner join Clients client on account.client_id = client.id;


#4 task

SELECT account.id,account.balance - ((SELECT SUM(c.balance) FROM Cards c WHERE c.account_id = account.id) ) FROM Clients client
INNER JOIN Accounts account ON client.id = account.client_id where account.balance <> ((SELECT SUM(card.balance) FROM Cards card WHERE card.account_id = account.id) );

# без подзапроса

SELECT social.name AS social_status, COUNT(card.id) AS card_count
FROM SocialStatuses social
INNER JOIN Clients cl ON social.id = cl.social_status_id
INNER JOIN Accounts account ON cl.id = account.client_id
INNER JOIN Cards card ON account.id = card.account_id
GROUP BY social.name;

# с подзапросом
SELECT social.name AS social_status, (
    SELECT COUNT(card.id)
    FROM Clients cl
    INNER JOIN Accounts account ON cl.id = account.client_id
    INNER JOIN Cards card ON account.id = card.account_id
    WHERE cl.social_status_id = social.id
) AS card_count
FROM SocialStatuses social;



#7 task

SELECT client.name,account.balance - ((SELECT SUM(cards.balance) FROM Cards cards WHERE cards.account_id = account.id) ) FROM Clients client
INNER JOIN Accounts account ON client.id = account.client_id;


#6 task

CREATE PROCEDURE stored_procedure(statusId BIGINT)
begin
    IF EXISTS(SELECT * from SocialStatuses WHERE id = statusId) THEN
        IF EXISTS(SELECT * FROM Clients WHERE social_status_id = statusId) THEN
            UPDATE accounts,clients,socialstatuses SET accounts.balance = accounts.balance + 10 WHERE Clients.social_status_id = statusId and Clients.id = Accounts.client_id;
        ELSE
            SELECT ('Нет аккаунтов с этим соц статусом');
            ROLLBACK;
        end if;
    ELSE
        SELECT ('Введён некорректный номер соц. статуса');
        ROLLBACK;
    end if;
end;

#8 task


CREATE PROCEDURE transfer(cardId BIGINT,sum DECIMAL(10,2))
    BEGIN
        DECLARE _balance DECIMAL(10,2);

        START TRANSACTION;

        SET _balance = (SELECT Account.balance - ((SELECT SUM(cards.balance) FROM Cards cards WHERE cards.account_id = account.id) ) FROM Clients client
            INNER JOIN Accounts account ON client.id = account.client_id
            INNER JOIN Cards cards on account.id = cards.account_id
                WHERE cards.id = cardId);

        IF _balance>0 THEN
            UPDATE Cards SET balance = balance + sum WHERE Cards.id = cardId;
        end if;

        commit ;
    end;


#9 task

#Account Trigger
CREATE TRIGGER Account_Trigger
    AFTER UPDATE ON Accounts
    FOR EACH ROW
    BEGIN
        IF NOT NEW.balance>((SELECT SUM(cards.balance) FROM Cards cards INNER JOIN accounts account ON cards.account_id = account.id WHERE cards.account_id = NEW.id) ) THEN
            SIGNAL sqlstate '45000' set message_text = 'Сумма на балансе счёта меньше суммы денег на всех картах';
        end if;
    end;

#Cards Trigger
CREATE TRIGGER Cards_Trigger
    AFTER UPDATE ON Cards
    FOR EACH ROW
    BEGIN
        IF ((SELECT SUM(cards.balance) + NEW.balance - OLD.balance FROM Cards cards inner join accounts account on cards.account_id = account.id WHERE cards.account_id = NEW.account_id))
               > (SELECT account.balance from accounts account WHERE account.id = NEW.account_id) THEN
            SIGNAL sqlstate '45000' set message_text = 'Сумма картах больше чем количество денег на счету';
        end if;
    end;


