# Checklist — Technical Assessment

## Sincronização do programa

- [ ] Consumir `GET /mock_api/screenings`
- [ ] Percorrer todas as páginas da API
- [ ] Sincronizar screenings, filmes e locais aninhados
- [ ] Usar identificadores externos como chave
- [ ] Garantir idempotência e evitar duplicações
- [ ] Atualizar registros alterados na origem
  - [ ] Mudanças de local
  - [ ] Cancelamentos
  - [ ] Renomeação de filmes
  - [ ] Renomeação de locais
  - [ ] Novos screenings
- [ ] Definir o tratamento de registros removidos na origem
- [ ] Preservar registros processados antes de uma falha parcial
- [ ] Diferenciar registros inválidos de indisponibilidade da API
- [ ] Tratar lentidão, erros e retries
- [ ] Executar a sincronização por um job Sidekiq
- [ ] Agendar a execução periódica
- [ ] Evitar ou tratar execuções simultâneas

## Histórico e observabilidade

- [ ] Registrar cada execução da sincronização
- [ ] Registrar horário e status
- [ ] Registrar sucesso ou falha
- [ ] Registrar quantidade de registros criados
- [ ] Registrar quantidade de registros atualizados
- [ ] Capturar e registrar erros
- [ ] Estruturar os dados para permitir monitoramento e alertas

## Código existente

- [ ] Avaliar o `VenueSync`
- [ ] Evitar associação de locais pelo nome
- [ ] Associar locais pelo identificador externo
- [ ] Tratar registros inválidos sem abandonar todo o lote
- [ ] Explicar no README os problemas encontrados
- [ ] Explicar as decisões tomadas sobre o código herdado

## Lista e filtros

- [ ] Atualizar somente a área de resultados
- [ ] Usar Turbo Frame ou Turbo Stream
- [ ] Manter a renderização no servidor
- [ ] Implementar filtro por data
- [ ] Implementar filtro por local
- [ ] Implementar busca textual por título
- [ ] Garantir que o parâmetro de busca seja aplicado
- [ ] Evitar N+1 ao carregar filmes e locais
- [ ] Considerar debounce da busca com Stimulus

## Testes

- [ ] Testar idempotência
- [ ] Testar criação de registros
- [ ] Testar atualização de registros
- [ ] Testar filme renomeado sem duplicação
- [ ] Testar local renomeado sem duplicação
- [ ] Testar mudança de local
- [ ] Testar mudança de status
- [ ] Testar paginação
- [ ] Testar falha parcial
- [ ] Testar `generation=1`
- [ ] Testar atualização para `generation=2`
- [ ] Testar `fail_after=8`
- [ ] Garantir que uma falha não remova dados já sincronizados

## README

- [ ] Escrever aproximadamente meia página
- [ ] Informar o que faria diferente com mais tempo
- [ ] Descrever problemas encontrados no código existente
- [ ] Explicar mudanças sugeridas
- [ ] Explicar decisões de escopo
- [ ] Registrar premissas adotadas
- [ ] Documentar limitações conhecidas

## Entrega

- [ ] Priorizar correção diante de falhas
- [ ] Criar commits claros e separados
- [ ] Publicar em um repositório Git privado
- [ ] Preservar o histórico sem squash