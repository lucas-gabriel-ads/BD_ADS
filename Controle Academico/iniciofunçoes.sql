--FUNÇÃO CADASTRAR MAIN
CREATE OR REPLACE FUNCTION CADASTRAR(TABELA TEXT, P1 VARCHAR(50) DEFAULT NULL, P2 VARCHAR(50) DEFAULT NULL, P3 VARCHAR(50) DEFAULT NULL, P4 VARCHAR(50) DEFAULT NULL)
RETURNS VOID AS $$
BEGIN
	IF TABELA ILIKE 'ALUNO' THEN
		EXECUTE FORMAT('SELECT CAD_ALUNO(%L, %L, %L, %L)', P1, P2, P3, CAST(P4 AS DATE));
	ELSEIF TABELA ILIKE 'PROFESSOR' THEN
		EXECUTE FORMAT('SELECT CAD_PROFESSOR(%L, %L, %L)', P1, P2, P3);
	ELSEIF TABELA ILIKE 'DISCIPLINA' THEN
		EXECUTE FORMAT('SELECT CAD_DISCIPLINA(%L, %L, %L, %L)', P1, CAST(P2 AS INT), CAST(P3 AS INT), CAST(P4 AS INT));
	ELSEIF TABELA ILIKE 'PAGAMENTO' THEN
		EXECUTE FORMAT('SELECT CAD_PAG(%L, %L, %L)', CAST(P1 AS INT), CAST(P2 AS REAL), CAST(P3 AS INT));
	ELSEIF TABELA ILIKE 'MATRICULA' THEN
		EXECUTE FORMAT('SELECT CAD_MATRICULA(%L, %L)', CAST(P1 AS INT), CAST(P2 AS REAL));
	ELSEIF TABELA ILIKE 'MAT_TURMA' THEN
		EXECUTE FORMAT('SELECT CAD_MAT_TURMA(%L, %L)', CAST(P1 AS INT), CAST(P2 AS REAL));
	ELSEIF TABELA ILIKE 'TURMA' THEN
		EXECUTE FORMAT('SELECT CAD_TURMA(%L, %L, %L, %L)', CAST(P1 AS INT), CAST(P2 AS INT), CAST(P3 AS INT), CAST(P4 AS INT));
	ELSEIF TABELA ILIKE 'CURSO' THEN
		EXECUTE FORMAT('SELECT CAD_CURSO(%L, %L, %L)', P1, P2, CAST(P3 AS INT));
	ELSE
		RAISE EXCEPTION 'TABELA NÃO ENCONTRADA';
	END IF;	
END;
$$ LANGUAGE PLPGSQL;

===========================================================================================================
--FUNÇAÕ CAD_PROFESSOR
CREATE OR REPLACE FUNCTION CAD_PROFESSOR(NAME VARCHAR(50), FONE VARCHAR(25), CPF VARCHAR(11))
RETURNS VOID AS $$
BEGIN
	INSERT INTO PROFESSOR VALUES (DEFAULT, NAME, FONE, CPF);
END;
$$ LANGUAGE PLPGSQL;

===========================================================================================================
--FUNÇÃO CAD_ALUNO
CREATE OR REPLACE FUNCTION CAD_ALUNO(NAME VARCHAR(50), CPF VARCHAR(11), FONE VARCHAR(15), DT_NASC DATE)
RETURNS VOID AS $$
BEGIN
	INSERT INTO ALUNO VALUES (DEFAULT, NAME, CPF, FONE, DT_NASC);
END;
$$ LANGUAGE PLPGSQL;

===========================================================================================================
--FUNÇÃO CAD_DISCIPLINA
CREATE OR REPLACE FUNCTION CAD_DISCIPLINA(NAME VARCHAR(20), CH INT, IDCURSO INT, ID_PRER INT DEFAULT NULL)
RETURNS VOID AS
$$
DECLARE
ID_DISC INT;
BEGIN
	IF EXISTS(SELECT ID_CURSO FROM CURSO C WHERE C.ID_CURSO = IDCURSO) THEN
		IF ID_PRER IS NULL THEN
			INSERT INTO DISCIPLINA VALUES (DEFAULT, NAME, CH, IDCURSO);
		ELSE
			IF EXISTS(SELECT D.ID_DISC FROM DISCIPLINA D WHERE D.ID_DISC = ID_PRER) THEN
				INSERT INTO DISCIPLINA VALUES (DEFAULT, NAME, CH, IDCURSO);
				ID_DISC = (SELECT D.ID_DISC FROM DISCIPLINA D WHERE D.NOME ILIKE NAME);
				INSERT INTO PRE_REQ VALUES (DEFAULT, ID_DISC, ID_PRER);
			ELSE
				RAISE EXCEPTION 'DISCIPLINA PRÉ-REQUISITO DE ID % NÃO EXISTENTE!', ID_PRER;
			END IF;
		END IF;
	ELSE
		RAISE EXCEPTION 'CURSO DE ID % NÃO EXISTE', IDCURSO;
	END IF;
END;
$$ LANGUAGE PLPGSQL;

===========================================================================================================
--FUNÇÃO CAD_PAG
CREATE OR REPLACE FUNCTION CAD_PAG(ID_MATRICULA INT, VALOR REAL, COMPETENCIA INT)
RETURNS VOID AS
$$
BEGIN
	IF (COMPETENCIA < 1 OR COMPETENCIA > 12) THEN
		RAISE EXCEPTION 'INSERIR COMPETENCIA ENTRE 1 E 12';
	END IF;
	IF (VALOR < 0) THEN
		RAISE EXCEPTION 'VALOR NÃO PODE SER NEGATIVO';
	END IF;
	IF EXISTS(SELECT * FROM PAGAMENTO P WHERE P.ID_MAT=ID_MATRICULA AND P.COMPET=COMPETENCIA) THEN
		RAISE EXCEPTION 'ALUNO JÁ EFETUOU O PAGAMENTO PARA A COMPETENCIA DO MES INFORMADO';
	END IF;
	IF NOT EXISTS(SELECT * FROM MATRICULA M WHERE M.ID_MAT=ID_MATRICULA) THEN
		RAISE EXCEPTION 'MATRICULA NÃO ENCONTRADA';
	END IF;
	INSERT INTO PAGAMENTO VALUES (DEFAULT, CURRENT_DATE, ID_MATRICULA, COMPETENCIA, VALOR);
END;
$$ LANGUAGE PLPGSQL;

===========================================================================================================
--FUNÇÃO CAD_MATRICULA
CREATE OR REPLACE FUNCTION CAD_MATRICULA(IDALUNO INT, IDCURSO INT)
RETURNS VOID AS
$$
BEGIN
	IF NOT EXISTS(SELECT * FROM ALUNO A WHERE A.ID_ALUNO = IDALUNO) THEN
		RAISE EXCEPTION 'ALUNO DE ID % NÃO EXISTE', IDALUNO;
	END IF;
	IF NOT EXISTS(SELECT * FROM CURSO C WHERE C.ID_CURSO = IDCURSO) THEN
		RAISE EXCEPTION 'CURSO DE ID % NÃO EXISTE', IDCURSO;
	END IF;
	IF EXISTS(SELECT * FROM MATRICULA M WHERE M.ID_ALUNO = IDALUNO AND M.ID_CURSO = IDCURSO) THEN
		RAISE EXCEPTION 'ALUNO JÁ MATRICULADO NO CURSO';
	END IF;
	INSERT INTO MATRICULA VALUES (DEFAULT, IDALUNO, IDCURSO, CURRENT_DATE);
END;
$$ LANGUAGE PLPGSQL;

===========================================================================================================
--FUNÇÃO CAD_MAT_TURMA
CREATE OR REPLACE FUNCTION CAD_MAT_TURMA(ID_MAT_ACAD INT, ID_TUR INT)
RETURNS VOID AS
$$
DECLARE
ID_DIS_TUR INT;
DIS_PRE INT;
ID_CUR INT;
BEGIN
	ID_DIS_TUR = (SELECT T.ID_DISC FROM TURMA T WHERE T.ID_TURMA = ID_TUR);
	ID_CUR = (SELECT D.ID_CURSO FROM DISCIPLINA D WHERE D.ID_DISC=ID_DIS_TUR);
	IF ((SELECT M.ID_CURSO FROM MATRICULA M WHERE M.ID_MAT = ID_MAT_ACAD) <> ID_CUR) THEN
		RAISE EXCEPTION 'A DISCIPLINA DESSA TURMA NÃO PERTENCE A GRADE DE DISCIPLINAS DO CURSO EM QUE O ALUNO ESTA MATRICULADO!';
	END IF;
	IF EXISTS(SELECT * FROM MAT_TURMA MT JOIN TURMA T ON MT.ID_TURMA=T.ID_TURMA WHERE MT.ID_MAT=ID_MAT_ACAD AND T.ID_DISC = ID_DIS_TUR AND MT.SITUACAO ILIKE 'C') THEN
		RAISE EXCEPTION 'ALUNO JÁ CURSANDO ESSA DISCIPLINA!';
	END IF;
	IF EXISTS(SELECT * FROM MAT_TURMA MT JOIN TURMA T ON MT.ID_TURMA=T.ID_TURMA WHERE MT.ID_MAT=ID_MAT_ACAD AND T.ID_DISC = ID_DIS_TUR AND MT.SITUACAO ILIKE 'A') THEN
		RAISE EXCEPTION 'ALUNO JÁ APROVADO NESSA DISCIPLINA!';
	END IF;
	IF EXISTS(SELECT * FROM PRE_REQ PR WHERE PR.ID_DISC = ID_DIS_TUR) THEN
		DIS_PRE = (SELECT ID_DISC_PRE FROM PRE_REQ PR WHERE PR.ID_DISC = ID_DIS_TUR);
		IF EXISTS(SELECT MT.ID_TURMA FROM MAT_TURMA MT JOIN TURMA T ON MT.ID_TURMA = T.ID_TURMA WHERE T.ID_DISC = DIS_PRE AND MT.ID_MAT = ID_MAT_ACAD AND MT.SITUACAO ILIKE 'A') THEN
			INSERT INTO MAT_TURMA VALUES (DEFAULT, ID_MAT_ACAD, ID_TUR, 'C');
		ELSEIF EXISTS(SELECT MT.ID_TURMA FROM MAT_TURMA MT JOIN TURMA T ON MT.ID_TURMA = T.ID_TURMA WHERE T.ID_DISC = DIS_PRE AND MT.ID_MAT = ID_MAT_ACAD AND MT.SITUACAO ILIKE 'C') THEN
			RAISE EXCEPTION 'ALUNO NAO PODE SE MATRICULAR NA TURMA POIS ESTA CURSANDO UMA TURMA DA DISCIPLINA PRE-REQUISITO';
		ELSE
			RAISE EXCEPTION 'O ALUNO PRECISA ESTAR APROVADO NA MATÉRIA PRE-REQUISITO(ID: %)', DIS_PRE;
		END IF;
	ELSE
		INSERT INTO MAT_TURMA VALUES (DEFAULT, ID_MAT_ACAD, ID_TUR, 'C');
	END IF;		
END;
$$ LANGUAGE PLPGSQL;

===========================================================================================================
--FUNÇÃO CAD_TURMA
CREATE OR REPLACE FUNCTION CAD_TURMA(IDDISC INT, IDPROF INT, PERI INT, ANO INT)
RETURNS VOID AS
$$
BEGIN
	IF NOT EXISTS(SELECT * FROM DISCIPLINA D WHERE D.ID_DISC = IDDISC) THEN
		RAISE EXCEPTION 'DISCIPLINA DE ID % NÃO EXISTE', IDDISC;
	END IF;
	IF NOT EXISTS(SELECT * FROM PROFESSOR P WHERE P.ID_PROF = IDPROF) THEN
		RAISE EXCEPTION 'PROFESSOR DE ID % NÃO EXISTE', IDPROF;
	END IF;
	INSERT INTO TURMA VALUES (DEFAULT, IDDISC, IDPROF, PERI, ANO, 'A');
END;
$$ LANGUAGE PLPGSQL;

===========================================================================================================
--FUNÇÃO CAD_CURSO
CREATE OR REPLACE FUNCTION CAD_CURSO(NAME VARCHAR(30), DESCR VARCHAR(50), CH INT)
RETURNS VOID AS
$$
BEGIN
	IF EXISTS(SELECT * FROM CURSO C WHERE C.NOME ILIKE NAME) THEN
		RAISE EXCEPTION 'JÁ EXISTE UM CURSO CADASTRADO COM ESSE NOME';
	END IF;
	INSERT INTO CURSO VALUES(DEFAULT, NAME, DESCR, CH);
END;
$$ LANGUAGE PLPGSQL;

===========================================================================================================
--funcao consultar notas do aluno
CREATE OR REPLACE FUNCTION CONSULTAR_NOTAS(MAT_TUR INT)
RETURNS TABLE (DISCIPLINA VARCHAR(50), NOME VARCHAR(50), PESO REAL, NOTA REAL)
AS $$
BEGIN
	IF NOT EXISTS(SELECT * FROM MAT_TURMA MT WHERE MT.ID_MAT_TURMA=MAT_TUR) THEN
		RAISE EXCEPTION 'ALUNO NÃO ENCONTRADO!';
	END IF;
	RETURN QUERY
	(SELECT D.NOME, AVA.NOME, AVA.PESO, N.VALOR_NOT AS NOTA
	 FROM NOTA N 
	 JOIN AVALIACAO AVA ON AVA.ID_AVA=N.ID_AVA 
	 JOIN TURMA T ON AVA.ID_TURMA=T.ID_TURMA 
	 JOIN DISCIPLINA D ON T.ID_DISC=D.ID_DISC 
	 WHERE N.ID_MAT_TURMA=MAT_TUR);
END;
$$ LANGUAGE PLPGSQL;
DROP FUNCTION CONSULTAR_NOTAS;

===========================================================================================================
--trigger reprovar por falta
CREATE OR REPLACE FUNCTION REP_FALTA()
RETURNS TRIGGER
AS $$
DECLARE
SUM_FALTAS INT;
CH_DISC INT;
BEGIN
	SUM_FALTAS = (SELECT SUM(F.QTD_FALTAS) FROM FALTA F WHERE F.ID_MAT_TURMA=NEW.ID_MAT_TURMA);
	CH_DISC = (SELECT D.CG_HORARIA FROM DISCIPLINA D 
			   JOIN TURMA T ON D.ID_DISC=T.ID_DISC
			   JOIN MAT_TURMA MT ON T.ID_TURMA=MT.ID_TURMA WHERE MT.ID_MAT_TURMA=NEW.ID_MAT_TURMA);
	IF (SUM_FALTAS >= (CH_DISC * 0.25)) THEN
		UPDATE MAT_TURMA AS MT
		SET SITUACAO='R'
		WHERE MT.ID_MAT_TURMA=NEW.ID_MAT_TURMA;
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE PLPGSQL;

DROP TRIGGER T_REP_FALTA ON FALTA
CREATE TRIGGER T_REP_FALTA AFTER INSERT ON FALTA FOR EACH ROW EXECUTE PROCEDURE REP_FALTA();

=============================================================================================================
--FUNÇÃO ALTERAR PROFESOR DE UMA TURMA
CREATE OR REPLACE FUNCTION MUDAR_PROFESSOR(IDTURMA INT, IDNEWPROF INT)
RETURNS VOID
AS $$
BEGIN
	IF NOT EXISTS(SELECT * FROM PROFESSOR P WHERE P.ID_PROF = IDNEWPROF) THEN
		RAISE EXCEPTION 'NOVO PROFESSOR INFORMADO NÃO EXISTE';
	END IF;
	IF (SELECT T.ID_PROF FROM TURMA T WHERE T.ID_TURMA=IDTURMA)=IDNEWPROF THEN
		RAISE EXCEPTION 'ESSE PROFESSOR JÁ MINISTRA AULA PARA ESSA TURMA';
	END IF;
	IF NOT EXISTS(SELECT * FROM TURMA T WHERE T.ID_TURMA = IDTURMA) THEN
		RAISE EXCEPTION 'TURMA NÃO EXISTE';
	END IF;
	UPDATE TURMA
	SET ID_PROF = IDNEWPROF
	WHERE ID_TURMA = IDTURMA;
END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION DEL_PROFESSOR(IDPROF INT, IDNEWPROF INT DEFAULT NULL)
RETURNS VOID
AS $$
BEGIN
	IF NOT EXISTS(SELECT * FROM PROFESSOR P WHERE P.ID_PROF = IDPROF) THEN
		RAISE EXCEPTION 'PROFESSOR INFORMADO NÃO EXISTE';
	END IF;
	IF EXISTS (SELECT * FROM TURMA T WHERE T.ID_PROF=IDPROF) THEN
		IF IDNEWPROF IS NULL THEN
			RAISE EXCEPTION 'IMPOSSIVEL DELETAR O PROFESSOR POIS EXISTE(M) TURMA(S) ATUALMENTE MINISTRADAS POR ELE. INFORME O ID PARA UM PROFESSOR SUBSTITUTO.';
		END IF;
		IF NOT EXISTS(SELECT * FROM PROFESSOR P WHERE P.ID_PROF = IDNEWPROF) THEN
			RAISE EXCEPTION 'PROFESSOR INFORMADO NÃO EXISTE';
		END IF;
		UPDATE TURMA
		SET ID_PROF = IDNEWPROF
		WHERE ID_PROF=IDPROF;
		DELETE FROM PROFESSOR WHERE ID_PROF=IDPROF;
	ELSE
		DELETE FROM PROFESSOR WHERE ID_PROF=IDPROF;
	END IF;
END;
$$ LANGUAGE PLPGSQL;

=============================================================================================================

--FUNÇÃO CAD_AVA
CREATE OR REPLACE FUNCTION CAD_AVA(IDTURMA INT, NOMEAVA VARCHAR(20), PESOAVA REAL)
RETURNS VOID
AS $$
BEGIN
	IF (SELECT SITUACAO FROM TURMA WHERE ID_TURMA=IDTURMA) ILIKE 'E' THEN
		RAISE EXCEPTION 'IMPOSSIVEL CRIAR AVALIAÇÕES PARA UMA TURMA COM STATUS ENCERRADA';
	END IF;
	IF NOT EXISTS(SELECT * FROM TURMA T WHERE T.ID_TURMA = IDTURMA) THEN
		RAISE EXCEPTION 'TURMA NÃO EXISTE';
	END IF;
	IF PESOAVA <= 0 THEN
		RAISE EXCEPTION 'PESO NÃO PODE SER MENOR OU IGUAL A 0';
	END IF;
	INSERT INTO AVALIACAO VALUES (DEFAULT, IDTURMA, NOMEAVA, PESOAVA);
END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION VALIDA_PESO()
RETURNS TRIGGER
AS $$
DECLARE
SUM_PESOS REAL;
BEGIN
	SUM_PESOS = (SELECT SUM(PESO) FROM AVALIACAO WHERE ID_TURMA=NEW.ID_TURMA);
	IF (SUM_PESOS) > 10 THEN
		RAISE EXCEPTION 'A SOMA DOS PESOS TOTAL DAS AVALIAÇÕES NÃO PODE SER MAIOR QUE 10';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE PLPGSQL;

CREATE TRIGGER T_VALIDA_PESO AFTER INSERT OR UPDATE ON AVALIACAO FOR EACH ROW EXECUTE PROCEDURE VALIDA_PESO();

=============================================================================================================
--FUNCAO CAD_NOTA
CREATE OR REPLACE FUNCTION CAD_NOTA(IDAVA INT, IDMATTURMA INT, V_NOTA REAL)
RETURNS VOID
AS $$
DECLARE
ID_TURMA_AVA INT;
BEGIN
	IF V_NOTA < 0 THEN
		RAISE EXCEPTION 'NOTA NÃO PODE SER MENOR QUE 0';
	END IF;
	IF NOT EXISTS(SELECT * FROM MAT_TURMA MT WHERE MT.ID_MAT_TURMA = IDMATTURMA) THEN
		RAISE EXCEPTION 'MATRICULA NA TURMA NÃO EXISTE';
	END IF;
	IF NOT EXISTS(SELECT * FROM AVALIACAO A WHERE A.ID_AVA = IDAVA) THEN
		RAISE EXCEPTION 'AVALIAÇÃO NÃO EXISTE';
	END IF;
	ID_TURMA_AVA = (SELECT A.ID_TURMA FROM AVALIACAO A WHERE A.ID_AVA=IDAVA);
	IF ID_TURMA_AVA = (SELECT MT.ID_TURMA FROM MAT_TURMA MT WHERE MT.ID_MAT_TURMA=IDMATTURMA) THEN
		IF EXISTS (SELECT * FROM NOTA N WHERE N.ID_MAT_TURMA = IDMATTURMA AND N.ID_AVA=IDAVA) THEN
			UPDATE NOTA 
			SET VALOR_NOT = V_NOTA
			WHERE ID_MAT_TURMA = IDMATTURMA AND ID_AVA = IDAVA;
		ELSE
			INSERT INTO NOTA VALUES (DEFAULT, IDAVA, IDMATTURMA, V_NOTA);
		END IF;
	ELSE
		RAISE EXCEPTION 'O ID DE MATRICULA DO ALUNO INFORMADO NÃO ESTA MATRICULADO NA TURMA NA QUAL FOI REALIZADA A AVALIAÇÃO INFORMADA!';
	END IF;
END;
$$ LANGUAGE PLPGSQL;
=============================================================================================================

--FUNÇÃO CAD_FALTA
CREATE OR REPLACE FUNCTION CAD_FALTA(IDMATTURMA INT, IDTURMA INT, QTDFALTA INT)
RETURNS VOID
AS $$
BEGIN
	IF NOT EXISTS(SELECT * FROM MAT_TURMA MT WHERE MT.ID_MAT_TURMA = IDMATTURMA) THEN
		RAISE EXCEPTION 'MATRICULA NA TURMA NÃO EXISTE';
	END IF;
	IF NOT EXISTS(SELECT * FROM TURMA T WHERE T.ID_TURMA = IDTURMA) THEN
		RAISE EXCEPTION 'TURMA NÃO EXISTE';
	END IF;
	IF (SELECT MT.ID_TURMA FROM MAT_TURMA MT WHERE MT.ID_MAT_TURMA=IDMATTURMA) <> IDTURMA THEN
		RAISE EXCEPTION 'O ID DE MATRICULA DO ALUNO INFORMADO NÃO ESTA MATRICULADO NA TURMA INFORMADA!';
	END IF;
	IF QTDFALTA < 0 THEN
		RAISE EXCEPTION 'QUANTIDADE DE FALTAS NÃO PODE SER MENOR QUE 0';
	END IF;
	INSERT INTO FALTA VALUES (DEFAULT, IDMATTURMA, IDTURMA, QTDFALTA, CURRENT_DATE);

END;
$$ LANGUAGE PLPGSQL;

SELECT CAD_FALTA(4, 1, 2)
=============================================================================================================
--FUNÇÃO CADASTRAR MAIN2
CREATE OR REPLACE FUNCTION CADASTRAR_MAIN(TABELA TEXT, P1 VARCHAR(50) DEFAULT NULL, P2 VARCHAR(50) DEFAULT NULL, P3 VARCHAR(50) DEFAULT NULL, P4 VARCHAR(50) DEFAULT NULL)
RETURNS VOID AS $$
BEGIN
	IF TABELA ILIKE 'AVALIACAO' THEN
		EXECUTE FORMAT('SELECT CAD_AVA(%L, %L, %L)', CAST(P1 AS INT), P2, CAST(P3 AS REAL));
	ELSEIF TABELA ILIKE 'NOTA' THEN
		EXECUTE FORMAT('SELECT CAD_NOTA(%L, %L, %L)', CAST(P1 AS INT), CAST(P2 AS INT), CAST(P3 AS REAL));
	ELSEIF TABELA ILIKE 'FALTA' THEN
		EXECUTE FORMAT('SELECT CAD_FALTA(%L, %L, %L)', CAST(P1 AS INT), CAST(P2 AS INT), CAST(P3 AS INT));
	ELSE
		RAISE EXCEPTION 'TABELA NÃO ENCONTRADA';
	END IF;	
END;
$$ LANGUAGE PLPGSQL;

=============================================================================================================
--FUNÇÃO ENC_TURMA
CREATE OR REPLACE FUNCTION ENC_TURMA(IDTURMA INT)
RETURNS VOID AS $$
BEGIN
	IF NOT EXISTS(SELECT * FROM TURMA T WHERE T.ID_TURMA = IDTURMA) THEN
		RAISE EXCEPTION 'TURMA NÃO EXISTE';
	END IF;
	IF (SELECT SUM(PESO) FROM AVALIACAO WHERE ID_TURMA=IDTURMA)<10 THEN
		RAISE EXCEPTION 'NÃO PODE SER ENCERRADA A TURMA POIS A SOMA DOS PESOS DAS AVALIAÇÕES APLICADAS É MENOR QUE 10';
	END IF;
	UPDATE TURMA
	SET SITUACAO = 'E'
	WHERE ID_TURMA = IDTURMA;
END;
$$ LANGUAGE PLPGSQL;



CREATE OR REPLACE FUNCTION CALC_MEDIA_FIM()
RETURNS TRIGGER
AS $$
DECLARE
    ALUNO_ROW RECORD;
BEGIN
	IF NEW.SITUACAO = 'E' THEN
		FOR ALUNO_ROW IN SELECT DISTINCT ID_MAT_TURMA FROM NOTA
		LOOP
			DECLARE
				TOTAL_PESO REAL := 0.0;
				SOMA_PONDERADA REAL := 0.0;
				AVALIACAO_ROW RECORD;
			BEGIN
				FOR AVALIACAO_ROW IN SELECT ID_AVA, PESO FROM AVALIACAO
				LOOP
					DECLARE
						VALOR_NOTA REAL;
					BEGIN
						SELECT VALOR_NOT INTO VALOR_NOTA
						FROM NOTA
						WHERE ID_MAT_TURMA = ALUNO_ROW.ID_MAT_TURMA
						AND ID_AVA = AVALIACAO_ROW.ID_AVA;

						IF VALOR_NOTA IS NOT NULL THEN
							SOMA_PONDERADA := SOMA_PONDERADA + (VALOR_NOTA * AVALIACAO_ROW.PESO);
							TOTAL_PESO := TOTAL_PESO + AVALIACAO_ROW.PESO;
						END IF;
					END;
				END LOOP;

				IF TOTAL_PESO > 0.0 THEN
					IF (SOMA_PONDERADA / TOTAL_PESO)>=7 THEN
						UPDATE MAT_TURMA AS MT
						SET SITUACAO = 'A'
						WHERE MT.ID_MAT_TURMA = ALUNO_ROW.ID_MAT_TURMA;
					ELSE
						UPDATE MAT_TURMA AS MT
						SET SITUACAO = 'R'
						WHERE MT.ID_MAT_TURMA = ALUNO_ROW.ID_MAT_TURMA;
					END IF;
				END IF;
			END;
		END LOOP;
	END IF;
    RETURN NEW;
END;
$$ LANGUAGE PLPGSQL;
CREATE TRIGGER T_CALC_MEDIA_FIM AFTER UPDATE ON TURMA FOR EACH ROW EXECUTE PROCEDURE CALC_MEDIA_FIM();

=============================================================================================================
--PERMISSOES PROFESSOR
CREATE ROLE PROFESSOR;
CREATE USER THIAGO WITH PASSWORD '12345' INTO ROLE PROFESSOR;

GRANT SELECT ON TURMA TO PROFESSOR;
GRANT SELECT ON MAT_TURMA TO PROFESSOR;
GRANT SELECT ON DISCIPLINA TO PROFESSOR;
GRANT INSERT ON AVALIACAO TO PROFESSOR;
GRANT DELETE ON AVALIACAO TO PROFESSOR;
GRANT UPDATE ON AVALIACAO TO PROFESSOR;
GRANT INSERT ON NOTA TO PROFESSOR;
GRANT DELETE ON NOTA TO PROFESSOR;
GRANT UPDATE ON NOTA TO PROFESSOR;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA PUBLIC TO PROFESSOR;

--PERMISSOES ALUNO
CREATE ROLE ALUNO;
CREATE USER LUCAS WITH PASSWORD '12345' INTO ALUNO;

GRANT SELECT ON TURMA TO ALUNO;
GRANT SELECT ON MAT_TURMA TO ALUNO;
GRANT SELECT ON NOTA TO ALUNO;
GRANT SELECT ON AVALIACAO TO ALUNO;
GRANT SELECT ON DISCIPLINA TO ALUNO;

SELECT * FROM CONSULTAR_NOTAS(7);

SELECT * FROM ALUNO
SELECT * FROM MATRICULA
SELECT * FROM MAT_TURMA
SELECT * FROM DISCIPLINA
SELECT * FROM PRE_REQ
SELECT * FROM TURMA
SELECT * FROM CURSO
SELECT * FROM PAGAMENTO
SELECT * FROM AVALIACAO
SELECT * FROM NOTA
SELECT * FROM FALTA
SELECT * FROM PROFESSOR