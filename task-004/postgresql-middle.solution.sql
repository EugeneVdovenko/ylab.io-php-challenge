-- группируем операции:
-- - на одной заправке  |
-- - в один день        |
-- - один вид сервиса   | (то есть это списание-возврат)
-- - по одной карте     | (то есть это один клиент)

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
) as tbl
