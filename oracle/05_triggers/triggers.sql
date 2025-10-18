-- =====================================================================
-- WinStore - Triggers: Timestamp Maintenance (Oracle)
-- =====================================================================
-- Description: BEFORE UPDATE триггеры для автоматического обновления полей
--              updated_AT (Products) и updated_at (Payments). Не содержит
--              бизнес-логики, только техническая поддержка таймстемпов.
-- Author:      WinStore Development Team
-- Created:     2025-05-25
-- Modified:    2025-10-02
-- Version:     1.0.1
-- =====================================================================
-- Dependencies: 01_schema/01_core_schema.sql
-- =====================================================================

CREATE OR REPLACE TRIGGER trg_products_bu_updated
BEFORE UPDATE ON Products
FOR EACH ROW
BEGIN
  :NEW.updated_AT := SYSTIMESTAMP;
END;
/

CREATE OR REPLACE TRIGGER trg_payments_bu_updated
BEFORE UPDATE ON Payments
FOR EACH ROW
BEGIN
  :NEW.updated_at := SYSTIMESTAMP;
END;
/
PROMPT Triggers created successfully