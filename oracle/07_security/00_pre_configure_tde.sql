-- =====================================================================
-- STEP 0: Configure System Parameters for TDE (Fixed for CDB/PDB)
-- =====================================================================

-- 1. Переключаемся в корневой контейнер (CDB$ROOT)
ALTER SESSION SET CONTAINER = CDB$ROOT;

PROMPT Switched to CDB$ROOT container. Configuring parameters...

-- 2. Указываем корневую папку для кошельков
-- Настройка применится после рестарта (SCOPE=SPFILE) после этого перезапускаем базу данных
-- ALTER SYSTEM SET WALLET_ROOT = '/opt/oracle/oradata/wallet' SCOPE=SPFILE;

-- 3. Указываем тип конфигурации
-- Исправляет ошибку ORA-32017 (теперь зависимость WALLET_ROOT будет корректна после рестарта)
-- ALTER SYSTEM SET TDE_CONFIGURATION = 'KEYSTORE_CONFIGURATION=FILE' SCOPE=SPFILE;

PROMPT Параметры успешно установлены в CDB$ROOT.
PROMPT Теперь НЕОБХОДИМО перезагрузить базу данных (контейнер) командой:
PROMPT docker restart winstore_oracle