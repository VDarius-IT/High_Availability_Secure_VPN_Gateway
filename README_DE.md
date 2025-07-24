# 🔐 Absicherung des Fernzugriffs: Hochverfügbares und sicheres VPN-Gateway

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

> Eine robuste, sichere und performante Fernzugriffslösung auf Basis von AWS, entwickelt für außergewöhnliche Verfügbarkeit und abgesichert durch Multi-Faktor-Authentifizierung.

Dieses Repository dokumentiert die Architektur, die Bereitstellung und den Betrieb eines **hochverfügbaren (HA) IPsec/OpenVPN-Clusters** auf AWS. Die Lösung wurde entwickelt, um eine sichere, zuverlässige und performante Anbindung für Remote-Mitarbeiter zu gewährleisten und verfügt über einen automatisierten Failover-Mechanismus, der durch proaktive CloudWatch-Alarme ausgelöst wird.

Dieses Projekt demonstriert Expertise in den Bereichen Cloud-Netzwerke, Infrastruktursicherheit, Hochverfügbarkeitssysteme und Automatisierung.

## Inhaltsverzeichnis

- [Projektübersicht](#projektübersicht)
- [Wesentliche Merkmale](#wesentliche-merkmale)
- [Systemarchitektur](#systemarchitektur)
- [Technologie-Stack](#technologie-stack)
- [Erste Schritte](#erste-schritte)
  - [Voraussetzungen](#voraussetzungen)
  - [Anleitung zur Bereitstellung](#anleitung-zur-bereitstellung)
- [Sicherheitsmaßnahmen](#sicherheitsmaßnahmen)
  - [Multi-Faktor-Authentifizierung (MFA)](#multi-faktor-authentifizierung-mfa)
  - [Firewall & Sicherheitsgruppen](#firewall--sicherheitsgruppen)
- [Hochverfügbarkeit & Automatischer Failover](#hochverfügbarkeit--automatischer-failover)
  - [Failover-Mechanismus](#failover-mechanismus)
  - [Überwachung mit CloudWatch](#überwachung-mit-cloudwatch)
- [Performance-Optimierung](#performance-optimierung)
- [Betriebshandbücher (Runbooks)](#betriebshandbücher-runbooks)
- [Struktur des Repositorys](#struktur-des-repositorys)
- [Mitwirken](#mitwirken)
- [Lizenz](#lizenz)

## Projektübersicht

Mit der Zunahme von Remote-Arbeit ist die Gewährleistung eines sicheren und zuverlässigen Zugriffs auf private Netzwerkressourcen von größter Bedeutung. Dieses Projekt begegnet dieser Anforderung durch die Bereitstellung einer **an Zero-Trust-Prinzipien ausgerichteten, hochverfügbaren Fernzugriffsschicht**, die Unternehmensressourcen schützt und gleichzeitig sicherstellt, dass Mitarbeiter auch bei Infrastrukturstörungen zuverlässig eine Verbindung herstellen können.

Die Lösung basiert auf drei Kernprinzipien:
*   **Sicherheit:** Erzwingung starker Authentifizierung und Verschlüsselung des gesamten Datenverkehrs.
*   **Ausfallsicherheit (Resilienz):** Eliminierung von Single Points of Failure und Automatisierung der Wiederherstellung.
*   **Performance:** Optimierung des Netzwerkpfads für maximalen Durchsatz.

## Wesentliche Merkmale

*   **Hochverfügbarkeit:** Bereitstellung als Multi-Node-Cluster über mehrere AWS Availability Zones (AZs), um Single Points of Failure zu eliminieren.
*   **Automatischer Failover:** Ein benutzerdefinierter Failover-Mechanismus, ausgelöst durch proaktive AWS CloudWatch-Alarme, gewährleistet eine nahtlose Servicekontinuität mit minimaler Ausfallzeit.
*   **Robuste Sicherheit:** Abgesichert durch obligatorische Multi-Faktor-Authentifizierung (MFA) für alle Benutzerverbindungen.
*   **Unterstützung für zwei Protokolle:** Bietet sowohl **IPsec (strongSwan)** als auch **OpenVPN**, um eine breite Palette von Client-Geräten und Anwendungsfällen zu unterstützen.
*   **Optimierter Durchsatz:** Die Infrastruktur- und VPN-Serverkonfigurationen sind sorgfältig auf hochleistungsfähigen Netzwerkverkehr abgestimmt.
*   **Infrastructure as Code (IaC):** Die gesamte Umgebung ist als Code (z.B. Terraform) definiert, um wiederholbare und konsistente Bereitstellungen zu ermöglichen.

## Systemarchitektur

Die Architektur ist auf Redundanz und automatische Wiederherstellung ausgelegt. Der Client-Verkehr wird zu einem stabilen Endpunkt (z. B. einem Route 53-Eintrag) geleitet, der auf die aktive VPN-Instanz verweist. CloudWatch überwacht kontinuierlich den Zustand dieser Instanz. Wenn ein Ausfall erkannt wird, wird eine Lambda-Funktion ausgelöst, um den Verkehr automatisch auf die Standby-Instanz in einer anderen AZ umzuleiten.

```text
                                                                   +-----------------------+
                                                                   |   Unternehmens-VPC    |
                                                                   |  (Privates Subnetz)   |
                                                                   +-----------+-----------+
                                                                               |
                             +-------------------------------------------------+--------------------------------------+
                             |                                                                                        |
               +-------------v---------------------+                                                  +---------------v------------------+
               |   AWS-Verfügbarkeitszone A        |                                                  |   AWS-Verfügbarkeitszone B       |
               |                                   |                                                  |                                  |
               |  +---------------------------+    |                                                  |   +--------------------------+   |
               |  |  [AKTIV]                  |    |                                                  |  |        [STANDBY]          |   |
               |  |  VPN-Instanz              +----+--------+-----------------------------------------|  |  VPN-Instanz              |   |
               |  |  (EC2: IPsec/OpenVPN)     |    |         |                         |              |  |  (EC2: IPsec/OpenVPN)     |   |
               |  +---------------------------+    |         |                         |              |   +--------------------------+   |
               |                                   |         |                         |              |                                  |
               +----------------^------------------+         |                         |              +-----------------^----------------+
                                |                            |                         |                                 |
                                |                            |                         |                   Route 53 Health Check
                                |                            |                         |
                                |  vpn.yourcompany.com (Route 53 Failover-Eintrag)     |
                                +----------------------------|-------------------------+
                                                             |
                                                             | (Client-Verbindung)
                                                             |
                                                    +--------v-----------+
                                                    | Remote-Mitarbeiter |
                                                    +--------------------+

                                                         ⬇
                                               AWS CloudWatch-Alarme
                                              (Instanzstatus, CPU, benutzerdefiniertes Health-Skript)
                                                         ⬇
                                               AWS Lambda Failover-Handler
                                                         ⬇
                                               Aktion zur Aktualisierung des Route 53 DNS-Eintrags
```

## Technologie-Stack

*   **Cloud-Anbieter:** AWS (Amazon Web Services)
*   **Compute:** Amazon EC2 (Netzwerkoptimierte Instanzen, z.B. `c5n.large`)
*   **Netzwerk:** Amazon VPC, Subnets, Route 53 (für DNS Failover)
*   **VPN-Software:** OpenVPN (Community Edition), strongSwan (für IPsec)
*   **Infrastructure as Code:** Terraform
*   **Überwachung & Alarmierung:** Amazon CloudWatch (Alarme, Logs, Metriken)
*   **Automatisierung:** AWS Lambda (Python/Node.js), Bash-Skripte
*   **Authentifizierung:** Google Authenticator PAM

## Erste Schritte

Dieser Abschnitt führt Sie durch die Bereitstellung des HA-VPN-Gateways in Ihrem eigenen AWS-Konto.

### Voraussetzungen

*   Ein AWS-Konto mit entsprechenden IAM-Berechtigungen (EC2, VPC, CloudWatch, Route 53, Lambda).
*   Die AWS CLI, lokal konfiguriert.
*   Terraform installiert.
*   Ein registrierter Domainname, der in einer Route 53 Hosted Zone verwaltet wird.
*   Ein SSH-Schlüsselpaar, das in Ihrer Ziel-AWS-Region erstellt wurde.

### Anleitung zur Bereitstellung

Die gesamte Infrastruktur wird mit Terraform provisioniert, um Wiederholbarkeit zu gewährleisten.

1.  **Repository klonen:**
    ```sh
    git clone https://github.com/<your-github-username>/<your-repository-name>.git
    cd <your-repository-name>
    ```

2.  **Infrastrukturvariablen konfigurieren:**
    Erstellen Sie eine `terraform.tfvars`-Datei und füllen Sie sie mit Ihren spezifischen Werten.
    ```hcl
    # Beispiel terraform.tfvars

    aws_region     = "us-east-1"
    instance_type  = "c5n.large"
    key_name       = "<Ihr-AWS-SSH-Schlüsselname>"
    vpc_id         = "<Ihre-VPC-ID>"
    public_subnet_az1_id = "<Ihre-Public-Subnet-ID-in-AZ-A>"
    public_subnet_az2_id = "<Ihre-Public-Subnet-ID-in-AZ-B>"
    hosted_zone_id = "<Ihre-Route53-Hosted-Zone-ID>"
    vpn_domain_name = "vpn.ihrunternehmen.de"
    ```

3.  **Den Stack bereitstellen:**
    Initialisieren Sie Terraform, überprüfen Sie den Plan und wenden Sie die Änderungen an.
    ```sh
    terraform init
    terraform plan
    terraform apply
    ```
    Dadurch werden die VPC-Komponenten, EC2-Instanzen, IAM-Rollen, Sicherheitsgruppen und CloudWatch-Alarme provisioniert. Die User-Data-Skripte der Instanzen übernehmen die Installation und Erstkonfiguration von OpenVPN und strongSwan.

## Sicherheitsmaßnahmen

### Multi-Faktor-Authentifizierung (MFA)

Um die Sicherheit zu erhöhen, wird MFA für alle VPN-Verbindungen erzwungen. Dieses Projekt verwendet das Google Authenticator PAM-Modul mit FreeRADIUS.

*   **Setup:** Die Konfiguration umfasst die Installation der `libpam-google-authenticator`-Bibliothek auf dem RADIUS-Server, die Erstellung eines dedizierten PAM-Serviceprofils für FreeRADIUS und die Konfiguration von FreeRADIUS, dieses Profil für die Authentifizierung zu verwenden. Der OpenVPN-Server wird dann mit einem RADIUS-Plugin konfiguriert, um alle Benutzerauthentifizierungsanfragen an den nun MFA-fähigen FreeRADIUS-Server zu delegieren.
*   **Benutzererfahrung:** Beim Verbinden müssen Benutzer ihr Passwort und ein zeitbasiertes Einmalpasswort (TOTP) aus ihrer Authenticator-App angeben.

### Firewall & Sicherheitsgruppen

AWS Security Groups fungieren als zustandsbehaftete (stateful) Firewall, die nach dem Prinzip der geringsten Rechte konfiguriert ist. Nur Verkehr auf den notwendigen Ports ist erlaubt:
*   **Port `1194/UDP`:** Für OpenVPN-Verkehr.
*   **Port `500/UDP` & `4500/UDP`:** Für IPsec (IKEv2)-Verkehr.
*   **Port `22/TCP`:** Für die SSH-Verwaltung (beschränkt auf einen bestimmten Bastion-Host oder eine Unternehmens-IP).

## Hochverfügbarkeit & Automatischer Failover

### Failover-Mechanismus

Die Lösung verwendet eine **DNS-basierte Failover-Strategie**, die von Route 53, CloudWatch und Lambda verwaltet wird.

1.  **Zustandsprüfungen (Health Checks):** Route 53 führt regelmäßige Zustandsprüfungen der primären (aktiven) VPN-Instanz durch.
2.  **Alarmauslösung:** Ein CloudWatch-Alarm überwacht den Status dieser Zustandsprüfungen. Wenn die primäre Instanz für einen festgelegten Zeitraum nicht reagiert, geht der Alarm in den Zustand `ALARM`.
3.  **Automatisierte Behebung:** Der Alarm ist so konfiguriert, dass er eine AWS-Lambda-Funktion auslöst.
4.  **DNS-Umleitung:** Die Lambda-Funktion führt ein Skript aus, das den Route 53 DNS-Eintrag aktualisiert und die IP-Adresse von der ausgefallenen primären Instanz auf die fehlerfreie Standby-Instanz ändert.
5.  **Nahtloser Übergang:** VPN-Clients, die für die Verwendung des Domainnamens (`vpn.ihrunternehmen.de`) konfiguriert sind, verbinden sich nach einer kurzen Unterbrechung automatisch wieder mit der neuen aktiven Instanz.

### Überwachung mit CloudWatch

Der Failover-Prozess wird durch eine Kombination von vorkonfigurierten CloudWatch-Alarmen ausgelöst:
*   **Route 53 Health Check Status:** Der primäre Auslöser für den Failover.
*   **StatusCheckFailed:** Löst aus, wenn die Instanz ihre zugrunde liegenden System- oder Instanzstatusprüfungen nicht besteht.
*   **Hohe CPU-Auslastung:** Ein Alarm zur Erkennung eines überlasteten oder nicht reagierenden Servers.
*   **Benutzerdefinierte VPN-Dienst-Zustandsmetrik:** Ein benutzerdefiniertes Skript, das per Cron-Job jede Minute auf jeder VPN-Instanz ausgeführt wird. Dieses Skript überprüft den Status der `openvpn`- und `strongswan`-Dienst-Daemons. Anschließend sendet es eine benutzerdefinierte Metrik (z.B. `VPNDaemonHealth`, mit dem Wert 1 für fehlerfrei oder 0 für fehlerhaft) an CloudWatch. Ein Alarm wird so konfiguriert, dass er auslöst, wenn diese Metrik für mehrere aufeinanderfolgende Minuten 0 meldet, was auf einen softwareseitigen Ausfall hindeutet, der einen Failover erfordert.

## Performance-Optimierung

Mehrere Maßnahmen wurden ergriffen, um den Netzwerkdurchsatz zu optimieren:
*   **Instanzauswahl:** Es wurden EC2-Instanzen aus einer netzwerkoptimierten Familie (`c5n`, `m5n`) mit hohen Bandbreitenfähigkeiten gewählt.
*   **Kernel-Tuning (`sysctl`):** Kernel-Parameter (`net.core.rmem_max`, `net.core.wmem_max` usw.) auf den Linux-Servern wurden geändert, um die Netzwerkpuffergrößen zu erhöhen und die Leistung unter Last zu verbessern.
*   **VPN-Protokolleinstellungen:**
    *   Für OpenVPN wird **UDP** anstelle von TCP verwendet, um einen geringeren Overhead und eine bessere Leistung zu erzielen.
    *   Es wurde eine moderne, performante Chiffre wie **AES-256-GCM** gewählt, da sie ein ausgezeichnetes Gleichgewicht zwischen Sicherheit und Geschwindigkeit auf Hardware bietet, die AES-NI unterstützt (Standard bei modernen EC2-Instanzen).

## Betriebshandbücher (Runbooks)

Um sicherzustellen, dass das System effektiv verwaltet werden kann, sind Betriebsanleitungen im Verzeichnis `/runbooks` enthalten.
*   `runbooks/USER_ONBOARDING.md`: Schritt-für-Schritt-Anleitung zur Aufnahme neuer Benutzer und Einrichtung ihrer MFA.
*   `runbooks/MANUAL_FAILOVER_TEST.md`: Verfahren zur Simulation eines AZ-Ausfalls, um den automatisierten Wiederherstellungsmechanismus zu validieren.
*   `runbooks/SYSTEM_RECOVERY.md`: Anleitung zur Wiederherstellung des primären Knotens nach einem längeren Ausfall.

## Struktur des Repositorys

```
.
├── terraform/         # Terraform-Module für alle AWS-Ressourcen
├── scripts/           # Bash-Skripte für die Serverkonfiguration und Health Checks
├── lambda/            # Python/Node.js-Code für die Failover-Lambda-Funktion
├── runbooks/          # Schritt-für-Schritt-Betriebsanleitungen (Markdown)
├── clients/           # Beispielkonfigurationsdateien für OpenVPN/IPsec-Clients
├── main.tf            # Root-Terraform-Konfigurationsdatei
├── variables.tf       # Terraform-Variablendefinitionen
└── README.md          # Diese Datei
```

## Mitwirken

Beiträge sind das, was die Open-Source-Community zu einem so großartigen Ort macht, um zu lernen, zu inspirieren und zu erschaffen. Jeder Beitrag, den Sie leisten, wird **sehr geschätzt**.

Wenn Sie einen Vorschlag haben, der dies verbessern würde, forken Sie bitte das Repo und erstellen Sie einen Pull Request. Sie können auch einfach ein Issue mit dem Tag "enhancement" eröffnen.

1.  Forken Sie das Projekt
2.  Erstellen Sie Ihren Feature Branch (`git checkout -b feature/AmazingFeature`)
3.  Committen Sie Ihre Änderungen (`git commit -m 'Add some AmazingFeature'`)
4.  Pushen Sie zum Branch (`git push origin feature/AmazingFeature`)
5.  Öffnen Sie einen Pull Request

## Lizenz

Verteilt unter der MIT-Lizenz. Weitere Informationen finden Sie in der Datei `LICENSE.txt`.
