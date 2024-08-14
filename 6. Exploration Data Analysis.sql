-- Análisis exploratorio de la Data

SELECT *
FROM layoffs_staging2;

SELECT MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoffs_staging2;

-- Explorar cuales son las empresas que perdieron el 100% de sus empleados
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;

SELECT company, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC; -- Los números(2) representan la columna de la tabla

SELECT company, total_laid_off
FROM layoffs_staging2
WHERE company = 'Amazon';

SELECT MIN(`date`), MAX(`date`)
FROM layoffs_staging2;

-- Explorar cuales son las industrias donde hubieron más despidos
SELECT industry, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC; 

SELECT *
FROM layoffs_staging2;

-- Explorar los paises donde hubieron más despidos
SELECT country, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY country
ORDER BY 2 DESC; 

-- Explorar los años donde hubieron más despidos
SELECT YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY YEAR(`date`)
ORDER BY 2 DESC; 

Select SUBSTRING(`date`, 6, 2) AS `MONTH`, SUM(total_laid_off) -- 6 = posición del caracter que queremos obtener / 2 = la cantidad de caracteres que quiero contando desde el anterior número (6)
FROM layoffs_staging2
GROUP BY `MONTH`;

-- Explorar los meses y el año
Select SUBSTRING(`date`, 1, 7) AS `MONTH`, SUM(total_laid_off) 
FROM layoffs_staging2
WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL -- No utilizamos MONTH porque la clausula WHERE no lo reconoce como columna
GROUP BY `MONTH`
ORDER BY 1;

WITH Rolling_total AS
(
Select SUBSTRING(`date`, 1, 7) AS `MONTH`, SUM(total_laid_off) AS total_off
FROM layoffs_staging2
WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL -- No utilizamos MONTH porque la clausula WHERE no lo reconoce como columna
GROUP BY `MONTH`
ORDER BY 1
)
SELECT `MONTH`,total_off, SUM(total_off)
OVER(ORDER BY `MONTH`) AS rolling_total_off -- La clausula OVER realiza cálculos sobre un conjunto de filas relacionado con la fila actual, sin agrupar los resultados en filas individuales,
FROM Rolling_total;

SELECT company, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;


SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(`date`) -- cuando usas una función de agregación (como SUM), todas las demás columnas en la lista de selección (SELECT) deben ser parte de la cláusula GROUP BY
ORDER BY 3 DESC;

-- Utilizamos CTEs para calcular el ranking de las empresas con mayor despidos por año
WITH Company_Year (company, years, total_laid_off) AS -- CTE llamado Company_Year que calcula el total de despidos (total_laid_off) por empresa (company) y por año (YEAR(date)).
(
SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
), Company_Year_Ranking AS -- CTE toma los resultados del primer CTE (Company_Year) y les asigna un rango basado en el número total de despidos en cada año, utilizando la función de ventana DENSE_RANK().
(
SELECT *,  
DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC) AS Ranking
FROM Company_Year
WHERE years IS NOT NULL
)
SELECT *
FROM Company_Year_Ranking
WHERE Ranking <= 5;

-- Ranking de las empresas con más despidos ordenados por paises
WITH country_laid_off AS
(
SELECT company, country, SUM(total_laid_off) AS sum_laid_off
FROM layoffs_staging2
GROUP BY company, country
) 
SELECT *,
DENSE_RANK() OVER(PARTITION BY country ORDER BY sum_laid_off) AS country_ranking
FROM country_laid_off
WHERE sum_laid_off IS NOT NULL
ORDER BY country ASC
;

-- TOP 5 de las empresas con más despidos ordenados por paises
WITH country_laid_off AS
(
SELECT company, country, SUM(total_laid_off) AS sum_laid_off
FROM layoffs_staging2
GROUP BY company, country
), ranking_country_laid_off AS
(SELECT *,
DENSE_RANK() OVER(PARTITION BY country ORDER BY sum_laid_off DESC) AS country_ranking
FROM country_laid_off
WHERE sum_laid_off IS NOT NULL
)
SELECT *
FROM ranking_country_laid_off
WHERE country_ranking <=5;