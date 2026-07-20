# Legacy Mailing Update Process — SSIS and SQL Server

Registro histórico de uma rotina de atualização de mailing implementada com SQL Server Integration Services e scripts SQL.

## Status

**Projeto desativado.** O SQL Server e os bancos associados foram encerrados após uma migração para BigQuery. Este repositório permanece apenas como documentação técnica do processo legado e não representa um ambiente operacional.

## Conteúdo

- `exec.dtsx`: pacote SSIS com tarefas de carga e atualização;
- `alteracoes.sql`: alterações e ajustes aplicados ao processo;
- `regra.sql`: regras SQL relacionadas à classificação e ao mailing.

## Objetivo original

A rotina coordenava etapas como:

1. leitura de arquivo de entrada;
2. carga em tabela de staging;
3. ajustes de tipos de dados;
4. remoção de registros inválidos;
5. atualização de classificações e códigos operacionais;
6. aplicação de regras de mailing;
7. preparação dos dados para processos posteriores.

## Tecnologias demonstradas

- SQL Server Integration Services;
- SQL Server;
- tarefas Execute SQL;
- arquivos delimitados;
- staging e transformação;
- regras de negócio em SQL;
- automação de processo legado.

## Aviso sobre o pacote

O arquivo `.dtsx` é um artefato histórico exportado do ambiente original. Ele pode conter nomes antigos de máquinas, usuários, servidores, caminhos, tabelas e connection managers. A infraestrutura referenciada foi desativada, mas esses valores não devem ser copiados para novos ambientes.

## Reutilização

Não execute o pacote diretamente. Para estudar ou reconstruir o processo:

1. abra uma cópia no Visual Studio com SSDT compatível;
2. remova ou recrie todos os connection managers;
3. substitua caminhos e tabelas por recursos de laboratório;
4. revise cada tarefa SQL individualmente;
5. utilize dados sintéticos;
6. configure proteção de segredos adequada;
7. valide o fluxo em ambiente isolado.

## Limitações

- dependência de infraestrutura já desativada;
- regras e schemas específicos do ambiente original;
- ausência de projeto SSDT completo e testes automatizados;
- pacote monolítico com lógica incorporada;
- connection managers históricos precisam ser reconstruídos;
- o repositório não é uma solução instalável.

## Contexto de portfólio

O valor deste repositório está na leitura e manutenção de um processo SSIS legado e na experiência posterior de migração para BigQuery. Para projetos novos, prefira configurações externas, identidades técnicas, observabilidade e pipelines desacoplados.