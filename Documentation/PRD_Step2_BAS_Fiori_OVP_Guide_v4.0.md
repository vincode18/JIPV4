# Step 2: Fiori OVP Implementation Guide — SAP Business Application Studio (BAS)

## JIP Milestone Aging Dashboard V4 — Frontend Development

**Companion to PRD v4.0 (Backend CDS) and PRD MDE (Metadata Extension)**

---

## 1. Prerequisites Checklist

Before starting in BAS, ensure these backend items are completed:

| # | Item | Status | Transaction/Tool |
|---|------|--------|-----------------|
| 1 | `ZC_JIPV4_AGING` CDS Consumption View activated | Required | Eclipse ADT |
| 2 | `ZE_JIPV4_AGING` Metadata Extension activated | Required | Eclipse ADT |
| 3 | `@OData.publish: true` generates OData V2 service | Required | Auto via SADL |
| 4 | OData service registered in Gateway | Required | `/IWFND/MAINT_SERVICE` |
| 5 | OData service tested with data | Required | `/IWFND/GW_CLIENT` |
| 6 | BAS Dev Space (SAP Fiori type) running | Required | SAP BTP Cockpit |
| 7 | Destination to S/4HANA backend configured | Required | SAP BTP Cockpit |

### 1.1 Register OData Service (Backend)

In SAP GUI, go to `/IWFND/MAINT_SERVICE`:

1. Click **Add Service**
2. System Alias: `LOCAL`
3. Search for service: `ZC_JIPV4_AGING_CDS`
4. Select and click **Add Selected Services**
5. Package: `$TMP` (or your transport package)

### 1.2 Test OData Service

In SAP GUI, go to `/IWFND/GW_CLIENT`:

```
GET /sap/opu/odata/sap/ZC_JIPV4_AGING_CDS/$metadata
```

Verify you see the entity type `ZC_JIPV4_AGINGType` with all fields.

Then test data:
```
GET //sap/opu/odata/sap/ZC_JIPV4_AGING_CDS/?$format=xml
```

### 1.3 Configure BTP Destination

In SAP BTP Cockpit → Destinations → New Destination:

| Property | Value |
|----------|-------|
| Name | `S4HANA_DEV` (or your system name) |
| Type | HTTP |
| URL | `https://<your-s4hana-host>:<port>` |
| Proxy Type | OnPremise (if via Cloud Connector) |
| Authentication | BasicAuthentication |
| User | Your SAP user |
| Password | Your SAP password |

Additional Properties:
```
sap-client = 030
WebIDEUsage = odata_abap,dev_abap
WebIDEEnabled = true
WebIDESystem = S4DEV
HTML5.DynamicDestination = true
```

---

## 2. Create BAS Dev Space

1. Open **SAP Business Application Studio** from BTP Cockpit
2. Click **Create Dev Space**
3. Name: `JIP_Dashboard_V4`
4. Type: **SAP Fiori**
5. Additional Extensions: (default is fine)
6. Click **Create Dev Space**
7. Wait for status: **RUNNING**
8. Click the Dev Space name to open

---

## 3. Generate OVP Application

### 3.1 Open Application Generator

1. In BAS, press **Ctrl+Shift+P** (Command Palette)
2. Type: `Fiori: Open Application Generator`
3. Click to open

### 3.2 Template Selection

| Field | Value |
|-------|-------|
| Template Type | SAP Fiori Elements |
| Floorplan | **Overview Page** |

Click **Next**.

### 3.3 Data Source

| Field | Value |
|-------|-------|
| Data Source | Connect to an SAP System |
| System | `S4HANA_DEV` (your destination) |
| Service | `ZC_JIPV4_AGING_CDS` (search for it) |

Click **Next**.

### 3.4 Entity Selection

| Field | Value |
|-------|-------|
| OData Entity Set | `ZC_JIPV4_AGING` |
| Filter Entity | `ZC_JIPV4_AGING` |

Click **Next**.

### 3.5 Project Attributes

| Field | Value |
|-------|-------|
| Module Name | `zjipv4aging` |
| Application Title | `JIP Milestone Aging Dashboard V4` |
| Application Namespace | `com.sap.jipv4` |
| Description | `JIP Parts Aging Monitoring - OVP Dashboard` |
| Minimum SAPUI5 Version | (latest available) |
| Add deployment configuration | Yes |
| Add FLP configuration | Yes |

Click **Next**.

### 3.6 Deployment Configuration

| Field | Value |
|-------|-------|
| Target | ABAP |
| Destination | `S4HANA_DEV` |
| SAPUI5 ABAP Repository | `ZJIPV4_AG_OVP` |
| Package | `$TMP` (or your transport package) |
| Transport Request | (your TR or create new) |

Click **Next**.

### 3.7 Fiori Launchpad Configuration

| Field | Value |
|-------|-------|
| Semantic Object | `JIPAging` |
| Action | `display` |
| Title | `JIP Milestone Aging V4` |
| Subtitle | `Parts Aging Dashboard` |

Click **Finish**. Wait for project generation to complete.

### 3.7.1 Open Generated Project

After generation finishes (you'll see a success message in the terminal), the project folder `zjipv4aging` appears in the Explorer:

1. In the **Explorer** panel (left sidebar), you'll see the new `zjipv4aging` folder
2. **Right-click** on `zjipv4aging` folder
3. Select **Open in Integrated Terminal** (or use Ctrl+`)
4. The terminal opens at the project root

**Alternatively, open via File Menu:**
1. Click **File** > **Open Folder**
2. Navigate to the BAS workspace directory
3. Select the `zjipv4aging` folder
4. Click **Open**

The project is now ready for configuration. You can start editing `webapp/manifest.json` to configure the OVP cards.

---

## 4. Project Structure

After generation, your project structure looks like:

```
zjipv4aging/
├── webapp/
│   ├── Component.js
│   ├── manifest.json          ← Main configuration file
│   ├── annotations/
│   │   └── annotation.xml     ← Local OData annotations
│   ├── i18n/
│   │   └── i18n.properties    ← Translations
│   ├── localService/
│   │   └── metadata.xml       ← Local metadata for mock
│   └── test/
│       └── ...
├── ui5.yaml
├── ui5-local.yaml
├── package.json
└── xs-app.json
```

---

## 5. Configure manifest.json — OVP Cards

This is the most important file. Open `webapp/manifest.json` and configure the OVP cards.

### 5.1 Model Configuration

In `sap.app` → `dataSources`, verify:

```json
{
  "sap.app": {
    "dataSources": {
      "mainService": {
        "uri": "/sap/opu/odata/sap/ZC_JIPV4_AGING_CDS/",
        "type": "OData",
        "settings": {
          "odataVersion": "2.0",
          "annotations": ["annotation0"],
          "localUri": "localService/metadata.xml"
        }
      },
      "annotation0": {
        "uri": "/sap/opu/odata/IWFND/CATALOGSERVICE;v=2/Annotations(TechnicalName='ZC_JIPV4_AGING_CDS',Version='0001')/$value/",
        "type": "ODataAnnotation",
        "settings": {
          "localUri": "annotations/annotation.xml"
        }
      }
    }
  }
}
```

### 5.2 OVP Settings

In `sap.ovp`, configure the global settings and cards:

```json
{
  "sap.ovp": {
    "globalFilterModel": "mainService",
    "globalFilterEntityType": "ZC_JIPV4_AGINGType",
    "containerLayout": "resizable",
    "enableLiveFilter": true,
    "considerAnalyticalParameters": false,
    "cards": {

      "card01_JIPPerPlant": {
        "model": "mainService",
        "template": "sap.ovp.cards.charts.analytical",
        "settings": {
          "title": "Total JIP per Plant",
          "subtitle": "Count by Plant",
          "entitySet": "ZC_JIPV4_AGING",
          "chartAnnotationPath": "com.sap.vocabularies.UI.v1.Chart#ChartJIPPerPlant",
          "presentationAnnotationPath": "com.sap.vocabularies.UI.v1.PresentationVariant#PVChartByPlant",
          "dataPointAnnotationPath": "com.sap.vocabularies.UI.v1.DataPoint#AgingBucket"
        }
      },

      "card02_HistoricalJIP": {
        "model": "mainService",
        "template": "sap.ovp.cards.charts.analytical",
        "settings": {
          "title": "Historical JIP - All Plants",
          "subtitle": "Monthly by Aging Bucket",
          "entitySet": "ZC_JIPV4_AGING",
          "chartAnnotationPath": "com.sap.vocabularies.UI.v1.Chart#ChartHistoricalJIP",
          "presentationAnnotationPath": "com.sap.vocabularies.UI.v1.PresentationVariant#PVChartHistorical"
        }
      },

      "card03_AgingPerPlant": {
        "model": "mainService",
        "template": "sap.ovp.cards.charts.analytical",
        "settings": {
          "title": "Aging per Plant",
          "subtitle": "Monthly by Aging Bucket",
          "entitySet": "ZC_JIPV4_AGING",
          "chartAnnotationPath": "com.sap.vocabularies.UI.v1.Chart#ChartAgingPerPlant",
          "presentationAnnotationPath": "com.sap.vocabularies.UI.v1.PresentationVariant#PVChartHistorical"
        }
      },

      "card04_ActivityBreakdown": {
        "model": "mainService",
        "template": "sap.ovp.cards.charts.analytical",
        "settings": {
          "title": "Activity Type Breakdown",
          "subtitle": "Count by Activity",
          "entitySet": "ZC_JIPV4_AGING",
          "chartAnnotationPath": "com.sap.vocabularies.UI.v1.Chart#ChartActivityBreakdown",
          "presentationAnnotationPath": "com.sap.vocabularies.UI.v1.PresentationVariant#PVChartActivity"
        }
      },

      "card05_MonthlyTrend": {
        "model": "mainService",
        "template": "sap.ovp.cards.charts.analytical",
        "settings": {
          "title": "Monthly Trend by Activity",
          "subtitle": "Activity Type Stacked",
          "entitySet": "ZC_JIPV4_AGING",
          "chartAnnotationPath": "com.sap.vocabularies.UI.v1.Chart#ChartMonthlyTrend",
          "presentationAnnotationPath": "com.sap.vocabularies.UI.v1.PresentationVariant#PVChartHistorical"
        }
      },

      "card06_AvgAging": {
        "model": "mainService",
        "template": "sap.ovp.cards.charts.analytical",
        "settings": {
          "title": "Avg Aging by Plant & Activity",
          "subtitle": "Combination Chart",
          "entitySet": "ZC_JIPV4_AGING",
          "chartAnnotationPath": "com.sap.vocabularies.UI.v1.Chart#ChartAvgAging"
        }
      },

      "card07_DetailTable": {
        "model": "mainService",
        "template": "sap.ovp.cards.table",
        "settings": {
          "title": "JIP Parts Detail",
          "subtitle": "All Items",
          "entitySet": "ZC_JIPV4_AGING",
          "presentationAnnotationPath": "com.sap.vocabularies.UI.v1.PresentationVariant#DefaultSort",
          "annotationPath": "com.sap.vocabularies.UI.v1.LineItem",
          "addODataSelect": true
        }
      }
    }
  }
}
```

### 5.3 Selection Variants (Local Annotations)

Since `@UI.selectionVariant` is not supported in CDS MDE syntax, define them in `webapp/annotations/annotation.xml`:

```xml
<edmx:Edmx xmlns:edmx="http://docs.oasis-open.org/odata/ns/edmx" Version="4.0">
  <edmx:Reference Uri="/sap/opu/odata/sap/ZC_JIPV4_AGING_CDS/$metadata">
    <edmx:Include Namespace="cds_zjipv4aging" Alias="SAP"/>
  </edmx:Reference>
  <edmx:Reference Uri="https://sap.github.io/odata-vocabularies/vocabularies/UI.xml">
    <edmx:Include Namespace="com.sap.vocabularies.UI.v1" Alias="UI"/>
  </edmx:Reference>

  <edmx:DataServices>
    <Schema xmlns="http://docs.oasis-open.org/odata/ns/edm"
            Namespace="local.annotation">

      <Annotations Target="SAP.ZC_JIPV4_AGINGType">

        <!-- Selection Variant: Open Items (Exclude GI) -->
        <Annotation Term="UI.SelectionVariant" Qualifier="SVOpenItems">
          <Record>
            <PropertyValue Property="Text" String="Open Items (Exclude GI)"/>
            <PropertyValue Property="SelectOptions">
              <Collection>
                <Record Type="UI.SelectOptionType">
                  <PropertyValue Property="PropertyName"
                                 PropertyPath="CurrentMilestone"/>
                  <PropertyValue Property="Ranges">
                    <Collection>
                      <Record Type="UI.SelectionRangeType">
                        <PropertyValue Property="Sign"
                                       EnumMember="UI.SelectionRangeSignType/E"/>
                        <PropertyValue Property="Option"
                                       EnumMember="UI.SelectionRangeOptionType/EQ"/>
                        <PropertyValue Property="Low" String="GI"/>
                      </Record>
                    </Collection>
                  </PropertyValue>
                </Record>
              </Collection>
            </PropertyValue>
          </Record>
        </Annotation>

        <!-- Selection Variant: Critical Aging (60+ and 70+) -->
        <Annotation Term="UI.SelectionVariant" Qualifier="SVCriticalAging">
          <Record>
            <PropertyValue Property="Text" String="Critical Aging (60+ and 70+)"/>
            <PropertyValue Property="SelectOptions">
              <Collection>
                <Record Type="UI.SelectOptionType">
                  <PropertyValue Property="PropertyName"
                                 PropertyPath="AgingBucket"/>
                  <PropertyValue Property="Ranges">
                    <Collection>
                      <Record Type="UI.SelectionRangeType">
                        <PropertyValue Property="Sign"
                                       EnumMember="UI.SelectionRangeSignType/E"/>
                        <PropertyValue Property="Option"
                                       EnumMember="UI.SelectionRangeOptionType/EQ"/>
                        <PropertyValue Property="Low" String="OK"/>
                      </Record>
                    </Collection>
                  </PropertyValue>
                </Record>
              </Collection>
            </PropertyValue>
          </Record>
        </Annotation>

        <!-- Selection Variant: EWM Plants Only -->
        <Annotation Term="UI.SelectionVariant" Qualifier="SVEWMOnly">
          <Record>
            <PropertyValue Property="Text" String="EWM Plants Only"/>
            <PropertyValue Property="SelectOptions">
              <Collection>
                <Record Type="UI.SelectOptionType">
                  <PropertyValue Property="PropertyName"
                                 PropertyPath="WmEwmType"/>
                  <PropertyValue Property="Ranges">
                    <Collection>
                      <Record Type="UI.SelectionRangeType">
                        <PropertyValue Property="Sign"
                                       EnumMember="UI.SelectionRangeSignType/I"/>
                        <PropertyValue Property="Option"
                                       EnumMember="UI.SelectionRangeOptionType/EQ"/>
                        <PropertyValue Property="Low" String="EWM"/>
                      </Record>
                    </Collection>
                  </PropertyValue>
                </Record>
              </Collection>
            </PropertyValue>
          </Record>
        </Annotation>

      </Annotations>
    </Schema>
  </edmx:DataServices>
</edmx:Edmx>
```

---

## 6. Run and Preview

### 6.1 Install Dependencies

Open Terminal in BAS (Ctrl+`):

```bash
cd zjipv4aging
npm install
```

### 6.2 Preview Application

**Option A — Run Configuration:**
1. Right-click `webapp` folder
2. Select **Preview Application**
3. Choose `start-noflp` or `start`
4. Browser opens with the OVP dashboard

**Option B — Terminal:**
```bash
npm run start
```

**Option C — Command Palette:**
1. Ctrl+Shift+P → `Fiori: Open Run Configurations`
2. Click the green play button

### 6.3 Expected Result

The dashboard should display:
- **Filter Bar** at top with Plant, Activity Type, Aging Bucket, WM/EWM, Warehouse No, Milestone, ABC
- **Card 1**: Total JIP per Plant (horizontal bar chart)
- **Card 2**: Historical JIP (stacked column by aging bucket)
- **Card 3**: Aging per Plant (stacked column)
- **Card 4**: Activity Breakdown (horizontal bar)
- **Card 5**: Monthly Trend (stacked by activity type)
- **Card 6**: Avg Aging (combination chart)
- **Card 7**: Detail Table (sortable, with criticality colors)

---

## 7. Guided Development (Optional — Add More Cards)

BAS provides a guided wizard for adding OVP cards:

1. Right-click project → **SAP Fiori tools - Open Guided Development**
2. Under **Overview Page**, select card type:
   - **Analytical Card** (for charts)
   - **Table Card** (for data tables)
   - **List Card** (for simple lists)
   - **Stack Card** (for drill-down)
3. Fill in the fields (Entity Set, Chart Qualifier, etc.)
4. Click **Apply** — code auto-generates in `manifest.json`

---

## 8. Local Annotations — Adding More UI via annotation.xml

You can add additional annotations beyond what the CDS MDE provides. Common additions:

### 8.1 Selection Presentation Variant (Combines Filter + Sort + Chart)

Add to `annotation.xml` to link a selection variant with a presentation variant for a card:

```xml
<Annotation Term="UI.SelectionPresentationVariant" Qualifier="SPVOpenByPlant">
  <Record>
    <PropertyValue Property="Text" String="Open Items by Plant"/>
    <PropertyValue Property="SelectionVariant"
                   AnnotationPath="@UI.SelectionVariant#SVOpenItems"/>
    <PropertyValue Property="PresentationVariant"
                   AnnotationPath="@UI.PresentationVariant#PVChartByPlant"/>
  </Record>
</Annotation>
```

Then reference in `manifest.json`:
```json
"selectionPresentationAnnotationPath": "com.sap.vocabularies.UI.v1.SelectionPresentationVariant#SPVOpenByPlant"
```

---

## 9. Deploy to ABAP Repository

### 9.1 Build

```bash
npm run build
```

### 9.2 Deploy

**Option A — Command Line:**
```bash
npm run deploy
```

**Option B — Command Palette:**
1. Ctrl+Shift+P → `Fiori: Deploy Application`
2. Select destination: `S4HANA_DEV`
3. BSP Application Name: `ZJIPV4_AGING_OVP`
4. Package: your package
5. Transport Request: your TR
6. Click **Deploy**

### 9.3 Verify Deployment

In SAP GUI:
1. Go to `/UI5/APP_INDEX_CALCULATE` — run to refresh app index
2. Go to `/UI2/FLP` — Fiori Launchpad
3. Search for tile: `JIP Milestone Aging V4`

---

## 10. Register in Fiori Launchpad

### 10.1 Create Catalog (PFCG or /UI2/FLPD_CUST)

In `/UI2/FLPD_CUST`:

1. **Create Catalog**: `ZJIPV4_AGING_CAT`
   - Title: `JIP Milestone Aging V4`

2. **Create Target Mapping**:
   | Field | Value |
   |-------|-------|
   | Semantic Object | `JIPAging` |
   | Action | `display` |
   | Application Type | SAPUI5 Fiori App |
   | URL | `/sap/bc/ui5_ui5/sap/zjipv4_aging_ovp` |
   | Component | `com.sap.jipv4` |

3. **Create Tile**:
   | Field | Value |
   |-------|-------|
   | Title | `JIP Milestone Aging V4` |
   | Subtitle | `Parts Aging Dashboard` |
   | Semantic Object | `JIPAging` |
   | Action | `display` |
   | Tile Type | Static |
   | Icon | `sap-icon://bar-chart` |

4. **Assign Catalog to Role** in PFCG

---

## 11. Troubleshooting

| Issue | Cause | Fix |
|-------|-------|-----|
| Cards show "No data" | OData service returns empty | Test in `/IWFND/GW_CLIENT` first |
| Chart cards not rendering | Chart annotation qualifier mismatch | Verify `chartAnnotationPath` matches MDE qualifier exactly |
| Filter bar empty | Selection fields not in MDE | Check `@UI.selectionField` in `ZE_JIPV4_AGING` |
| Criticality colors missing | `AgingCriticality` field not exposed | Ensure field is in `ZC_JIPV4_AGING` select list |
| "Service unavailable" error | Destination not configured | Check BTP destination properties |
| CORS error in preview | Missing proxy config | Use `ui5-local.yaml` proxy settings |
| App not in Launchpad | App index not refreshed | Run `/UI5/APP_INDEX_CALCULATE` |
| Metadata errors | MDE not activated | Activate `ZE_JIPV4_AGING`, clear metadata cache |
| Cards show wrong data | EntitySet mismatch | Verify `entitySet` in each card config |
| Deploy fails | Transport locked | Check TR status in SE09 |

---

## 12. Files Reference

| File | Purpose | When to Edit |
|------|---------|-------------|
| `manifest.json` | OVP card definitions, data source, FLP config | Add/modify cards |
| `annotations/annotation.xml` | Local OData annotations (selection variants) | Add annotations not in CDS MDE |
| `i18n/i18n.properties` | Translations | Change labels/titles |
| `Component.js` | App component (usually untouched) | Custom extensions |
| `ui5.yaml` | SAPUI5 version, build config | Version changes |
| `ui5-local.yaml` | Local preview proxy settings | Proxy/destination issues |
| `xs-app.json` | App router config (Cloud Foundry) | CF deployment |
| `package.json` | Dependencies, scripts | Add libraries |

---

## 13. Development Checklist

- [ ] BAS Dev Space created and running (SAP Fiori type)
- [ ] BTP Destination to S/4HANA configured with WebIDEEnabled
- [ ] OData service `ZC_JIPV4_AGING_CDS` registered in `/IWFND/MAINT_SERVICE`
- [ ] OData service tested with `$metadata` and `$top=10`
- [ ] OVP project generated from template
- [ ] `manifest.json` configured with 7 cards (6 charts + 1 table)
- [ ] `annotation.xml` contains 3 selection variants (SVOpenItems, SVCriticalAging, SVEWMOnly)
- [ ] Local preview working (`npm run start`)
- [ ] Filter bar shows: Plant, ActivityType, AgingBucket, WmEwmType, WarehouseNumber, CurrentMilestone, ABCIndicator, PeriodMonth
- [ ] Chart cards render with correct data
- [ ] Table card shows line items with criticality colors
- [ ] Aging bucket colors: Green (OK), Yellow (60+), Red (70+)
- [ ] App deployed to ABAP repository (`ZJIPV4_AGING_OVP`)
- [ ] App index refreshed (`/UI5/APP_INDEX_CALCULATE`)
- [ ] Tile created in Fiori Launchpad
- [ ] Catalog assigned to user role in PFCG
- [ ] End-to-end test: Launchpad → Tile → Dashboard → Filter → Charts → Table
