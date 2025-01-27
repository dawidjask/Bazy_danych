#################################################################
#Bazy danych przestrzennych Lab 10
#Data utworzenia 19.01.2025
#Dawid Jaśkiewicz - 403167
#Skrypt automatyzuje proces pobierania danych z plików ZIP
#Waliduje dane, czyści je, przetwarza i ładuje do bazy danych MySQL
#Eksportuje dane do pliku .csv po czym kompresuje plik
################################################################
#!/bin/bash

# ---Zmienne---
URL="http://home.agh.edu.pl/~wsarlej/dyd/bdp2/materialy/cw10/InternetSales_new.zip"
ZIP_PASSWORD="bdp2agh"
ZIP_NAME="InternetSales_new.zip"
NUMERINDEKSU="403167"
OUTPUT_DIR="PROCESSED"
TIMESTAMP=$(date +%m%d%Y)
LOG_FILE="${OUTPUT_DIR}/script_log_${TIMESTAMP}.log"
BAD_FILE="${OUTPUT_DIR}/InternetSales_new.bad_${TIMESTAMP}.csv"
GOOD_FILE="${OUTPUT_DIR}/${TIMESTAMP}_InternetSales_new.csv"
NUMERINDEKSU="403167"
EXPORT_FILE="${OUTPUT_DIR}/CUSTOMERS_${INDEX}.csv"
TABLE_NAME="CUSTOMERS_${NUMERINDEKSU}"
MYSQL_USER="djaskiew"
MYSQL_PASSWORD_ENCRYPTED="SzhiNjBIa1JSVEJIUGU4RQ=="
MYSQL_HOST="mysql.agh.edu.pl"
MYSQL_PORT="3306"
MYSQL_DATABASE="djaskiew"




# Funkcja do logów
log() {
  local STATUS="$1"
  local MESSAGE="$2"
  echo "$(date '+%Y-%m-%d %H:%M:%S') | $STATUS | $MESSAGE" >> "$LOG_FILE"
}



mkdir -p "$OUTPUT_DIR"
 > "$LOG_FILE"

# Pobieranie i rozpakowywanie pliku
log "INFO" "Rozpoczęcie pobierania pliku z adresu: $URL"
echo "$(date '+%Y-%m-%d %H:%M:%S') | Przygotowywanie pliku"
wget -q -O ${ZIP_NAME} ${URL}
if [[ $? -eq 0 ]]; then
  log "SUCCESS" "Pomyślnie pobrano plik: $ZIP_NAME"
else
  log "FAILURE" "Nie udało się pobrać pliku: $ZIP_NAME"
  exit 1  
fi

unzip -q -P ${ZIP_PASSWORD} -o ${ZIP_NAME}
if [[ $? -eq 0 ]]; then
  log "SUCCESS" "Pomyślnie rozpakowano plik ZIP: $ZIP_NAME"
else
  log "FAILURE" "Nie udało się rozpakować pliku ZIP: $ZIP_NAME"
  exit 1  
fi

# Walidacja
echo "$(date '+%Y-%m-%d %H:%M:%S') | Walidacja danych"
TXT_FILE="InternetSales_new.txt"
TEMP_HEADER=$(mktemp)
TEMP_DATA=$(mktemp)
head -n 1 "$TXT_FILE" > "$TEMP_HEADER"
tail -n +2 "$TXT_FILE" > "$TEMP_DATA"

TEMP_GOOD=$(mktemp)
TEMP_BAD=$(mktemp)

# Usunięcie pustych linii
if awk 'NF' "$TEMP_DATA" > "$TEMP_GOOD"; then
  log "SUCCESS" "Pomyślnie usunięto puste wiersze."
else
  log "FAILURE" "Nie udało się usunąć pustych wierszy"
  exit 1
fi
mv "$TEMP_GOOD" "$TEMP_DATA"

# Usuwanie zawartości kolumny SecretCode za pomocą awk
COLUMN_INDEX=$(awk -F'|' '{for (i = 1; i <= NF; i++) if ($i == "SecretCode") print i; exit}' "$TEMP_HEADER")

if awk -F'|' -v col="$COLUMN_INDEX" '{
  if (NF >= col) {
    $col = ""  # Usunięcie zawartości kolumny SecretCode
  }
  print $0
}' OFS='|' "$TEMP_DATA" > "$TEMP_GOOD"; then
  log "SUCCESS" "Zawartość kolumny SecretCode została pomyślnie usunięta."
else
  log "FAILURE" "Nie udało się usunąć zawartości kolumny SecretCode."
  exit 1
fi
mv "$TEMP_GOOD" "$TEMP_DATA"


# Usunięcie duplikatów
if awk '
  !repeat[$0]++ { print > temp_good }  
  repeat[$0] == 2 { print > temp_bad } 
' temp_good="$TEMP_GOOD" temp_bad="$TEMP_BAD" "$TEMP_DATA"; then
  log "SUCCESS" "Usuwanie duplikatów zakończone pomyślnie"
else
  log "FAILURE" "Usuwanie duplikatów nie powiodło się."
  exit 1
fi
mv "$TEMP_GOOD" "$TEMP_DATA"

#Usunięcie wierszy, mające ilość kolumn inną niż TEMP_HEADER
NUM_COLUMNS=$(awk -F'|' '{print NF}' "$TEMP_HEADER")

if awk -v num_columns="$NUM_COLUMNS" -F'|' '
  NF == num_columns { print > temp_good }  
  NF != num_columns { print >> temp_bad }  
' temp_good="$TEMP_GOOD" temp_bad="$TEMP_BAD" "$TEMP_DATA"; then
  log "SUCCESS" "Walidacja liczby kolumn zakończona pomyślnie."
else
  log "FAILURE" "Walidacja liczby kolumn nie powiodła się."
  exit 1
fi
mv "$TEMP_GOOD" "$TEMP_DATA"

#Filtrowanie wierszy dla których kolumna OrderQuantity wynosi maksymalnie 100
COLUMN_INDEX=$(awk -F'|' '{for (i=1; i<=NF; i++) if ($i == "OrderQuantity") print i; exit}' "$TEMP_HEADER")
if awk -F'|' -v col="$COLUMN_INDEX" '
  $col <= 100 { print > temp_good }  
  $col > 100 { print >> temp_bad }   
' temp_good="$TEMP_GOOD" temp_bad="$TEMP_BAD" "$TEMP_DATA"; then
  log "SUCCESS" "Filtrowanie dla których kolumna OrderQuantity <=100 , zakończone pomyślnie."
else
  log "FAILURE" "Filtrowanie na podstawie wartości kolumny nie powiodło się."
  exit 1
fi
mv "$TEMP_GOOD" "$TEMP_DATA"

#Usunięcie wierszy z pustymi kolumnami (oprócz ostatniej)
if awk -F'|' '{
  valid = 1  
  for (i = 1; i < NF; i++) {  
    while (substr($i, 1, 1) == " " || substr($i, 1, 1) == "\t") {
      $i = substr($i, 2) 
    }
    while (substr($i, length($i), 1) == " " || substr($i, length($i), 1) == "\t") {
      $i = substr($i, 1, length($i) - 1)  
    }
    if (length($i) == 0) {
      valid = 0  
      break  
    }
  }
  if (valid) {
    print $0 >> temp_good
  } else {
    print $0 >> temp_bad
  }
}' temp_good="$TEMP_GOOD" temp_bad="$TEMP_BAD" "$TEMP_DATA"; then
  log "SUCCESS" "Usuwanie wierszy z pustymi kolumnami zakończone pomyślnie."
else
  log "FAILURE" "Usuwanie wierszy z pustymi kolumnami nie powiodło się."
  exit 1
fi
mv "$TEMP_GOOD" "$TEMP_DATA"

# Usunięcie wierszy ze złym formatem imienia
COLUMN_INDEX=$(awk -F'|' '{for (i = 1; i <= NF; i++) if ($i == "Customer_Name") print i; exit}' "$TEMP_HEADER")

if awk -F'|' -v col="$COLUMN_INDEX" '{
  value = $col  
  if (substr(value, 1, 1) == "\"" && substr(value, length(value), 1) == "\"") {  
    stripped = substr(value, 2, length(value) - 2)  
    n = split(stripped, parts, ",") 
    if (n == 2 && length(parts[1]) > 0 && length(parts[2]) > 0) {  
      print $0 > temp_good  
    } else {
      print $0 >> temp_bad 
    }
  } else {
    print $0 >> temp_bad  
  }
}' temp_good="$TEMP_GOOD" temp_bad="$TEMP_BAD" "$TEMP_DATA"; then
  log "SUCCESS" "Przetwarzanie kolumny Customer_Name zakończone pomyślnie."
else
  log "FAILURE" "Przetwarzanie kolumny Customer_Name nie powiodło się."
  exit 1
fi
mv "$TEMP_GOOD" "$TEMP_DATA"

# Zamiana Customer_Name na LAST_NAME i FIRST_NAME
NEW_TEMP_HEADER=$(mktemp)
awk -F'|' -v col="$COLUMN_INDEX" '{
  for (i = 1; i <= NF; i++) {
    if (i == col) {
      printf "LastName|FirstName"  
    } else {
      printf "%s", $i  
    }
    if (i < NF) printf "|"  
  }
  printf "\n"  
}' "$TEMP_HEADER" > "$NEW_TEMP_HEADER"

if awk -F'|' -v col="$COLUMN_INDEX" '{
  split($col, name_parts, ",")
  if (length(name_parts) == 2) {
    name_parts[1] = substr(name_parts[1], 2)
    name_parts[2] = substr(name_parts[2], 1, length(name_parts[2]) - 1)
    $col = name_parts[1] "|" name_parts[2]
  }
  for (i = 1; i <= NF; i++) {
    printf "%s", $i
    if (i < NF) printf "|"
  }
  printf "\n"
}' "$TEMP_DATA" > "$TEMP_GOOD"; then
  log "SUCCESS" "Przetwarzanie danych zakończone pomyślnie."
else
  log "FAILURE" "Przetwarzanie danych nie powiodło się."
  exit 1
fi
mv "$TEMP_GOOD" "$TEMP_DATA"

# Zmiana przecinka na kropkę w UnitPrice
COLUMN_INDEX=$(awk -F'|' '{for (i = 1; i <= NF; i++) if ($i == "UnitPrice") print i; exit}' "$NEW_TEMP_HEADER")
if awk -F'|' -v col="$COLUMN_INDEX" '{
  if (col <= NF) {
    # Zamieniamy przecinki na kropki w UnitPrice
    new_value = ""
    for (i = 1; i <= length($col); i++) {
      char = substr($col, i, 1)
      if (char == ",") {
        char = "."  # Zamiana przecinka na kropkę
      }
      new_value = new_value char
    }
    $col = new_value
  }
  # Drukowanie przetworzonego wiersza
  for (i = 1; i <= NF; i++) {
    printf "%s", $i
    if (i < NF) printf "|"
  }
  printf "\n"
}' "$TEMP_DATA" > "$TEMP_GOOD"; then 
  log "SUCCESS" "Zamiana przecinków na kropki w kolumnie UnitPrice zakończona pomyślnie."
else
  log "FAILURE" "Nie udało się zamienić przecinków na kropki w kolumnie UnitPrice."
  exit 1
fi




###############################

MYSQL_PASSWORD=$(echo -n "$MYSQL_PASSWORD_ENCRYPTED" | base64 --decode)

#Tworzenie tabeli
SQL_QUERY="
DROP TABLE IF EXISTS ${TABLE_NAME};
CREATE TABLE ${TABLE_NAME} (
    ProductKey INT,
    CurrencyAlternateKey VARCHAR(3),
    LAST_NAME VARCHAR(255) NOT NULL,
    FIRST_NAME VARCHAR(255) NOT NULL,
    OrderDateKey INT,
    OrderQuantity INT,
    UnitPrice DECIMAL(10,2),
    SecretCode VARCHAR(10)
) 
"


if mysql -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -h"${MYSQL_HOST}" -P"${MYSQL_PORT}" "${MYSQL_DATABASE}" -e "${SQL_QUERY}" 2>/dev/null; then
  log "SUCCESS" "Tabela ${TABLE_NAME} została pomyślnie utworzona w bazie danych ${MYSQL_DATABASE}."
else
  log "FAILURE" "Nie udało się utworzyć tabeli ${TABLE_NAME} w bazie danych ${MYSQL_DATABASE}."
  exit 1
fi

#Ładowanie danych do tabeli MYSQL
echo "$(date '+%Y-%m-%d %H:%M:%S') | Ładowanie danych do tabeli MYSQL"
SQL_LOAD_DATA="
LOAD DATA LOCAL INFILE '${TEMP_GOOD}'
INTO TABLE CUSTOMERS_${NUMERINDEKSU}
FIELDS TERMINATED BY '|'
LINES TERMINATED BY '\n'
(ProductKey, CurrencyAlternateKey, LAST_NAME, FIRST_NAME, OrderDateKey, OrderQuantity, UnitPrice, SecretCode);
"

if mysql --local-infile=1 -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -h"${MYSQL_HOST}" -P"${MYSQL_PORT}" "${MYSQL_DATABASE}" -e "${SQL_LOAD_DATA}" 2>/dev/null; then
  log "SUCCESS" "Przefiltrowane dane zostały pomyślnie załadowane do tabeli CUSTOMERS_${NUMERINDEKSU}."
else
  log "FAILURE" "Nie udało się załadować danych z pliku  do tabeli CUSTOMERS_${NUMERINDEKSU}."
  exit 1
fi

#Aktualizacja kolumny SecretCode
SQL_QUERY="
UPDATE CUSTOMERS_${NUMERINDEKSU}
SET SecretCode = SUBSTRING(MD5(RAND()), 1, 10);
"

if mysql -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -h"${MYSQL_HOST}" -P"${MYSQL_PORT}" "${MYSQL_DATABASE}" -e "${SQL_QUERY}" 2>/dev/null; then
  log "SUCCESS" "Kolumna SecretCode w tabeli CUSTOMERS_${NUMERINDEKSU} została zaktualizowana losowymi stringami o długości 10."
else
  log "FAILURE" "Nie udało się zaktualizować kolumny SecretCode w tabeli CUSTOMERS_${NUMERINDEKSU}."
  exit 1
fi

#Kompresowanie pliku
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT_DIR="${SCRIPT_DIR}/PROCESSED"
EXPORT_FILE="${OUTPUT_DIR}/${TABLE_NAME}.csv"
COMPRESSED_FILE="${OUTPUT_DIR}/${TABLE_NAME}.gz"




if mysql -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -h"${MYSQL_HOST}" -P"${MYSQL_PORT}" "${MYSQL_DATABASE}" -e "SELECT * FROM ${TABLE_NAME}" > "${EXPORT_FILE}" 2>/dev/null; then
  log "SUCCESS" "Tabela ${TABLE_NAME} została pomyślnie wyeksportowana do pliku ${EXPORT_FILE}."
else
  log "FAILURE" "Nie udało się wyeksportować tabeli ${TABLE_NAME} do pliku ${EXPORT_FILE}."
  exit 1
fi

if gzip -c "${EXPORT_FILE}" > "${COMPRESSED_FILE}"; then
  log "SUCCESS" "Plik ${EXPORT_FILE} został pomyślnie skompresowany do ${COMPRESSED_FILE}."
else
  log "FAILURE" "Nie udało się skompresować pliku ${EXPORT_FILE}."
  exit 1
fi


cat "$NEW_TEMP_HEADER" "$TEMP_GOOD" > "$GOOD_FILE"
cat "$TEMP_HEADER" "$TEMP_BAD" > "$BAD_FILE"

echo "$(date '+%Y-%m-%d %H:%M:%S') | Usuwanie plików tymczasowych"
rm -f "$TEMP_HEADER" "$NEW_TEMP_HEADER" "$TEMP_DATA" "$TEMP_GOOD" "$TEMP_BAD"











