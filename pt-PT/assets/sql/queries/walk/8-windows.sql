-- §8 Janelas: a janela de cada linha de turnos, e a unidade em que a sua quantidade se conta.
WITH layers_windows AS (
-- pm:Nameplate/pm:Divisibility/pm:window, beside the amount unit that decides if it is answerable.
SELECT n.filing, n.layer,
       n.window_low, n.window_mode, n.window_high, n.window_unit, n.window_size_absent,
       n.window_absent,
       n.amount_unit
FROM pm.nameplate n
)
SELECT filing      AS declaração,
       layer       AS camada,
       window_mode AS janela,
       window_unit AS unidade_da_janela,
       amount_unit AS unidade_da_quantidade
FROM (
    SELECT * FROM layers_windows
) w
WHERE layer IN ('shift-line', 'linha-partilhada')
  AND window_mode IS NOT NULL;
