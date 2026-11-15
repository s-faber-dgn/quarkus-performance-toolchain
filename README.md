# Quarkus Performance Toolchain

Ein reproduzierbares Werkzeugset, um eine lokal auf macOS laufende Quarkus-Anwendung unter Last zu untersuchen. Podman Compose betreibt Prometheus und Grafana; JVM-Diagnose und Profiling laufen auf dem Host gegen den lokalen Java-Prozess.

## Enthalten

- Prometheus und Grafana via Podman Compose
- Prometheus-Konfiguration für Quarkus-Metriken auf `host.containers.internal:8080`
- Grafana-Datenquelle sowie Dashboards für JVM-Übersicht, CPU, Speicher und Durchsatz
- k6-Beispiel für einen konfigurierbaren HTTP-Endpunkt
- Skripte für JVM-Auswahl, JFR-Aufzeichnung, Heap-Dump und async-profiler
- optionales Zellij-Layout

## Voraussetzungen

- macOS mit Podman und initialisierter Podman-Machine
- vollständiges JDK passend zur Anwendung; `jcmd`, `jfr` und `jstack` im `PATH`
- k6 und async-profiler für Last- und CPU/Allocation-Profile
- Quarkus mit `io.quarkus:quarkus-micrometer-registry-prometheus`

Host-Werkzeuge installieren. Beispiel mit Homebrew:

```bash
brew install k6 async-profiler
```

JMC und VisualVM sind optionale GUI-Werkzeuge. JFR-Dateien lassen sich mit JMC öffnen; Heap-Dumps mit Eclipse MAT.

## Schnellstart

1. Prometheus-Registry-Extension in der Quarkus-Anwendung ergänzen. Wenn die App nur an `localhost` gebunden ist, zusätzlich in ihrer `application.properties` die für Prometheus nötigen Hostnamen zulassen:

   ```properties
   quarkus.http.host-validation.allowed-hosts=localhost,127.0.0.1,host.containers.internal
   ```

   Danach die App neu starten.
2. Quarkus lokal starten und `http://localhost:8080/q/metrics` prüfen.
3. Monitoring starten: `podman compose up -d`.
4. Grafana unter <http://localhost:3000> öffnen (Login `admin` / `performance`; Passwort beim ersten Login ändern).
   Im Ordner **Performance** werden die Dashboards **Quarkus Performance**, **Quarkus CPU optimieren**, **Quarkus Memory optimieren** und **Quarkus Durchsatz optimieren** automatisch bereitgestellt.
5. Einen geeigneten, nicht destruktiven **App-Endpunkt** mit k6 testen. `/q/health/ready` und andere `/q/`-Endpunkte erzeugen bei der Quarkus-Standardeinstellung keine HTTP-Durchsatzmetriken. Den Beispielpfad durch einen vorhandenen GET-Endpunkt deiner App ersetzen:

   ```bash
   K6_BASE_URL=http://localhost:8080 K6_PATH=/api/items k6 run k6/smoke.js
   ```

6. JVM-Prozess finden und JFR aufzeichnen:

   ```bash
   ./scripts/java-processes.sh
   ./scripts/record-jfr.sh <PID> 120
   ```

Ergebnisse landen in `artifacts/` und werden von Git ignoriert. Für reproduzierbare Vergleiche Commit, JDK-Version, JVM-Optionen, Testdaten und Lastprofil mitnotieren.

## Metriken in Grafana prüfen

Die Daten fließen von der Quarkus-App über `http://host.containers.internal:8080/q/metrics` zu Prometheus und von dort über `http://prometheus:9090` zur bereitgestellten Grafana-Datenquelle. Die App muss laufen und die Prometheus-Registry-Extension enthalten.

1. Auf dem Host `curl -f http://localhost:8080/q/metrics` ausführen. Die Antwort muss Prometheus-Metriken enthalten, etwa `jvm_memory_used_bytes`.
2. In Prometheus unter <http://localhost:9090/targets> prüfen, ob das Target `quarkus` den Status **UP** hat. Bei **DOWN** die dort angezeigte Fehlermeldung prüfen. Die App muss aus dem Podman-Container über `host.containers.internal:8080` erreichbar sein. Bei `400 Bad Request` die oben gezeigte Quarkus-Hostfreigabe ergänzen; ein `200` mit `Host: localhost:8080` aus dem Container bestätigt diese Ursache.
3. In Grafana unter <http://localhost:3000/d/quarkus-performance/quarkus-performance> das Dashboard öffnen. **Quarkus-Metriken erreichbar** muss grün und **Erfasste Metrikreihen** größer als null sein. Die JVM-Kurven erscheinen nach den ersten Scrapes; die HTTP-Kurven benötigen zusätzlich Anfragen an die App.

### Optimierungs-Dashboards

- [CPU](http://localhost:3000/d/quarkus-cpu/quarkus-cpu): Prozess- und Systemauslastung, verbrauchte CPU-Kerne, GC-Zeit, Thread-Zustände und Worker-Pools. Bei hoher CPU mit `./scripts/record-jfr.sh <PID> 60` oder `./scripts/profile-async.sh <PID> 30 cpu` die konkreten Hotspots finden.
- [Memory](http://localhost:3000/d/quarkus-memory/quarkus-memory): Heap, langlebige Daten nach GC, Allokationsrate, GC-Pausen, Non-Heap und direkte Buffer. Bei dauerhaft wachsendem Speicher JFR-Allokationen oder einen Heap-Dump auswerten.
- [Durchsatz](http://localhost:3000/d/quarkus-throughput/quarkus-throughput): Requests pro Sekunde, 5xx-Quote, mittlere und maximale Antwortzeit, stärkste Endpunkte, aktive Anfragen und Worker-Warteschlange. Für belastbare Vergleiche denselben Endpunkt und dasselbe Lastprofil mit k6 wiederholen.

HTTP-Raten und die mittlere Antwortzeit benötigen mindestens zwei Scrapes und echte Anfragen an einen App-Endpunkt. Der maximale Antwortzeitwert ist ein Micrometer-Zeitfenstermaximum und kein Perzentil. Zur Kontrolle vor und nach dem Lasttest `curl -s http://localhost:8080/q/metrics | rg '^http_server_requests_seconds_count'` ausführen; der Zähler für den getesteten Pfad muss steigen.

Bei einem anderen App-Port `prometheus/prometheus.yml` anpassen und Prometheus mit `podman compose restart prometheus` neu starten. Falls die App ihre Metriken an einem anderen Pfad oder Management-Port veröffentlicht, auch `metrics_path` und das Target entsprechend ändern. Ein Neustart von Grafana ist für Änderungen an den Dashboard-Dateien normalerweise nicht nötig; die Dateibereitstellung aktualisiert sie automatisch.

## JVM-Diagnose

```bash
./scripts/java-processes.sh
./scripts/jvm-summary.sh <PID>
./scripts/record-jfr.sh <PID> 60
./scripts/heap-dump.sh <PID>
./scripts/thread-dump.sh <PID>
./scripts/profile-async.sh <PID> 30 cpu
./scripts/profile-async.sh <PID> 30 alloc
./scripts/profile-async.sh <PID> 30 lock
```

JFR untersuchen:

```bash
jfr summary artifacts/recording-*.jfr
jfr view hot-methods artifacts/recording-*.jfr
jfr view allocation-by-site artifacts/recording-*.jfr
```

Heap-Dumps können groß sein, die JVM kurz pausieren und sensible Daten enthalten. Nicht committen oder weitergeben, bevor sie geprüft wurden.

## Anpassen

Bei anderem Quarkus-Port die Target-Adresse in `prometheus/prometheus.yml` anpassen. Die k6-URL und den Pfad steuerst du über `K6_BASE_URL` und `K6_PATH`. Für aussagekräftige Resultate Lastprofil, Dauer, Ramp-up und Schwellenwerte an den Use Case anpassen.

```bash
podman compose down       # Container stoppen
podman compose down -v    # Container und gespeicherte Metrik-/Dashboard-Daten löschen
```

