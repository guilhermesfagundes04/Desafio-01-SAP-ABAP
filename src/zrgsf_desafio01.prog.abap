* Desafio 01 - Exercícios ABAP
" Mostrar nome da companhia aérea, data do voo, soma do peso da bagagem, quantidade de passageiros e quantidade de nacionalidade.

*Seleção
" Compania Aérea (CARRID);
" Nº Voo (CONNID).

*Criar programa que liste:
" SCARR-CARNAME;
" SFLIGHT-FLDATE;
" PESO_BAGAGEM --> (soma do campo SBOOK-LUGGWEIGHT para o voo);
" QTD_PASSAGEIROS --> (contagem registros SBOOK para o voo);
" QTD_NACIONALIDADE --> (contagem países diferentes para o voo).

REPORT zrgsf_desafio01.

* Declaro as tabelas que vão ser utilizadas no report *
TABLES: scarr, sbook, scustom.

* Declaro meus tipos internos que vão ser usados. *
* OBS: Sempre por como campo as chaves primárias das tabelas. *
TYPES: BEGIN OF ty_desafio,
         carrname          TYPE scarr-carrname,
         fldate            TYPE sbook-fldate,
         peso_bagagem      TYPE sbook-luggweight,
         qtd_passageiros   TYPE i,
         qtd_nacionalidade TYPE i,
       END OF ty_desafio,
       BEGIN OF ty_scarr,
         carrid   TYPE scarr-carrid,
         carrname TYPE scarr-carrname,
       END OF ty_scarr,
       BEGIN OF ty_sbook,
         carrid     TYPE sbook-carrid,
         connid     TYPE sbook-connid,
         fldate     TYPE sbook-fldate,
         bookid     TYPE sbook-bookid,
         luggweight TYPE sbook-luggweight,
         customid   TYPE sbook-customid,
       END OF ty_sbook,
       BEGIN OF ty_scustom,
         id      TYPE scustom-id,
         country TYPE scustom-country,
       END OF ty_scustom.

* Declaro minhas tabelas internas(globais) que vão ser utilizadas para os SELECTS *
DATA: gt_desafio   TYPE TABLE OF ty_desafio,
      gt_scarr     TYPE TABLE OF ty_scarr,
      gt_sbook     TYPE TABLE OF ty_sbook,
      gt_sbook_aux TYPE TABLE OF ty_sbook, "Auxiliar para fazer o tratamento de peso da bagagem, quantidade de passageiros e quantidade de nacionalidades
      gt_scustom   TYPE TABLE OF ty_scustom.

* Faço um SELECTION-SCREEN para por na tela as minhas seleções que vão ser utilizadas para filtrar os dados que vão ser pesquisados. *
SELECTION-SCREEN BEGIN OF BLOCK bc01 WITH FRAME TITLE TEXT-001.

  SELECT-OPTIONS: s_carrid FOR scarr-carrid,
                  s_connid FOR sbook-connid.

SELECTION-SCREEN END OF BLOCK bc01.

* Faço um START-OF-SELECTION para chamar meu PERFORM de busca. *
START-OF-SELECTION.

  PERFORM zf_busca.

END-OF-SELECTION.

* Chamando os PERFORM's de tratamento e exibição. *
  PERFORM zf_tratamento.
  PERFORM zf_exibe.

* Faço meu formulário de busca (SELECTS) começar sempre do macro pro micro *
FORM zf_busca.

  SELECT carrid, connid, fldate, bookid, luggweight, customid "SELECIONO esses atributos
    FROM sbook "DA tabela sbook
    INTO CORRESPONDING FIELDS OF TABLE @gt_sbook "EM CAMPOS CORRESPONDENTE DA TABELA gt_sbook
   WHERE carrid IN @s_carrid "ONDE carrid está EM seleção s_carrid
     AND connid IN @s_connid. "E connid está EM seleção s_connid

  IF sy-subrc IS INITIAL. "SE sy-subrc É INICIAL (está vazia = 0)

    SELECT carrid, carrname "SELECIONO esses atributos
      FROM scarr "DA tabela scarr
      INTO CORRESPONDING FIELDS OF TABLE @gt_scarr "EM CAMPOS CORRESPONDENTE DA TABELA gt_scarr
       FOR ALL ENTRIES IN @gt_sbook "PARA TODAS AS ENTRADAS EM gt_sbook
     WHERE carrid EQ @gt_sbook-carrid. "ONDE carrid IGUAL gt_sbook-carrid (chaves tem que ser iguais da tabela do for all entries)

    SELECT id, country "SELECIONO esses atributos
      FROM scustom "DA yabela scustom
      INTO CORRESPONDING FIELDS OF TABLE @gt_scustom "EM CAMPOS CORRESPONDENTE DA TABELA gt_scustom
       FOR ALL ENTRIES IN @gt_sbook "PARA TODAS AS ENTRADAS EM gt_sbook
     WHERE id EQ @gt_sbook-customid. "ONDE id IGUAL gt_sbook-customid chaves tem que ser iguais da tabela do for all entries)

    gt_sbook_aux = gt_sbook. "Atribuindo gt_sbook_aux IGUAL a gt_sbook

  ENDIF.

  PERFORM zf_ordenacao. "Chamo o PERFORM de ordenação.

ENDFORM.

* Faço meu formulário de ordenação (SORT) *
FORM zf_ordenacao.

  SORT: gt_sbook BY carrid ASCENDING connid ASCENDING fldate ASCENDING, "ORGANIZAR tabela gt_sbook POR chaves primárias em ordem CRESCENTE
        gt_sbook_aux BY carrid ASCENDING connid ASCENDING fldate ASCENDING, "ORGANIZAR tabela gt_sbook_aux POR chaves primárias em ordem CRESCENTE
        gt_scarr BY carrid ASCENDING, "ORGANIZAR tabela gt_scarr POR chaves primárias em ordem CRESCENTE (só ponho as chaves primárias que tem relação)
        gt_scustom BY id ASCENDING. "ORGANIZAR tabela gt_scustom POR chaves primárias em ordem CRESCENTE (só ponho as chaves primárias que tem relação)

  DELETE ADJACENT DUPLICATES FROM gt_sbook COMPARING carrid connid fldate. "EXCLUIR DUPLICAÇÕES ADJACENTES DE gt_sbook COMPARANDO carrid, connid e fldate (sempre por chaves no DELETE, e não campos)

ENDFORM.

* Faço meu formulário de tratamento (LÓGICA) *
FORM zf_tratamento.

  DATA: lt_countries TYPE SORTED TABLE OF scustom-country WITH UNIQUE KEY table_line, "Declarando tabela interna local lt_countries TIPO DE TABELA CLASSIFICADA DE scustom-country COM CHAVE ÚNICA table_line
        lv_country   TYPE scustom-country. "Vriável para armazenar os paises distintos "Delacarando variável local lv_country TIPO scustom-country

* Criação dos meus FIELD-SYMBOLS (SÍMBOLOS DE CAMPO)
  FIELD-SYMBOLS: <fs_sbook>   TYPE ty_sbook,
                 <fs_aux>     TYPE ty_sbook,
                 <fs_scarr>   TYPE ty_scarr,
                 <fs_scustom> TYPE ty_scustom,
                 <fs_desafio> TYPE ty_desafio.

  LOOP AT gt_sbook ASSIGNING <fs_sbook>. "LAÇO EM gt_sbook ATRIBUINDO fs_sbook (do macro pro micro)

    CLEAR lt_countries. "LIMPAR os dados da tabela interna local lt_countries (para não ter mais nacionalidades do que passageiros)

    APPEND INITIAL LINE TO gt_desafio ASSIGNING <fs_desafio>. "ANEXAR LINHA INICIAL A tabela gt_desafio ATRIBUINDO fs_desafio
    <fs_desafio>-fldate = <fs_sbook>-fldate. "Simbolo de campo_desafio-fldate IGUAL simbolo de campo_sbook-fldate (É O QUE EU TENHO NA TABELA SBOOK E QUERO EXIBIR NA TELA)

    READ TABLE gt_scarr ASSIGNING <fs_scarr> WITH KEY carrid = <fs_sbook>-carrid BINARY SEARCH. "LER TABELA gt_scarr ATRIBUINDO fs_scarr COM CHAVE carrid = fs_sbook-carrid BUSCA BINÁRIA
    IF sy-subrc IS INITIAL. "SE sy-subrc É INICIAL (está vazia = 0)
      <fs_desafio>-carrname = <fs_scarr>-carrname. "Simbolo de campo_desafio-carrname IGUAL simbolo de campo_scarr-carrname (É O QUE EU TENHO NA TABELA SCARR E QUERO EXIBIR NA TELA)
    ENDIF.

    READ TABLE gt_sbook_aux TRANSPORTING NO FIELDS WITH KEY carrid = <fs_sbook>-carrid connid = <fs_sbook>-connid fldate = <fs_sbook>-fldate BINARY SEARCH. "LER TABELA gt_sbook_aux TRANSPORTANDO CAMPOS SEM CHAVE (chaves primárias) BUSCA BINÁRIA
    IF sy-subrc IS INITIAL. "SE sy-subrc É INICIAL (está vazia = 0)

      LOOP AT gt_sbook_aux FROM sy-tabix ASSIGNING <fs_aux>. "LAÇO EM gt_sbook_aux DE sy-tabix (cada iteração, indicando a linha atual) ATRIBUINDO fs_aux

        IF <fs_aux>-carrid NE <fs_sbook>-carrid OR <fs_aux>-connid NE <fs_sbook>-connid OR <fs_aux>-fldate NE <fs_sbook>-fldate. "SE as chaves de fs_aux NÃO FOREM IGUAIS as chaves de fs_sbook
          EXIT. "SAÍDA do loop
        ENDIF.

        ADD <fs_aux>-luggweight TO <fs_desafio>-peso_bagagem. "ADICIONAR fs_aux-luggweight PARA fs_desafio-peso_bagagem
        ADD 1 TO <fs_desafio>-qtd_passageiros. "ADICIONAR 1 PARA fs_desafio-qtd_passageiros

        READ TABLE gt_scustom ASSIGNING <fs_scustom> WITH KEY id = <fs_aux>-customid BINARY SEARCH. "LER TABELA gt_scustom ATRIBUINDO fs_scustom COM CHAVE id = fs_aux-id BUSCA BINÁRIA
        IF sy-subrc IS INITIAL AND <fs_scustom>-country IS NOT INITIAL. "SE sy-subrc É INICIAL (está vazia = 0) E fs_scustom-country NÃO É INICIAL (não está vazia)
          lv_country = <fs_scustom>-country. "Atribuindo lv_country IGUAL a fs_scustom-country
          INSERT lv_country INTO TABLE lt_countries. "INSERIR lv_country NA TABELA lt_countries
        ENDIF.

      ENDLOOP.

      <fs_desafio>-qtd_nacionalidade = lines( lt_countries ). "Atribuindo fs_desafio-qtd_nacionalidade IGUAL a lines( lt_countries ) linhas da tabela local interna de países

    ENDIF.

  ENDLOOP.

ENDFORM.

* Faço meu formulário de exibição (MOSTRAR NA TELA)
FORM zf_exibe.
  DATA: lr_table     TYPE REF TO cl_salv_table,
        lr_functions TYPE REF TO cl_salv_functions,
        lr_columns   TYPE REF TO cl_salv_columns_table,
        lr_column    TYPE REF TO cl_salv_column.

  TRY.
      cl_salv_table=>factory( IMPORTING r_salv_table = lr_table
                              CHANGING  t_table      = gt_desafio ). "Aqui vai ser a minha tabela interna global principal

      lr_functions = lr_table->get_functions( ).
      lr_functions->set_all( abap_true ).

      lr_columns = lr_table->get_columns( ).
      lr_columns->set_optimize( abap_true ).

      lr_column ?= lr_columns->get_column( 'PESO_BAGAGEM' ).
      lr_column->set_short_text( 'Peso' ).
      lr_column->set_medium_text( 'Peso Bagagem' ).
      lr_column->set_long_text( 'Peso total da Bagagem' ).

      lr_column ?= lr_columns->get_column( 'QTD_PASSAGEIROS' ).
      lr_column->set_short_text( 'Pas.' ).
      lr_column->set_medium_text( 'Tot. passageiros' ).
      lr_column->set_long_text( 'Total de passageiros no voo' ).

      lr_column ?= lr_columns->get_column( 'QTD_NACIONALIDADE' ).
      lr_column->set_short_text( 'Nac.' ).
      lr_column->set_medium_text( 'Tot. nacionalidades' ).
      lr_column->set_long_text( 'Total de nacionalidades no voo' ).

      lr_table->display( ).
    CATCH cx_salv_msg.
    CATCH cx_salv_not_found.
  ENDTRY.
ENDFORM.
