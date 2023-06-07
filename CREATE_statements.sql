CREATE SCHEMA HEALTHCARE;
USE HEALTHCARE;

CREATE TABLE HOSPITAL(
	HOSP_ID INT PRIMARY KEY auto_increment,
    HOSP_NAME VARCHAR(20),
    HOSP_ADDRESS VARCHAR(50),
    HOSP_PHONE BIGINT(13)
);

CREATE TABLE DRUGS(
	DRUG_ID INT PRIMARY KEY auto_increment,
    DRUG_NAME VARCHAR(100),
    DRUGS_DISEASE_TREATED VARCHAR(100),
    METHOD_OF_ADMIN VARCHAR(100),
    DRUG_TYPE VARCHAR(100),
    DRUG_ACTIVE_INGREDIENT VARCHAR(100)
);

CREATE TABLE PHARMACY(
	PHARM_ID INT PRIMARY KEY auto_increment,
    PHARM_NAME VARCHAR(100),
    PHARM_ADDRESS VARCHAR(100)
);

CREATE TABLE INSURANCE(
	POL_ID INT PRIMARY KEY auto_increment,
    HOSP_ID INT,
    PHARM_ID INT,
    POL_NAME VARCHAR(100),
    POL_DURATION_MONTHS INT,
    FOREIGN KEY (HOSP_ID) REFERENCES HOSPITAL(HOSP_ID),
    FOREIGN KEY (PHARM_ID) REFERENCES PHARMACY(PHARM_ID)
);

CREATE TABLE PATIENT(
	PAT_ID INT PRIMARY KEY auto_increment,
    POL_ID INT,
    PAT_AGE INT,
    PAT_WT_LBS FLOAT,
    PAT_HT_INCHES FLOAT,
    PAT_BLOODGRP VARCHAR(4),
    FOREIGN KEY (POL_ID) REFERENCES INSURANCE(POL_ID)
);

CREATE TABLE PHYSICIAN(
	PHY_ID INT PRIMARY KEY auto_increment,
    PHY_FNAME VARCHAR(50),
    PHY_LNAME VARCHAR(50),
    PHY_SPECIALIZATION VARCHAR(100)
);

CREATE TABLE MANUFACTURER(
	MANUF_NAME VARCHAR(100) PRIMARY KEY,
    MANUF_ADDRESS VARCHAR(100)
);

CREATE TABLE FDA(
	DRUG_APP_ID INT PRIMARY KEY auto_increment,
    MANUF_NAME VARCHAR(100),
    PATENT_TYPE VARCHAR(100),
    DRUG_APP_TYPE VARCHAR(100),
    FOREIGN KEY (MANUF_NAME) REFERENCES MANUFACTURER(MANUF_NAME)
);

CREATE TABLE PRESCRIPTION(
	RX_ID INT PRIMARY KEY auto_increment,
    PHY_ID INT,
    PHARM_ID INT,
    PAT_ID INT,
    RX_DATE DATE,
    RX_SUBTOTAL FLOAT,
    RX_TAX FLOAT,
    FOREIGN KEY (PHY_ID) REFERENCES PHYSICIAN(PHY_ID),
    FOREIGN KEY (PHARM_ID) REFERENCES PHARMACY(PHARM_ID),
    FOREIGN KEY (PAT_ID) REFERENCES PATIENT(PAT_ID)
);

CREATE TABLE PRESCRIPTION_LINES(
	RX_LINE_ID INT PRIMARY KEY auto_increment,
    RX_ID INT,
    DRUG_ID INT,
    RX_LINE_PRICE FLOAT,
    RX_LINE_QUANTITY INT,
    FOREIGN KEY (DRUG_ID) REFERENCES DRUGS(DRUG_ID),
    FOREIGN KEY (RX_ID) REFERENCES PRESCRIPTION(RX_ID)
);

CREATE TABLE STORES(
	PHARM_ID INT,
    DRUG_ID INT,
    PRIMARY KEY(PHARM_ID, DRUG_ID),
    FOREIGN KEY (DRUG_ID) REFERENCES DRUGS(DRUG_ID),
    FOREIGN KEY (PHARM_ID) REFERENCES PHARMACY(PHARM_ID)
);

CREATE TABLE VISITS(
	PAT_ID INT,
    HOSP_ID INT,
    PRIMARY KEY(PAT_ID, HOSP_ID),
    FOREIGN KEY (PAT_ID) REFERENCES PATIENT(PAT_ID),
    FOREIGN KEY (HOSP_ID) REFERENCES HOSPITAL(HOSP_ID)
);

CREATE TABLE TREATS(
	PAT_ID INT,
    PHY_ID INT,
    PRIMARY KEY(PAT_ID, PHY_ID),
    FOREIGN KEY (PAT_ID) REFERENCES PATIENT(PAT_ID),
    FOREIGN KEY (PHY_ID) REFERENCES PHYSICIAN(PHY_ID)
);

CREATE TABLE EMPLOYS(
	HOSP_ID INT,
    PHY_ID INT,
    PRIMARY KEY(HOSP_ID, PHY_ID),
    FOREIGN KEY (HOSP_ID) REFERENCES HOSPITAL(HOSP_ID),
    FOREIGN KEY (PHY_ID) REFERENCES PHYSICIAN(PHY_ID)
);

CREATE TABLE DUR_PREMIUM(
	POL_ID INT PRIMARY KEY,
    POL_DURATION_MONTHS INT,
    POL_PREMIUM FLOAT,
    FOREIGN KEY (POL_ID) REFERENCES INSURANCE(POL_ID)
);

CREATE TABLE REGISTERS(
	PHARM_ID INT,
    RX_ID INT,
    PRIMARY KEY(RX_ID, PHARM_ID),
    FOREIGN KEY (RX_ID) REFERENCES PRESCRIPTION(RX_ID),
    FOREIGN KEY (PHARM_ID) REFERENCES PHARMACY(PHARM_ID)
);

CREATE TABLE SUBTOT_TAX_TOT(
	RX_ID INT PRIMARY KEY,
	RX_SUBTOTAL FLOAT,
    RX_TAX FLOAT,
    RX_TOTAL FLOAT,
    FOREIGN KEY (RX_ID) REFERENCES PRESCRIPTION(RX_ID)
);

CREATE TABLE PRICE_QUANT_TOTAL(
	RX_LINE_ID INT PRIMARY KEY,
    RX_LINE_PRICE FLOAT,
    RX_LINE_QUANTITY INT,
    RX_LINE_TOTAL FLOAT,
    FOREIGN KEY (RX_LINE_ID) REFERENCES PRESCRIPTION_LINES(RX_LINE_ID)
);

CREATE TABLE MAKES(
	DRUG_ID INT,
    MANUF_NAME VARCHAR(100),
    PRIMARY KEY(DRUG_ID, MANUF_NAME),
    FOREIGN KEY (DRUG_ID) REFERENCES DRUGS(DRUG_ID),
    FOREIGN KEY (MANUF_NAME) REFERENCES MANUFACTURER(MANUF_NAME)
);

DELIMITER ||
CREATE TRIGGER Pres_Trg AFTER INSERT ON PRESCRIPTION_LINES 
	FOR EACH ROW
	BEGIN 
		DECLARE rx_line_subtotal FLOAT;
        DECLARE rx_id_count INT;
        
        INSERT INTO PRICE_QUANT_TOTAL VALUES (NEW.RX_LINE_ID, NEW.RX_LINE_PRICE, NEW.RX_LINE_QUANTITY, NEW.RX_LINE_PRICE*NEW.RX_LINE_QUANTITY);
        
        SELECT SUM(B.RX_LINE_TOTAL) INTO rx_line_subtotal 
        FROM PRESCRIPTION_LINES AS A INNER JOIN PRICE_QUANT_TOTAL AS B ON A.RX_LINE_ID = B.RX_LINE_ID 
        WHERE A.RX_ID = NEW.RX_ID 
        GROUP BY A.RX_ID;
        
        UPDATE PRESCRIPTION SET RX_SUBTOTAL = rx_line_subtotal WHERE RX_ID = NEW.RX_ID;
        
        SELECT COUNT(*) INTO rx_id_count FROM SUBTOT_TAX_TOT as stt WHERE stt.RX_ID = new.RX_ID;
        
        IF rx_id_count>0 THEN
			UPDATE SUBTOT_TAX_TOT SET RX_SUBTOTAL = RX_SUBTOTAL + rx_line_subtotal WHERE RX_ID = new.RX_ID;
            UPDATE SUBTOT_TAX_TOT SET RX_TOTAL = RX_TOTAL + (1.0625*rx_line_subtotal) WHERE RX_ID = new.RX_ID;
        ELSE
			INSERT INTO SUBTOT_TAX_TOT VALUES (NEW.RX_ID, rx_line_subtotal, 6.25, 1.0625*rx_line_subtotal);
		END IF;
	END
||

