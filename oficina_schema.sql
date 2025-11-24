-- oficina_schema.sql
-- Schema for a mechanical workshop (oficina) - PostgreSQL

CREATE SCHEMA IF NOT EXISTS oficina;
SET search_path = oficina;

-- Parties / Clients
CREATE TABLE party (
    party_id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    email VARCHAR(200),
    phone VARCHAR(30),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    UNIQUE(email)
);

-- Accounts: can be PF (cpf) or PJ (cnpj), but not both (CHECK)
CREATE TABLE accounts (
    account_id SERIAL PRIMARY KEY,
    party_id INTEGER REFERENCES party(party_id) ON DELETE SET NULL,
    username VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(200) NOT NULL,
    cpf VARCHAR(14),
    cnpj VARCHAR(18),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    CHECK (
        ((cpf IS NOT NULL AND cnpj IS NULL) OR (cpf IS NULL AND cnpj IS NOT NULL))
    )
);

-- Mechanics (employees)
CREATE TABLE mechanics (
    mechanic_id SERIAL PRIMARY KEY,
    party_id INTEGER REFERENCES party(party_id) ON DELETE SET NULL,
    hire_date DATE,
    hourly_rate NUMERIC(10,2) CHECK (hourly_rate >= 0)
);

-- Vehicles owned by clients
CREATE TABLE vehicles (
    vehicle_id SERIAL PRIMARY KEY,
    account_id INTEGER NOT NULL REFERENCES accounts(account_id) ON DELETE CASCADE,
    license_plate VARCHAR(20) NOT NULL,
    vin VARCHAR(50), -- vehicle identification number
    make VARCHAR(100),
    model VARCHAR(100),
    year INTEGER CHECK (year > 1900 AND year <= EXTRACT(YEAR FROM now())::int + 1),
    UNIQUE(license_plate)
);

-- Parts and suppliers
CREATE TABLE suppliers (
    supplier_id SERIAL PRIMARY KEY,
    party_id INTEGER REFERENCES party(party_id) ON DELETE SET NULL,
    supplier_code VARCHAR(50) UNIQUE
);

CREATE TABLE parts (
    part_id SERIAL PRIMARY KEY,
    sku VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    cost_price NUMERIC(12,2) CHECK (cost_price >= 0),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TABLE part_suppliers (
    part_id INTEGER NOT NULL REFERENCES parts(part_id) ON DELETE CASCADE,
    supplier_id INTEGER NOT NULL REFERENCES suppliers(supplier_id) ON DELETE CASCADE,
    supplier_sku VARCHAR(100),
    lead_time_days INTEGER CHECK (lead_time_days >= 0),
    price NUMERIC(12,2) CHECK (price >= 0),
    PRIMARY KEY (part_id, supplier_id)
);

-- Inventory of parts by warehouse
CREATE TABLE inventory (
    inventory_id SERIAL PRIMARY KEY,
    part_id INTEGER NOT NULL REFERENCES parts(part_id) ON DELETE CASCADE,
    quantity INTEGER NOT NULL CHECK (quantity >= 0),
    warehouse VARCHAR(100) DEFAULT 'main',
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    UNIQUE(part_id, warehouse)
);

-- Service orders (ordem de serviço)
CREATE TABLE service_orders (
    service_order_id SERIAL PRIMARY KEY,
    account_id INTEGER NOT NULL REFERENCES accounts(account_id) ON DELETE RESTRICT,
    vehicle_id INTEGER NOT NULL REFERENCES vehicles(vehicle_id) ON DELETE RESTRICT,
    opened_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    closed_at TIMESTAMP WITH TIME ZONE,
    status VARCHAR(30) NOT NULL DEFAULT 'open', -- open, in_progress, closed, cancelled
    notes TEXT
);

CREATE TABLE service_order_items (
    service_item_id SERIAL PRIMARY KEY,
    service_order_id INTEGER NOT NULL REFERENCES service_orders(service_order_id) ON DELETE CASCADE,
    description TEXT NOT NULL, -- e.g., 'Troca de óleo', 'Alinhamento'
    hours_worked NUMERIC(6,2) DEFAULT 0 CHECK (hours_worked >= 0),
    mechanic_id INTEGER REFERENCES mechanics(mechanic_id),
    unit_price NUMERIC(12,2) NOT NULL CHECK (unit_price >= 0),
    quantity_parts INTEGER DEFAULT 0 CHECK (quantity_parts >= 0)
);

-- Parts used in a service order (many-to-many service_item -> parts)
CREATE TABLE service_item_parts (
    service_item_id INTEGER NOT NULL REFERENCES service_order_items(service_item_id) ON DELETE CASCADE,
    part_id INTEGER NOT NULL REFERENCES parts(part_id) ON DELETE RESTRICT,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_cost NUMERIC(12,2) NOT NULL CHECK (unit_cost >= 0),
    PRIMARY KEY (service_item_id, part_id)
);

-- Payment methods per account
CREATE TABLE payment_methods (
    payment_method_id SERIAL PRIMARY KEY,
    account_id INTEGER NOT NULL REFERENCES accounts(account_id) ON DELETE CASCADE,
    method_type VARCHAR(50) NOT NULL, -- cash, card, transfer
    details JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Payments for service orders (can be partial)
CREATE TABLE payments (
    payment_id SERIAL PRIMARY KEY,
    service_order_id INTEGER NOT NULL REFERENCES service_orders(service_order_id) ON DELETE CASCADE,
    payment_method_id INTEGER REFERENCES payment_methods(payment_method_id) ON DELETE SET NULL,
    amount NUMERIC(12,2) NOT NULL CHECK (amount >= 0),
    paid_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Appointments (scheduling)
CREATE TABLE appointments (
    appointment_id SERIAL PRIMARY KEY,
    account_id INTEGER NOT NULL REFERENCES accounts(account_id) ON DELETE CASCADE,
    vehicle_id INTEGER NOT NULL REFERENCES vehicles(vehicle_id) ON DELETE CASCADE,
    scheduled_at TIMESTAMP WITH TIME ZONE NOT NULL,
    duration_minutes INTEGER NOT NULL CHECK (duration_minutes > 0),
    status VARCHAR(30) NOT NULL DEFAULT 'scheduled' -- scheduled, attended, cancelled, no_show
);

-- Indexes useful
CREATE INDEX idx_vehicles_plate ON vehicles(license_plate);
CREATE INDEX idx_service_orders_account ON service_orders(account_id);

-- View: service order total (derived attribute)
CREATE VIEW vw_service_order_totals AS
SELECT so.service_order_id,
       so.account_id,
       so.opened_at,
       COALESCE(SUM(soi.hours_worked * soi.unit_price + COALESCE(SIP.total_parts_cost,0)),0) AS order_total
FROM service_orders so
LEFT JOIN service_order_items soi ON so.service_order_id = soi.service_order_id
LEFT JOIN (
    SELECT sip.service_item_id, SUM(sip.quantity * sip.unit_cost) AS total_parts_cost
    FROM service_item_parts sip
    GROUP BY sip.service_item_id
) SIP ON soi.service_item_id = SIP.service_item_id
GROUP BY so.service_order_id, so.account_id, so.opened_at;
