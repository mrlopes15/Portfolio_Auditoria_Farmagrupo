CREATE DATABASE auditoria;

SET search_path TO auditoria;

CREATE TABLE despesas(
	id SERIAL PRIMARY KEY,
	nr_documento TEXT NOT NULL,
	filial TEXT,
	centro_custo TEXT NOT NULL,
	fornecedor TEXT,
	valor_bruto NUMERIC(10,2),
	forma_pagamento TEXT,
	status_aprovacao TEXT,
	aprovador TEXT,
	data_emissao DATE,
	data_lancamento DATE,
	usuario_lancamento TEXT	
);

CREATE TABLE fiscal (
	id SERIAL PRIMARY KEY,
	nr_documento TEXT NOT NULL,
	tipo_doc TEXT,
	fornecedor TEXT,
	natureza_operacao TEXT,
	filial TEXT NOT NULL,
	valor_nota NUMERIC(10,2),
	data_emissao DATE,
	data_lancamento DATE,
	validado BOOLEAN NOT NULL,
	usuario_lancamento TEXT
);

CREATE TABLE log_auditoria (
	id SERIAL PRIMARY KEY,
	data_execucao TIMESTAMP DEFAULT NOW() NOT NULL,
	tipo_risco TEXT,
	nivel_risco TEXT,
	prioridade TEXT,
	id_registro INT,
	nr_documento TEXT,
	tabela_origem TEXT NOT NULL,
	descricao TEXT,
	valor NUMERIC(10,2),
	usuario TEXT,
	filial TEXT
);

