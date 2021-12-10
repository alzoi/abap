FORM run.
  DATA:
    l_repid       TYPE              sy-repid,
    l_source      TYPE              string,
    lr_source     TYPE REF TO       string,
    lt_source     TYPE TABLE OF     string,
    l_prgname(30) TYPE              c,
    l_msg(120)    TYPE              c,
    l_line(10)    TYPE              c,
    l_word(10)    TYPE              c,
    l_off(3)      TYPE              c,
    l_exit        TYPE              c,
    lt_message    TYPE TABLE OF     bapiret2,
    ls_return     TYPE              bapiret2,
    lt_tab_cod    TYPE TABLE OF     string.

  CONSTANTS:
    lc_sep TYPE              char6  VALUE '%cr_lf',
    lc_op1 TYPE              string VALUE 'UPDATE',
    lc_op2 TYPE              string VALUE 'INSERT',
    lc_op3 TYPE              string VALUE 'MODIFY',
    lc_op4 TYPE              string VALUE 'CALL',
    lc_op5 TYPE              string VALUE 'INCLUDE',
    lc_op6 TYPE              string VALUE 'SUBMIT'.

  l_repid = sy-repid.

  CONCATENATE
    'REPORT SUBPOOL.'
    'DATA:'
    '  gt_out TYPE TABLE OF t001w.'
    ''
    'FORM sel.'
    ''
    '  " ВАШ ЗАПРОС.'
    '  SELECT * FROM t001w INTO TABLE gt_out.'
    ''
    'ENDFORM.'
    ''
    'FORM main.'
    '  DATA:'
    '    t1           TYPE          i,'
    '    t2           TYPE          i,'
    '    lr_salv1     TYPE REF TO   cl_salv_table,'
    '    lr_display   TYPE REF TO   cl_salv_display_settings,'
    '    lr_functions TYPE REF TO   cl_salv_functions,'
    '    l_ttl        TYPE          lvc_title.'
    ''
    '  GET RUN TIME FIELD t1. PERFORM sel.'
    '  GET RUN TIME FIELD t2. t2 = t2 - t1.'
    ''
    '  " Отобразить ALV.'
    '  cl_salv_table=>factory( IMPORTING r_salv_table = lr_salv1 CHANGING  t_table = gt_out ).'
    '  lr_functions = lr_salv1->get_functions( ).'
    '  IF lr_functions IS BOUND.'
    '    lr_functions->set_all( abap_true ).'
    '  ENDIF.'
    '  l_ttl = t2. CONDENSE l_ttl. l_ttl = `Длительность запроса: ` && l_ttl && ` микросекунд`.'
    '  lr_display = lr_salv1->get_display_settings( ). lr_display->set_list_header( l_ttl ).'
    '  lr_salv1->display( ).'
    'ENDFORM.'
    INTO l_source SEPARATED BY lc_sep.
  SPLIT l_source AT lc_sep INTO TABLE lt_source.

  WHILE l_exit <> 4.
    IF l_exit = 3.
      CALL FUNCTION 'FINB_BAPIRET2_DISPLAY'
        EXPORTING
          it_message = lt_message.
      CLEAR lt_message[].
    ENDIF.

    EDITOR-CALL FOR lt_source.
    IF sy-subrc = 0 OR sy-subrc = 2.
      TRY.
          DEFINE _cod.
            LOOP AT lt_source REFERENCE INTO lr_source.
              IF lr_source->* CS lc_op1 OR lr_source->* CS lc_op2 OR lr_source->* CS lc_op3 OR
                 lr_source->* CS lc_op4 OR lr_source->* CS lc_op5 OR lr_source->* CS lc_op6.
                MOVE '<<<<   ЗАПРЕЩЁННЫЙ ОПЕРАТОР УДАЛЁН   <<<' TO lr_source->*.
              ENDIF.
            ENDLOOP.
            GENERATE SUBROUTINE POOL lt_source NAME l_prgname
              MESSAGE l_msg
              LINE    l_line
              WORD    l_word
              OFFSET  l_off.
          END-OF-DEFINITION.
          _cod.
          IF sy-subrc = 0.
            PERFORM main IN PROGRAM (l_prgname).
          ELSE.
            l_exit = 3.
            ls_return-type   = 'E'.
            ls_return-id     = 'G01'.
            ls_return-number = '000'.
            ls_return-row        = 1.
            ls_return-message_v1 = 'Синтаксическая ошибка'.
            APPEND ls_return TO lt_message.
            ls_return-row        = 2.
            ls_return-message_v1 = `Строка/Столбец:` && l_line && '/' && l_off.
            APPEND ls_return TO lt_message.
            ls_return-row        = 3.
            ls_return-message_v1 = l_msg.
            ls_return-message_v2 = l_msg+50(50).
            ls_return-message_v3 = l_msg+100(20).
            APPEND ls_return TO lt_message.
          ENDIF.
        CATCH cx_root.
          SUBMIT (l_repid).
      ENDTRY.
    ELSE.
      l_exit = 4.
    ENDIF.
  ENDWHILE.
ENDFORM.

START-OF-SELECTION.

  PERFORM run.
