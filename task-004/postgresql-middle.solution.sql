-- Решение #1: группировка:
-- - на одной заправке  |
-- - в один день        |
-- - один вид сервиса   | (то есть это списание-возврат)
-- - по одной карте     | (то есть это один клиент)

-- не учитывается переход между сутками
-- т.е. например, списание в 23:59, зачисление в 00:01

-- CREATE TABLE data AS (
SELECT
      id,
      card_number,
      date,
      volume,
      service,
      address_id
FROM (
    SELECT
          min(id) as id,
          card_number,
          sum(volume) as volume,
          service,
          address_id,
          min(date) as date,
          date(date) as day
    FROM data
    GROUP BY
        card_number,
        address_id,
        day,
        service
) as tbl;
-- )

-- Решение #2: хранимая процедура:
-- - выбираем все карты (всех клиентов)
-- - перебираем карты и по каждой делаем выборку
-- - перебираем строки выборки со 2-ой до последней
-- - берем строки n и (n-1)
-- - сравниваем изменения баланса volume
-- - если знак разный - сравниваем service, address_id и date
-- - меняем volume у отрицательного изменения и удаляем строку с положительным изменением

-- DROP FUNCTION processvolume();

CREATE OR REPLACE FUNCTION processVolume() RETURNS varchar(255) AS $$
DECLARE
    cnt INTEGER := 0;
    ccnt INTEGER;
    cnumber RECORD;
    ccnumber RECORD;  -- current
    pcnumber RECORD;  -- prev
BEGIN
    for cnumber in
        SELECT DISTINCT card_number FROM data
        loop
            ccnt := 0;
            for ccnumber in
                SELECT * FROM data WHERE card_number = cnumber.card_number ORDER BY id
                loop
                    ccnt := ccnt + 1;
                    if ccnt > 1
                    then
                        if (ccnumber.address_id = pcnumber.address_id) and
                           (ccnumber.service = pcnumber.service) and
                           (abs(extract(epoch from (ccnumber.date - pcnumber.date))) < 60 * 10) and  -- пусть разница во времени не больше 10 минут
                           (
                                   ((ccnumber.volume > 0) and (pcnumber.volume < 0)) or
                                   ((ccnumber.volume < 0) and (pcnumber.volume > 0))
                               )
                        then
                            -- 'Тут меняем запись с id ' || pcnumber.id || ' и удаляем ' || ccnumber.id;
                        end if;
                    end if;
                    pcnumber := ccnumber;
                end loop;

            cnt := cnt + 1;
        end loop;

    RETURN 'Обработано записей: '|| cnt;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM processVolume();
