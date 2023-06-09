CREATE TABLE ALUNO (
ID_ALUNO SERIAL PRIMARY KEY NOT NULL,
NOME VARCHAR(50) NOT NULL,
CPF VARCHAR(11) NOT NULL,
FONE VARCHAR(20),
DT_NASC DATE NOT NULL);

CREATE TABLE CURSO (
ID_CURSO SERIAL PRIMARY KEY NOT NULL,
NOME VARCHAR(50) NOT NULL,
DESCR VARCHAR(500),
CG_HORARIA INT NOT NULL);

CREATE TABLE MATRICULA (
ID_MAT SERIAL PRIMARY KEY NOT NULL,
ID_ALUNO INT NOT NULL,
ID_CURSO INT NOT NULL,
DT_MAT DATE NOT NULL,
FOREIGN KEY (ID_ALUNO) REFERENCES ALUNO (ID_ALUNO),
FOREIGN KEY (ID_CURSO) REFERENCES CURSO (ID_CURSO));

CREATE TABLE PAGAMENTO (
ID_PAG SERIAL PRIMARY KEY NOT NULL,
DT_PAG DATE NOT NULL,
ID_MAT INT NOT NULL,
VALOR_PAGO FLOAT NOT NULL,
FOREIGN KEY (ID_MAT) REFERENCES MATRICULA (ID_MAT));

CREATE TABLE PROFESSOR (
ID_PROF SERIAL PRIMARY KEY NOT NULL,
NOME VARCHAR(50) NOT NULL,
FONE VARCHAR(20),
CPF VARCHAR(11) NOT NULL);

CREATE TABLE DISCIPLINA (
ID_DISC SERIAL PRIMARY KEY NOT NULL,
NOME VARCHAR(50) NOT NULL,
CG_HORARIA INT NOT NULL,
ID_CURSO INT NOT NULL,
FOREIGN KEY (ID_CURSO) REFERENCES CURSO (ID_CURSO));

CREATE TABLE PRE_REQ (
ID_PRE_REQ SERIAL PRIMARY KEY NOT NULL,
ID_DISC INT NOT NULL,
ID_DISC_PRE INT,
FOREIGN KEY (ID_DISC) REFERENCES DISCIPLINA (ID_DISC),
FOREIGN KEY (ID_DISC_PRE) REFERENCES DISCIPLINA (ID_DISC));

CREATE TABLE TURMA (
ID_TURMA SERIAL PRIMARY KEY NOT NULL,
ID_DISC INT NOT NULL,
ID_PROF INT NOT NULL,
PERIODO INT NOT NULL,
ANO INT NOT NULL,
FOREIGN KEY (ID_DISC) REFERENCES DISCIPLINA (ID_DISC),
FOREIGN KEY (ID_PROF) REFERENCES PROFESSOR (ID_PROF));

CREATE TABLE AVALIACAO (
ID_AVA SERIAL PRIMARY KEY NOT NULL,
ID_TURMA INT NOT NULL,
NOME VARCHAR(50) NOT NULL,
PESO REAL NOT NULL,
FOREIGN KEY (ID_TURMA) REFERENCES TURMA (ID_TURMA));

CREATE TABLE MAT_TURMA (
ID_MAT_TURMA SERIAL PRIMARY KEY NOT NULL,
ID_MAT INT NOT NULL,
ID_TURMA INT NOT NULL,
SITUACAO CHAR(1) NOT NULL,
FOREIGN KEY (ID_MAT) REFERENCES MATRICULA (ID_MAT),
FOREIGN KEY (ID_TURMA) REFERENCES TURMA (ID_TURMA));

CREATE TABLE NOTA (
ID_NOTA SERIAL PRIMARY KEY NOT NULL,
ID_AVA INT NOT NULL,
ID_MAT_TURMA INT NOT NULL,
VALOR_NOT REAL NOT NULL,
FOREIGN KEY (ID_AVA) REFERENCES AVALIACAO (ID_AVA),
FOREIGN KEY (ID_MAT_TURMA) REFERENCES MAT_TURMA (ID_MAT_TURMA));

CREATE TABLE FALTA (
ID_FALTA SERIAL PRIMARY KEY NOT NULL,
ID_MAT_TURMA INT NOT NULL,
ID_TURMA INT NOT NULL,
DT_FALTA DATE NOT NULL,
FOREIGN KEY (ID_MAT_TURMA) REFERENCES MAT_TURMA (ID_MAT_TURMA),
FOREIGN KEY (ID_TURMA) REFERENCES TURMA (ID_TURMA));

























