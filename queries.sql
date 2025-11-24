-- queries.sql for oficina

-- Q1: Recuperação simples - listar clientes (accounts) e seus veículos
SELECT a.username, p.name AS client_name, v.license_plate, v.make, v.model, v.year
FROM accounts a
JOIN party p ON a.party_id = p.party_id
LEFT JOIN vehicles v ON a.account_id = v.account_id
ORDER BY p.name;

-- Q2: WHERE - veículos de um determinado ano >= 2015
SELECT v.license_plate, v.make, v.model, v.year
FROM vehicles v
WHERE v.year >= 2015
ORDER BY v.year DESC;

-- Q3: Atributo derivado - total de cada serviço (mão de obra + peças)
SELECT so.service_order_id,
       p.name AS client_name,
       SUM(soi.hours_worked * soi.unit_price) AS labor_total,
       COALESCE(SUM(sip.quantity * sip.unit_cost),0) AS parts_total,
       SUM(soi.hours_worked * soi.unit_price) + COALESCE(SUM(sip.quantity * sip.unit_cost),0) AS order_total
FROM service_orders so
JOIN accounts a ON so.account_id = a.account_id
JOIN party p ON a.party_id = p.party_id
LEFT JOIN service_order_items soi ON so.service_order_id = soi.service_order_id
LEFT JOIN service_item_parts sip ON soi.service_item_id = sip.service_item_id
GROUP BY so.service_order_id, p.name
ORDER BY order_total DESC;

-- Q4: HAVING - clientes que gastaram mais de R$200 em um serviço
SELECT so.service_order_id, p.name AS client_name,
       SUM(soi.hours_worked * soi.unit_price) + COALESCE(SUM(sip.quantity * sip.unit_cost),0) AS order_total
FROM service_orders so
JOIN accounts a ON so.account_id = a.account_id
JOIN party p ON a.party_id = p.party_id
LEFT JOIN service_order_items soi ON so.service_order_id = soi.service_order_id
LEFT JOIN service_item_parts sip ON soi.service_item_id = sip.service_item_id
GROUP BY so.service_order_id, p.name
HAVING SUM(soi.hours_worked * soi.unit_price) + COALESCE(SUM(sip.quantity * sip.unit_cost),0) > 200
ORDER BY order_total DESC;

-- Q5: JOINs complexos - listar ordens com status, total pago e valor restante
SELECT so.service_order_id, p.name AS client_name, so.status,
       COALESCE(vw.order_total,0) AS order_total,
       COALESCE(SUM(pay.amount),0) AS paid_total,
       COALESCE(vw.order_total,0) - COALESCE(SUM(pay.amount),0) AS remaining
FROM service_orders so
JOIN accounts a ON so.account_id = a.account_id
JOIN party p ON a.party_id = p.party_id
LEFT JOIN vw_service_order_totals vw ON so.service_order_id = vw.service_order_id
LEFT JOIN payments pay ON so.service_order_id = pay.service_order_id
GROUP BY so.service_order_id, p.name, so.status, vw.order_total
ORDER BY remaining DESC NULLS LAST;

-- Q6: Produtos/peças com estoque baixo (WHERE) e ordenar
SELECT pr.part_id, pr.sku, pr.name, i.quantity, i.warehouse
FROM parts pr
JOIN inventory i ON pr.part_id = i.part_id
WHERE i.quantity < 15
ORDER BY i.quantity ASC;

-- Q7: Quantidade de serviços realizados por cada mecânico (GROUP BY + HAVING)
SELECT m.mechanic_id, pa.name AS mechanic_name, COUNT(soi.service_item_id) AS items_done,
       SUM(soi.hours_worked) AS total_hours
FROM mechanics m
JOIN party pa ON m.party_id = pa.party_id
LEFT JOIN service_order_items soi ON m.mechanic_id = soi.mechanic_id
GROUP BY m.mechanic_id, pa.name
HAVING COUNT(soi.service_item_id) > 0
ORDER BY total_hours DESC;

-- Q8: Peças mais utilizadas (sum quantity in service_item_parts)
SELECT pr.part_id, pr.name, SUM(sip.quantity) AS total_used
FROM service_item_parts sip
JOIN parts pr ON sip.part_id = pr.part_id
GROUP BY pr.part_id, pr.name
ORDER BY total_used DESC;

-- Q9: Agendamentos futuros (WHERE with date comparison)
SELECT a.username, p.name AS client_name, ap.scheduled_at, ap.duration_minutes, ap.status
FROM appointments ap
JOIN accounts a ON ap.account_id = a.account_id
JOIN party p ON a.party_id = p.party_id
WHERE ap.scheduled_at > now()
ORDER BY ap.scheduled_at ASC;

-- Q10: Clientes que possuem mais de 1 veículo (HAVING)
SELECT a.username, p.name, COUNT(v.vehicle_id) AS total_vehicles
FROM accounts a
JOIN vehicles v ON a.account_id = v.account_id
JOIN party p ON a.party_id = p.party_id
GROUP BY a.username, p.name
HAVING COUNT(v.vehicle_id) > 1;
