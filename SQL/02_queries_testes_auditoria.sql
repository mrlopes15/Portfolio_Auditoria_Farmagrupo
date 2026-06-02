-- PROJETO: Sistema de Auditoria Interna Baseado em Dados
-- Empresa: Farmagrupo Nordeste SA
-- Base ficticia para fins de portfolio
------------------------------------------------------------------
SET search_path TO auditoria;


-- TESTE DE AUDITORIA 1 -- Pagamentos sem aprovação formal
-- Hipótese: Existem pagamentos acima de R$ 5k sem aprovação?
-- Norma Global: Domínio V - Princípio 13 - Planeje os Trabalhos com Eficácia
-- Norma 13.2 - Avaliação de Riscos do Trabalho
-- Norma 13.4 - Critérios de Avaliação

SELECT 	nr_documento,
    	filial,
    	centro_custo,
    	fornecedor,
    	valor_bruto,
    	forma_pagamento,
    	status_aprovacao,
    	data_emissao,
    	data_lancamento,
    	usuario_lancamento
FROM despesas
WHERE valor_bruto > 5000 AND status_aprovacao IN ('PENDENTE', 'BLOQUEADO')
ORDER BY valor_bruto DESC;



-- TESTE DE AUDITORIA 2 -- Volume e percentual sem aprovação
-- Hipótese: A falha é sistêmica ou pontual?
-- Norma Global: Domínio V - Princípio 14 - Conduza o Trabalho de Auditoria
-- Norma 14.2 - Análises e Potenciais Constatações do Trabalho

WITH total_acima_5k AS (
    SELECT COUNT(*) AS total
    FROM despesas
    WHERE valor_bruto > 5000
)
SELECT
    COUNT(*) AS qtd_sem_aprovacao,
    t.total AS total_acima_5k,
    ROUND(100.0 * COUNT(*) / t.total, 1) AS pct_sem_aprovacao
FROM despesas, total_acima_5k t
WHERE valor_bruto > 5000 AND status_aprovacao IN ('PENDENTE', 'BLOQUEADO')
GROUP BY t.total;



-- TESTE DE AUDITORIA 3 -- Impacto financeiro
-- Hipótese: O valor exposto é relevante para o negócio?
-- Norma Global: Domínio V - Princípio 14 - Conduza o Trabalho de Auditoria
-- Norma 14.3 - Avaliação das Constatações

WITH total_acima_5k AS (
    SELECT COUNT(*) AS total
    FROM despesas
    WHERE valor_bruto > 5000
)
SELECT
    COUNT(*) AS qtd_transacoes,
    SUM(valor_bruto) AS valor_total_risco,
    ROUND(AVG(valor_bruto), 2) AS valor_medio_transacao,
    MAX(valor_bruto) AS maior_transacao,
    MIN(valor_bruto) AS menor_transacao
FROM despesas, total_acima_5k t
WHERE valor_bruto > 5000 AND status_aprovacao IN ('PENDENTE', 'BLOQUEADO')
GROUP BY t.total;



-- TESTE DE AUDITORIA 4 -- Atrasos nos lançamentos acima de 10 dias
-- Hipótese: Existem lançamentos fora do prazo comprometendo a tempestividade das demonstrações financeiras?
-- Norma Global: Princípio 14 - Conduza o Trabalho de Auditoria
-- Norma 14.1 - Coletando Informações para Análises e Avaliação

SELECT 	nr_documento,
    	filial,
    	centro_custo,
    	fornecedor,
    	valor_bruto,
    	usuario_lancamento,
    	data_emissao,
    	data_lancamento,
    	(data_lancamento - data_emissao) AS dias_atraso
FROM despesas
WHERE (data_lancamento - data_emissao) > 10
ORDER BY dias_atraso DESC, valor_bruto DESC;



-- TESTE DE AUDITORIA 5 -- Padrão suspeito no limite de 30 dias
-- Hipótese: Registros com exatamente 30 dias estão concentrados em usuários específicos indicando adequação deliberada ao limite?
-- Norma Global: Princípio 14 - Conduza o Trabalho de Auditoria
-- Norma 14.2 - Análises e Potenciais Constatações do Trabalho
-- Norma 4.3 - Ceticismo Profissional


SELECT 	usuario_lancamento,
    	filial,
    	COUNT(*) AS qtd_30_dias,
    	SUM(valor_bruto) AS valor_total
FROM despesas
WHERE (data_lancamento - data_emissao) = 30
GROUP BY usuario_lancamento, filial
ORDER BY qtd_30_dias DESC, valor_total DESC;



-- TESTE DE AUDITORIA 6 -- Cruzamento de falhas múltiplas
-- Hipótese: Existem transações com ausência de aprovação e atraso simultâneos, representando o maior nível de risco do projeto?
-- Norma Global: Princípio 14 - Conduza o Trabalho de Auditoria
-- Norma 14.2 - Análises e Potenciais Constatações do Trabalho
-- Norma 14.3 - Avaliação das Constatações

SELECT 	nr_documento,
    	filial,
    	centro_custo,
    	fornecedor,
    	valor_bruto,
    	forma_pagamento,
    	status_aprovacao,
    	usuario_lancamento,
    	data_emissao,
    	data_lancamento,
    	(data_lancamento - data_emissao) AS dias_atraso
FROM despesas
WHERE valor_bruto > 5000
  AND status_aprovacao IN ('PENDENTE', 'BLOQUEADO')
  AND (data_lancamento - data_emissao) > 10
ORDER BY valor_bruto DESC, dias_atraso DESC;

-- Teste DE AUDITORIA 6a -- Impacto financeiro das falhas combinadas
-- Hipótese: Qual o valor total exposto nas transações com falha dupla?

SELECT
    COUNT(*) AS qtd_falha_dupla,
    SUM(valor_bruto) AS valor_total_risco,
    ROUND(AVG(valor_bruto), 2) AS valor_medio_transacao,
    MAX(valor_bruto) AS maior_transacao
FROM despesas
WHERE valor_bruto > 5000
  AND status_aprovacao IN ('PENDENTE', 'BLOQUEADO')
  AND (data_lancamento - data_emissao) > 10;
  
-- Teste DE AUDITORIA 6b -- Impacto financeiro das falhas combinadas
-- Hipótese: Qual o valor total e a por usuários?

SELECT 	usuario_lancamento, 
    	COUNT(*) AS total_lancamentos,
		SUM(valor_bruto)
FROM despesas 
WHERE valor_bruto > 5000 
    AND status_aprovacao IN ('PENDENTE', 'BLOQUEADO') 
    AND (data_lancamento - data_emissao) > 10 
GROUP BY usuario_lancamento
ORDER BY total_lancamentos DESC;


-- TESTE DE AUDITORIA 7 -- Segregação de função e rastreabilidade
-- Hipótese: Existem transações onde o usuário que lançou é o mesmo que aprovou, ou onde não há aprovador identificado?
-- Princípio 14 - Conduza o Trabalho de Auditoria
-- Norma 14.2 - Análises e Potenciais Constatações do Trabalho

SELECT	usuario_lancamento,
    	aprovador,
   		COUNT(*) AS qtd_transacoes,
    SUM(valor_bruto) AS valor_total,
    CASE
        WHEN usuario_lancamento = aprovador
            THEN 'AUTO-APROVACAO - RISCO CRITICO'
        WHEN aprovador IS NULL OR aprovador = ''
            THEN 'SEM APROVADOR IDENTIFICADO'
        ELSE 'OK - SEGREGADO'
    END AS status_segregacao
FROM despesas
WHERE valor_bruto > 5000
GROUP BY usuario_lancamento, aprovador
ORDER BY valor_total DESC;

SELECT 	SUM(valor_total) AS total_sem_aprovador,
		SUM(Q)
FROM (
    SELECT
        usuario_lancamento,
        aprovador,
        SUM(valor_bruto) AS valor_total,
        CASE
            WHEN usuario_lancamento = aprovador
                THEN 'AUTO-APROVACAO - RISCO CRITICO'
            WHEN aprovador IS NULL OR aprovador = ''
                THEN 'SEM APROVADOR IDENTIFICADO'
            ELSE 'OK - SEGREGADO'
        END AS status_segregacao
    FROM despesas
    WHERE valor_bruto > 5000
    GROUP BY usuario_lancamento, aprovador
)
WHERE status_segregacao = 'SEM APROVADOR IDENTIFICADO';


-- TESTE DE AUDITORIA 8 -- Concentração por usuário e centro de custo
-- Hipótese: Existe concentração de volume financeiro em usuários ou centros de custo específicos?
-- Princípio 14 - Conduza o Trabalho de Auditoria
-- Norma 14.2 - Análises e Potenciais Constatações do Trabalho


SELECT 	usuario_lancamento,
		centro_custo,
    	filial,
    	COUNT(*) AS qtd_transacoes,
    	SUM(valor_bruto) AS valor_total,
    	ROUND(100.0 * SUM(valor_bruto) /
        	SUM(SUM(valor_bruto)) OVER (), 1) AS pct_total,
    	COUNT(CASE WHEN status_aprovacao IN
        	('PENDENTE','BLOQUEADO') THEN 1 END) AS qtd_sem_aprovacao
FROM despesas
GROUP BY usuario_lancamento, centro_custo, filial
ORDER BY valor_total DESC;


-- TESTE DE AUDITORIA 9 -- Risco por forma de pagamento
-- Hipótese: Formas de pagamento com baixa rastreabilidade representam volume financeiro relevante?
-- Princípio 14 - Conduza o Trabalho de Auditoria
-- Norma 14.2 - Análises e Potenciais Constatações do Trabalho

SELECT 	forma_pagamento,
    	COUNT(*) AS qtd_transacoes,
    	SUM(valor_bruto) AS valor_total,
    	ROUND(100.0 * SUM(valor_bruto) /
        	SUM(SUM(valor_bruto)) OVER (), 1) AS pct_total,
    	COUNT(CASE WHEN status_aprovacao IN
        	('PENDENTE','BLOQUEADO') THEN 1 END) AS qtd_sem_aprovacao,
		SUM(CASE WHEN status_aprovacao IN 
			('PENDENTE','BLOQUEADO') THEN valor_bruto ELSE 0 END) AS valor_sem_aprovacao,
    	CASE
        	WHEN forma_pagamento IN ('DIN','CHQ')
            	THEN 'ALTO RISCO - baixa rastreabilidade'
        	WHEN forma_pagamento = 'PIX'
            	THEN 'RISCO MODERADO - rastreavel externamente'
        	WHEN forma_pagamento IN ('BOL','TED')
            	THEN 'BAIXO RISCO - rastreavel'
        	ELSE 'INDEFINIDO'
    	END AS nivel_risco
FROM despesas
GROUP BY forma_pagamento
ORDER BY valor_total DESC;


-- TESTE DE AUDITORIA 10a -- Tempestividade fiscal
-- Hipótese: Existem notas fiscais lançadas fora da competência, comprometendo a acuracidade das demonstrações financeiras?
-- Princípio 14 - Conduza o Trabalho de Auditoria
-- Norma 14.1 - Coletando Informações para Análises e Avaliação

SELECT 	nr_documento,
    	tipo_doc,
    	fornecedor,
    	natureza_operacao,
    	filial,
    	valor_nota,
    	data_emissao,
    	data_lancamento,
    	(data_lancamento - data_emissao) AS dias_atraso,
    	usuario_lancamento,
    	CASE
        	WHEN (data_lancamento - data_emissao) > 30
            	THEN 'CRITICO - fora da competencia'
        	WHEN (data_lancamento - data_emissao) BETWEEN 16 AND 30
            	THEN 'ALTO - atraso relevante'
        	WHEN (data_lancamento - data_emissao) BETWEEN 6 AND 15
            	THEN 'ATENCAO - atraso moderado'
        	ELSE 'OK'
    	END AS status_tempestividade
FROM fiscal
WHERE (data_lancamento - data_emissao) > 5
ORDER BY dias_atraso DESC, valor_nota DESC;



SELECT 
    nr_documento,
    tipo_doc,
    fornecedor,
    natureza_operacao,
    filial,
    valor_nota,
    data_emissao,
    data_lancamento,
    (data_lancamento - data_emissao) AS dias_atraso,
    usuario_lancamento,
    CASE
        WHEN (data_lancamento - data_emissao) > 30 THEN 'CRITICO - fora da competencia'
        WHEN (data_lancamento - data_emissao) BETWEEN 16 AND 30 THEN 'ALTO - atraso relevante'
        WHEN (data_lancamento - data_emissao) BETWEEN 6 AND 15 THEN 'ATENCAO - atraso moderado'
        ELSE 'OK'
    END AS status_tempestividade,
    -- COLUNA DE CONTAGEM: Conta quantas notas existem para cada categoria de atraso
    COUNT(*) OVER(PARTITION BY 
        CASE
            WHEN (data_lancamento - data_emissao) > 30 THEN 1
            WHEN (data_lancamento - data_emissao) BETWEEN 16 AND 30 THEN 2
            WHEN (data_lancamento - data_emissao) BETWEEN 6 AND 15 THEN 3
            ELSE 4
        END
    ) AS qtd_no_status
FROM fiscal
WHERE (data_lancamento - data_emissao) > 5
ORDER BY dias_atraso DESC, valor_nota DESC;

-- TESTE DE AUDITORIA 10a-2 — Concentração de atrasos fiscais por filial e usuário
-- Pergunta: Onde e com quem está concentrada a falha de tempestividade fiscal?
-- Norma Global: Princípio 14 — Norma 14.2

SELECT
    filial,
    usuario_lancamento,
    COUNT(*) AS qtd_atraso,
    SUM(valor_nota) AS valor_total,
	SUM(SUM(valor_nota)) OVER(PARTITION BY filial) AS valor_total_filial,
	ROUND(AVG(data_lancamento - data_emissao), 1) AS media_dias_atraso,
	ROUND(100.0 * SUM(valor_nota) / SUM(SUM(valor_nota)) OVER(PARTITION BY filial), 1) AS pct_participacao_filial
FROM fiscal
WHERE (data_lancamento - data_emissao) > 5
GROUP BY filial, usuario_lancamento
ORDER BY filial, valor_total DESC;


-- TESTE DE AUDITORIA 10b -- Notas sem validação prévia
-- Hipótese: Existem notas fiscais lançadas sem validação prévia, indicando falha no controle de entrada de documentos?
-- Princípio 14 - Conduza o Trabalho de Auditoria
-- Norma 14.2 - Análises e Potenciais Constatações do Trabalho

SELECT 	nr_documento,
    	tipo_doc,
    	fornecedor,
    	natureza_operacao,
    	filial,
    	valor_nota,
    	data_emissao,
    	data_lancamento,
    	usuario_lancamento,
    	validado
FROM fiscal
WHERE validado = 'false'
ORDER BY valor_nota DESC;


-- TESTE DE AUDITORIA 10c -- Concentração por fornecedor
-- Hipótese: Existe concentração de volume fiscal em poucos fornecedores, representando risco de dependência operacional?
-- Princípio 14 - Conduza o Trabalho de Auditoria
-- Norma 14.2 - Análises e Potenciais Constatações do Trabalho


SELECT 	fornecedor,
    	natureza_operacao,
    	tipo_doc,
    	COUNT(*) AS qtd_notas,
   		SUM(valor_nota) AS valor_total,
    	ROUND(100.0 * SUM(valor_nota) /
        	SUM(SUM(valor_nota)) OVER (), 1) AS pct_total
FROM fiscal
GROUP BY fornecedor, natureza_operacao, tipo_doc
ORDER BY valor_total DESC;


