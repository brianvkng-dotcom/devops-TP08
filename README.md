# TP08 - Monitoreo con Prometheus y Grafana

## 1. Objetivo

Implementar una solución de monitoreo para la aplicación de notas desarrollada en trabajos prácticos anteriores, utilizando Prometheus, Grafana y exporters.

La arquitectura final está compuesta por:

- PostgreSQL: base de datos.
- Flask/Gunicorn: backend.
- Nginx: frontend y proxy.
- Prometheus: recolección y almacenamiento de métricas.
- Grafana: visualización de métricas.
- Node Exporter: métricas del host.
- cAdvisor: métricas de contenedores.

## 2. Entorno utilizado

- Sistema operativo: Ubuntu
- Máquina: Nordic
- Usuario: brian
- Docker / Docker Compose
- Aplicación basada en Flask, PostgreSQL y Nginx

El TP08 se realizó sobre una copia del proyecto del TP06 para no modificar el trabajo anterior.

## 3. Instrumentación de Flask

Se incorporó la librería `prometheus-client` y se agregaron métricas específicas de la aplicación:

- `app_requests_total`: cantidad total de requests HTTP.
- `app_request_duration_seconds`: duración de las requests.
- `app_notes_total`: cantidad actual de notas.
- `app_db_errors_total`: errores relacionados con la base de datos.
- `app_info`: información de versión y ambiente.

También se agregó el endpoint `/metrics`.

Se excluyó `/metrics` del contador de requests para evitar que el scraping genere tráfico adicional dentro de la métrica de la aplicación.

## 4. Configuración de Prometheus

Prometheus fue configurado con un intervalo de scraping de 15 segundos.

Targets configurados:

- Prometheus.
- Flask backend.
- Node Exporter.
- cAdvisor.

También se agregaron reglas de alerta para:

- Aplicación caída.
- CPU elevada.
- Tasa elevada de errores HTTP 5xx.
- Poco espacio disponible en disco.

## 5. Configuración de Grafana

Grafana utiliza Prometheus como datasource mediante:

`http://prometheus:9090`

Se configuró el aprovisionamiento automático del datasource y del dashboard.

El dashboard contiene ocho paneles:

1. Requests por segundo.
2. Latencia p50.
3. Total de notas.
4. Tasa de errores 5xx.
5. Requests por endpoint.
6. Latencias p50, p95 y p99.
7. CPU del host.
8. Memoria disponible.

## 6. Arquitectura de comunicación

El flujo principal es:

Usuario → Nginx :8080 → Flask :5000 → PostgreSQL :5432

Las métricas siguen:

Flask → Prometheus :9090 → Grafana :3000

Además:

Node Exporter → Prometheus

cAdvisor → Prometheus

## 7. Pruebas realizadas

Se verificó:

- Estado de los siete servicios.
- Salud de PostgreSQL.
- Salud de Prometheus.
- Endpoint `/health`.
- Endpoint `/metrics`.
- Targets de Prometheus.
- Recolección de métricas reales.
- Creación de notas.
- Visualización de datos en Grafana.
- Dashboard con datos reales.
- Script automático de verificación.

El resultado final fue un stack funcionando correctamente.

## 8. Verificación automática

Se creó:

`scripts/verify.sh`

El script comprueba:

- Estado de los contenedores.
- Salud de Prometheus.
- Salud de la aplicación.
- Existencia de métricas.
- Targets activos de Prometheus.

Finaliza mostrando:

`=== Stack OK — verificación completada ===`

## 9. Desviaciones y cambios realizados

### 9.1 Puerto del frontend

El TP06 ya utilizaba el puerto 80 del host.

Se modificó:

`FRONTEND_PORT=80`

por:

`FRONTEND_PORT=8080`

Esto permite ejecutar TP06 y TP08 simultáneamente.

### 9.2 Nombres de contenedores

Para evitar conflictos con los contenedores del TP06 se utilizó el prefijo:

`tp08-`

Ejemplos:

- `tp08-notes-db`
- `tp08-notes-backend`
- `tp08-notes-frontend`
- `tp08-prometheus`
- `tp08-grafana`
- `tp08-node-exporter`
- `tp08-cadvisor`

### 9.3 Endpoint /metrics mediante Nginx

El backend utiliza el puerto 5000 internamente y no se publicó directamente en el host.

Por eso se agregó una ubicación `/metrics` en Nginx que redirige hacia `backend:5000/metrics`.

Esto permite acceder mediante:

`http://localhost:8080/metrics`

### 9.4 Node Exporter

La configuración original utilizaba:

`/:/host:ro,rslave`

Docker produjo un error relacionado con el montaje y la propagación de mounts.

Se modificó a:

`/:/host:ro`

Con este cambio el contenedor pudo iniciar correctamente.

### 9.5 Dependencia duplicada

Durante la modificación de `requirements.txt` se detectó una entrada duplicada de:

`prometheus-client==0.19.0`

Se eliminó la duplicación.

### 9.6 Aprovisionamiento de Grafana

El dashboard estaba correctamente montado dentro del contenedor, pero inicialmente no aparecía en la interfaz.

Se reinició Grafana para forzar nuevamente el proceso de provisioning.

Después del reinicio el dashboard apareció correctamente.

## 10. Error relevante interpretado

Durante la puesta en marcha de Prometheus se produjo un error al cargar `alerts.yml`.

El mensaje principal fue:

`yaml: line 50: could not find expected ':'`

El problema se produjo porque el archivo había quedado contaminado con texto correspondiente al comando de creación del archivo.

Se reemplazó `alerts.yml` por una versión YAML válida.

Después de corregirlo, Prometheus inició correctamente.

La comprobación:

`curl http://localhost:9090/-/healthy`

devolvió:

`Prometheus Server is Healthy.`

Esto permitió comprobar que el problema estaba en la sintaxis del archivo de reglas y no en el servicio de Prometheus.

## 11. Versión 2

Como mejora respecto de una implementación básica, la versión 2 incorpora:

- Instrumentación directa del backend Flask.
- Contadores para requests y errores.
- Histogramas para medir latencia.
- Gauge para representar el estado actual de las notas.
- Exporters para obtener métricas del host y contenedores.
- Alertas de disponibilidad, CPU, errores y espacio en disco.
- Provisioning automático de Grafana.
- Dashboard reproducible mediante JSON.
- Script de verificación automática.
- Separación de puertos y nombres de contenedores para permitir ejecutar TP06 y TP08 en paralelo.

La justificación técnica es pasar de un monitoreo manual basado en comandos aislados a una solución de observabilidad reproducible y automatizada.

## 12. Conceptos teóricos aplicados

### Counter

`app_requests_total` es un Counter porque representa un valor acumulativo.

Para obtener requests por segundo se utiliza:

`rate(app_requests_total[1m])`

### Gauge

`app_notes_total` es un Gauge porque representa un valor que puede aumentar o disminuir.

### Histogram

`app_request_duration_seconds` es un Histogram porque permite distribuir las duraciones de las requests en buckets.

Con `histogram_quantile()` se pueden obtener percentiles como p50, p95 y p99.

### Exporters

Node Exporter y cAdvisor permiten obtener métricas que no pertenecen directamente a la aplicación.

Node Exporter proporciona información del host, mientras que cAdvisor permite observar los contenedores.

### Observabilidad

El sistema permite observar:

- Disponibilidad.
- Cantidad de requests.
- Errores.
- Latencia.
- Estado de la base de datos.
- CPU.
- Memoria.
- Estado de contenedores.

## 13. Pasos novedosos o sorprendentes

Un aspecto novedoso fue comprobar que una aplicación Dockerizada puede exponer métricas internas que luego son recolectadas automáticamente por Prometheus.

También fue importante comprobar que los servicios se comunican utilizando los nombres de servicio de Docker Compose, por ejemplo `backend:5000`, `prometheus:9090` y `db:5432`.

Otro punto relevante fue observar que un error de sintaxis YAML podía impedir completamente el inicio de Prometheus, aun cuando el resto de los contenedores estuviera funcionando.

Finalmente, el provisioning permitió comprobar que Grafana puede configurarse de forma reproducible mediante archivos, sin tener que crear manualmente toda la configuración desde la interfaz.

## 14. Evidencias

Las principales evidencias obtenidas durante el TP fueron:

- Captura 1: identificación del usuario, máquina y configuración Git.
- Captura 2: disponibilidad del proyecto TP06.
- Captura 3: estructura inicial de TP08.
- Captura 4: copia de backend y frontend.
- Captura 6: dependencia y validación del backend.
- Captura 7: configuración de Prometheus.
- Captura 8: provisioning de Grafana.
- Captura 9: validación del dashboard.
- Captura 10: configuración de Nginx para `/metrics`.
- Captura 11: validación de Docker Compose.
- Captura 13: `/health` y `/metrics`.
- Captura 14: targets de Prometheus en estado UP.
- Captura 15: métricas reales de la aplicación.
- Captura 16: acceso a Grafana.
- Captura 17: datasource Prometheus conectado.
- Captura 18: dashboard de TP08.
- Captura 19: dashboard actualizado con datos reales.
- Captura 20: siete servicios funcionando.
- Captura 21: verificación automática.
- Captura 22: estructura final del proyecto.

## 15. Conclusión

Este trabajo permitió incorporar observabilidad a la aplicación desarrollada anteriormente.

La utilización conjunta de Prometheus y Grafana permite transformar métricas de la aplicación, del host y de los contenedores en información visualizable y útil para detectar problemas.

El TP también permitió aplicar conceptos teóricos como Counter, Gauge, Histogram, `rate()` y `histogram_quantile()`, además de comprender el funcionamiento de exporters y el modelo de scraping de Prometheus.

La integración mediante Docker Compose hace que toda la solución sea reproducible y que los componentes puedan comunicarse mediante la red interna definida para el proyecto.

La evolución de los trabajos prácticos queda relacionada de forma progresiva:

TP06 → Containerización

TP07 → CI/CD

TP08 → Observabilidad y monitoreo

La aplicación deja de ser solamente un conjunto de contenedores funcionando y pasa a contar con mecanismos para observar su comportamiento y detectar problemas.
