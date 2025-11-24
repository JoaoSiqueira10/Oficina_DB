-- seed.sql for oficina (workshop)

-- Parties
INSERT INTO party(name,email,phone) VALUES
('Carlos Pereira','carlos@example.com','+55 11 98888-0001'),
('Oficina Auto LTDA','contato@oficina.com','+55 11 3333-2222'),
('Ana Souza','ana@example.com','+55 21 97777-0002'),
('Fornecedor Peças SA','vendas@pecas.com','+55 21 3333-4444');

-- Accounts (PF and PJ)
INSERT INTO accounts(party_id, username, password_hash, cpf) VALUES
(1, 'carlosp', 'hash_carlos', '111.222.333-44'),
(3, 'ana_s', 'hash_ana', '555.666.777-88');

INSERT INTO accounts(party_id, username, password_hash, cnpj) VALUES
(2, 'oficina_auto', 'hash_oficina', '98.765.432/0001-10');

-- Mechanics (party 2 is company, but add one mechanic as party 2 too)
INSERT INTO mechanics(party_id, hire_date, hourly_rate) VALUES
(2, '2020-05-10', 80.00),
(2, '2021-08-01', 95.00);

-- Vehicles
INSERT INTO vehicles(account_id, license_plate, vin, make, model, year) VALUES
(1, 'ABC1D23', '1HGCM82633A004352', 'Honda', 'Civic', 2010),
(3, 'XYZ9Z88', '2T1BR32E54C123456', 'Toyota', 'Corolla', 2018);

-- Suppliers (party 4)
INSERT INTO suppliers(party_id, supplier_code) VALUES
(4, 'SUPP-PECAS-1');

-- Parts
INSERT INTO parts(sku,name,description,cost_price) VALUES
('PT-OLIO-001','Óleo Sintético 5W40','Litro óleo sintético',25.00),
('PT-FILTRO-001','Filtro de Óleo','Filtro compatível',15.00),
('PT-PNEU-001','Pneu 205/55','Pneu radial',350.00);

-- Part suppliers
INSERT INTO part_suppliers(part_id, supplier_id, supplier_sku, lead_time_days, price) VALUES
(1,1,'OIL-5W40-01',2,30.00),
(2,1,'FILT-01',3,20.00),
(3,1,'PNEU-205-55',7,420.00);

-- Inventory
INSERT INTO inventory(part_id, quantity, warehouse) VALUES
(1,50,'main'),
(2,40,'main'),
(3,10,'main');

-- Create a service order for Carlos: troca de óleo + filtro
INSERT INTO service_orders(account_id, vehicle_id, opened_at, status, notes) VALUES
(1, 1, now() - interval '2 days', 'closed', 'Troca de óleo e filtro.');

-- Add service items
INSERT INTO service_order_items(service_order_id, description, hours_worked, mechanic_id, unit_price, quantity_parts) VALUES
(1, 'Troca de óleo', 0.5, 1, 100.00, 1),
(1, 'Substituição filtro de óleo', 0.25, 2, 50.00, 1);

-- Parts used (link to service items)
INSERT INTO service_item_parts(service_item_id, part_id, quantity, unit_cost) VALUES
(1, 1, 4, 25.00), -- 4 litros de óleo
(2, 2, 1, 15.00);

-- Payments (partial/full)
INSERT INTO payment_methods(account_id, method_type, details) VALUES
(1, 'card', '{"brand":"visa","last4":"1111"}'),
(1, 'cash', '{}'),
(2, 'transfer', '{}');

INSERT INTO payments(service_order_id, payment_method_id, amount, paid_at) VALUES
(1, 1, 250.00, now() - interval '1 day');

-- Another service order (open) for Ana
INSERT INTO service_orders(account_id, vehicle_id, opened_at, status, notes) VALUES
(2, 2, now() - interval '1 day', 'open', 'Revisão geral.');

INSERT INTO service_order_items(service_order_id, description, hours_worked, mechanic_id, unit_price, quantity_parts) VALUES
(2, 'Revisão e diagnóstico', 1.5, 1, 150.00, 0);
