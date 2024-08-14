-- Limpieza de Datos
    -- 1. Eliminar duplicados
    -- 2. Estandarizar los datos
    -- 3. Valores nulos o vacíos
    -- 4. Eliminar columnas o filas innecesarias - varias formas

SELECT *  
FROM layoffs;

-- Crear una copia de la información
CREATE TABLE layoffs_staging 
LIKE layoffs
;

SELECT *
FROM layoffs_staging;

-- Insertamos los datos de layoff en nuestra nueva tabla
INSERT layoffs_staging
SELECT * 
FROM layoffs;

-- Identificar duplicados
-- Cuando usas PARTITION BY, estás instruyendo a SQL que agrupe las filas que tienen valores iguales en las columnas especificadas. 
SELECT *,
ROW_NUMBER () OVER (PARTITION BY company, industry, total_laid_off, percentage_laid_off, `date`) AS row_num
FROM layoffs_staging;

-- CTE
WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER () OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

-- Creamos otra copia más porque vamos a modificar la información
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT *
FROM layoffs_staging2;

INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER () OVER (PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

-- Seleccionar los duplicados
SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

-- Eliminar los duplicados
DELETE 
FROM layoffs_staging2
WHERE row_num > 1;

-- Estandarización de Datos	

SELECT company, TRIM(company) -- TRIM elimina los espacios en blanco de la cadena de texto
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);

-- Identificamos si hay columnas iguales pero con diferente nombre o escritura para agruparlas
-- Tenemos que observar columna por columna

SELECT DISTINCT industry 
FROM layoffs_staging2
ORDER BY 1;

-- En la columna Industry, observamos que hay 3 diferentes variables para referirse a la industria de cryptomonedas, los unimos en una sola
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';


SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;

-- En la columna country observamos que hay dos maneras diferentes para referirse a United State, las unimos en una sola
SELECT DISTINCT country, TRIM(TRAILING '.' FROM country) -- Trailing nos permite decidir que caracter queremos eliminar de los valores de la columna country
FROM layoffs_staging2
ORDER BY 1;

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country) 
WHERE country LIKE 'United States%';

-- La columna date no se encuentra en el formato correcto(date). Lo modificamos para que así sea
SELECT `date`
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

-- Convertir la columna date de tipo de dato text a date
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- Tratar los nulos

-- La columna industry tiene espacios vacíos. Los convertimos en nulos para poder tratarlos.
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

-- Comprobamos
SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
OR industry = '';

-- Observamos los valores de la compañía Airbnb 
SELECT *
FROM layoffs_staging2
WHERE company = 'Airbnb'
;

-- Observamos que sus nulos pueden tomar el valor de otras filas. Observamos los demás nulos que existen en la columna  
SELECT *
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
WHERE (t1.industry IS NULL)
AND t2.industry IS NOT NULL;

-- Remplazamos los nulos por valores correspondientes a las respectivas empresas
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

-- La compañía Bally's no tiene valores que puedan remplazar sus nulos.
SELECT *
FROM layoffs_staging2
WHERE company LIKE 'Bally%';

-- Observamos los nulos de las columnas total_laid_off y percentage_laid_off
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Son pocos Nulos, los eliminamos.
DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT *
FROM layoffs_staging2;

-- Eliminamos la columna row_num que nos sirvió para observar duplicados
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

