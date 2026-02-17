# Portugal Geographical Database Research
## Comprehensive Guide for Junior Data Engineers

**Research Date:** 2026-02-13  
**Target:** Building a geographical database with maximum granularity (council/parish level)

---

## Executive Summary

Portugal has excellent data infrastructure with multiple open data portals, official statistics, and geographic resources. The most valuable starting points are:

1. **INE (Statistics Portugal)** - The authoritative source for demographic, economic, and social data
2. **dados.gov.pt** - National open data portal with 20,000+ datasets
3. **CAOP (Official Administrative Map)** - Official geographic boundaries
4. **Pordata** - Socioeconomic indicators database
5. **OpenStreetMap** - Community-mapped POI data (restaurants, shops, amenities)

---

## 1. PRIMARY DATA SOURCES

### 1.1 INE - Statistics Portugal (Instituto Nacional de Estatística)
**URL:** https://www.ine.pt/  
**Coverage:** National, District (Distrito), Municipality (Concelho), Parish (Freguesia)

**Key Datasets:**
- **Census Data (Censos 2021):** Population, housing, households at parish level
- **Economic Activity (CAE):** Classification of Economic Activities by parish (see E-REDES dataset)
- **Quarterly Housing Prices:** Metropolitan area and municipality level
- **Population Statistics:** Age distribution, employment, education
- **Agricultural Census:** Parish-level agricultural data

**Geographic Granularity:**
- National → District → Municipality → Parish (Freguesia)
- Statistical Sections and Subsections (sub-parish level for census)

**Access Methods:**
- Web portal: https://www.ine.pt/xportal/xmain?xpid=INE&xpgid=ine_cont_inst
- REST API (limited documentation, may require registration)
- Bulk downloads: Excel, CSV, PDF

---

### 1.2 dados.gov.pt - National Open Data Portal
**URL:** https://dados.gov.pt/en/  
**Coverage:** 20,100+ datasets, 42,900+ files, 422 organizations

**Key Categories:**
- Administrative boundaries
- Demographics
- Education
- Healthcare
- Infrastructure
- Environment
- Economy

**Notable Datasets:**
- Administrative boundary codes and shapes
- School locations and enrollment data
- Hospital and healthcare facility locations
- Public infrastructure data
- Environmental monitoring data

**Access:**
- Open API (CKAN-based)
- Direct downloads (CSV, JSON, XML, Shapefile)
- REST API endpoints

---

### 1.3 CAOP - Carta Administrativa Oficial de Portugal
**Publisher:** Direção-Geral do Território (DGT)  
**URL:** https://www2.gov.pt/en/servicos/consultar-a-carta-administrativa-oficial-de-portugal-caop-  
**Coverage:** Official administrative boundaries

**Geographic Levels:**
- **Distrito** (District): NUTS II level
- **Concelho** (Municipality): LAU 1 level
- **Freguesia** (Parish): LAU 2 level
- **Subsecções** (Subsections): For statistical purposes

**Formats:**
- Shapefile (.shp)
- GeoJSON
- KML
- PostGIS dumps

**Alternative Sources:**
- GeoPostcodes: https://www.geopostcodes.com/country/portugal/shapefile/
- IGISMap: https://www.igismap.com/download-portugal-administrative-boundary-gis-data/

---

### 1.4 Pordata - Socioeconomic Database
**URL:** https://www.pordata.pt/en/  
**Publisher:** Fundação Francisco Manuel dos Santos

**Coverage:**
- Demographics
- Economy
- Education
- Health
- Environment
- Justice
- Technology

**Geographic Granularity:**
- National level (primary)
- Regional (NUTS II)
- Some municipal data available

**Access:**
- Web interface (download as Excel/CSV)
- No public API (as of 2025)

---

## 2. SPECIALIZED DATA SOURCES

### 2.1 Real Estate Data

#### Idealista (Scraping Required)
**URL:** https://www.idealista.pt/  
**Coverage:** Portugal's largest real estate platform

**Data Points:**
- Property prices (sale/rent)
- Property features (size, rooms, floor)
- Geographic location (latitude/longitude)
- Agency contact information

**Access Methods:**
- **Commercial APIs:**
  - Apify Idealista Scraper: $4.99/month + API costs ($0.00151-$0.013/property)
  - Scrapfly: https://scrapfly.io/blog/posts/how-to-scrape-idealista
- **Open Source Scapers:**
  - GitHub: https://github.com/FlowExtractAPI/idealista-scraper-api
  - Multiple Python repositories available

**Granularity:**
- Exact coordinates (most listings)
- Can be geocoded to parish level via coordinates

**Enrichment Ideas:**
- Count properties by parish for market analysis
- Price trends by municipality
- Property type distribution by region
- Days on market metrics

---

### 2.2 Transportation Data

#### GTFS - Public Transportation
**Lisbon Metro:** https://www.transit.land/feeds/f-eyckr-metrodelisboa  
**Lisbon Open Data:** https://dadosabertos.cm-lisboa.pt/dataset?res_format=GTFS  
**GitHub API:** https://github.com/AndreVarandas/transportes-portugal-api

**Coverage:**
- Bus routes and schedules
- Metro lines and stations
- Train routes (CP - Comboios de Portugal)
- Ferry services (Soflusa)

**Granularity:**
- Route level (can geocode stops to parish)
- Real-time data available for some operators

**Enrichment Ideas:**
- Public transport accessibility index by parish
- Stop density per square kilometer
- Travel time analysis between parishes
- Service frequency analysis

---

### 2.3 Economic Activity Data

#### E-REDES Open Data
**URL:** https://e-redes.opendatasoft.com/explore/dataset/codigo-de-atividade-economica-por-distrito-concelho-e-freguesia/export/  
**Publisher:** INE

**Dataset:** Economic Activity Code (CAE) by District, Municipality, Parish

**Fields:**
- Year
- District code
- Municipality code
- Parish code
- CAE code (economic activity classification)
- Number of companies

**Frequency:** Annual

**Coverage:** Continental Portugal

**Enrichment Ideas:**
- Industry diversity index by parish
- Business density per capita
- Sector concentration analysis
- Startup ecosystem mapping

---

### 2.4 Healthcare Data

#### SNS - National Health Service
**URL:** https://www.sns.gov.pt/sns/pesquisa-prestadores/  
**Open Data:** https://dados.gov.pt/en/datasets/fornecimentos-e-servicos-externos-nas-instituicoes-sns-1/

**Coverage:**
- Hospital locations
- Health centers
- Emergency services (urgências)
- Healthcare providers

**Granularity:**
- Facility level (can geocode to parish)

**Enrichment Ideas:**
- Healthcare accessibility index
- Hospital beds per capita by parish
- Emergency service coverage analysis

---

### 2.5 Weather Data

#### IPMA - Portuguese Institute for Sea and Atmosphere
**URL:** http://www.ipma.pt/  
**API:** Available (requires registration)

**Coverage:**
- Weather stations across Portugal
- Historical data
- Forecasts

**Granularity:**
- Station level (can interpolate to parish)

**Enrichment Ideas:**
- Climate zone mapping
- Extreme event analysis by region
- Seasonal tourism indicators

---

## 3. OPEN STREET MAP (COMMUNITY DATA)

**URL:** https://www.openstreetmap.org/  

**Coverage:**
- Points of interest (POIs)
- Road networks
- Building footprints
- Land use
- Amenities (restaurants, shops, schools, hospitals)

**Key Tags for Business Analysis:**
- `amenity=restaurant|cafe|fast_food`
- `shop=supermarket|convenience|mall`
- `tourism=hotel|hostel|attraction`
- `leisure=sports_centre|fitness_centre`

**Access Methods:**
- Overpass API (query by geographic area)
- Geofabrik downloads (country extracts)
- OSMPoisPbf tool for extracting POIs to CSV

**Enrichment Ideas:**
- **McDonald's Analysis:** Query `brand=McDonald's` tag by parish
- Restaurant density per capita
- Tourist attraction clustering
- Retail sector mapping

**Example Queries:**
```bash
# Get all McDonald's in Portugal
[out:json][timeout:25];
area["name"="Portugal"]->.searchArea;
(node["brand"="McDonald's"](area.searchArea);
 way["brand"="McDonald's"](area.searchArea);
 relation["brand"="McDonald's"](area.searchArea);
);
out center;
```

---

## 4. COMMERCIAL DATA PROVIDERS

### 4.1 POI Databases
- **Poidata.io:** McDonald's locations (103 in Portugal as of Oct 2025)
- **Datarade:** Multiple POI datasets available
- **Kaggle:** Various restaurant and location datasets

### 4.2 Real Estate APIs
- **Idealista API:** Commercial (requires partnership)
- **Apify Scrapers:** Monthly subscription
- **Scrapfly:** Pay-per-use scraping service

### 4.3 Company Registries
- **RNPC - Registo Nacional de Pessoas Coletivas:** Company registry (may require paid access)

---

## 5. DATA ENRICHMENT IDEAS FOR JUNIOR DATA ENGINEERS

### 5.1 McDonald's by Council/Parish
**Source:** OpenStreetMap or commercial POI data

**Approach:**
1. Extract McDonald's locations with coordinates
2. Spatial join with parish boundaries (CAOP)
3. Count per parish
4. Calculate density per 1,000 inhabitants (use INE population data)

**Metrics to Track:**
- Total count per parish
- Density per capita
- Distance from parish centroid
- Cluster analysis (Hotspot detection)

---

### 5.2 Houses for Sale by Parish
**Source:** Idealista (scraped)

**Approach:**
1. Scrape Idealista listings with coordinates
2. Geocode to parish level using spatial join
3. Aggregate metrics:
   - Average price per m² by parish
   - Number of listings
   - Price distribution
   - Property type mix

**Advanced Enrichment:**
- Days on market
- Price changes over time
- Correlation with transport proximity
- School district premium analysis

---

### 5.3 Restaurant Density by Parish
**Source:** OpenStreetMap

**Approach:**
1. Extract all `amenity=restaurant`, `cafe`, `fast_food`
2. Spatial join with parish boundaries
3. Calculate:
   - Restaurant count per parish
   - Restaurant density per capita
   - Cuisine diversity index
   - Chain vs independent ratio

---

### 5.4 School Accessibility
**Source:** INE (school locations) + CAOP + OSM (roads)

**Approach:**
1. Get school locations from INE
2. Calculate distance to parish centroid
3. Network analysis using OSM road data
4. Create accessibility index:
   - Schools within 1km
   - Schools within 2km
   - Student-to-school ratio

---

### 5.5 Economic Activity Heatmap
**Source:** E-REDES CAE dataset

**Approach:**
1. Load CAE data by parish
2. Aggregate by industry sectors (CAE sections)
3. Visualize:
   - Top industry per parish
   - Employment concentration
   - Business diversity index (Shannon entropy)
   - Sector correlation matrix

---

### 5.6 Public Transport Coverage
**Source:** GTFS feeds + CAOP

**Approach:**
1. Load GTFS stops with coordinates
2. Create 500m buffers around stops
3. Calculate coverage percentage of each parish
4. Metrics:
   - % of parish area within 500m of stop
   - Stops per km²
   - Service frequency weighted coverage

---

### 5.7 Healthcare Accessibility Index
**Source:** SNS locations + INE population data

**Approach:**
1. Geocode healthcare facilities
2. Calculate travel time or distance
3. Weight by facility type (hospital > health center)
4. Create composite index:
   - Hospital beds per 10,000
   - Emergency response coverage
   - Primary care density

---

### 5.8 Housing Market Segmentation
**Source:** Idealista + INE (demographics) + E-REDES (economy)

**Approach:**
1. Cluster parishes by:
   - Average property price
   - Price growth rate
   - Population density
   - Income level
   - Economic activity mix
2. Use K-means or hierarchical clustering
3. Identify market segments:
   - Premium markets (central cities)
   - Commuter zones
   - Rural/low-cost areas
   - Emerging markets

---

## 6. TECHNICAL RECOMMENDATIONS

### 6.1 Database Architecture
**Recommended Stack:**
- **PostgreSQL with PostGIS** - Best for geospatial queries
- **Python** - Data extraction and processing
- **Apache Airflow / Prefect** - Orchestration
- **Streamlit / Metabase** - Visualization

**Why PostGIS:**
- Native spatial joins (ST_Contains, ST_Intersects)
- Efficient geocoding operations
- Standard SQL interface
- Strong community support

---

### 6.2 Data Modeling
**Core Tables:**
```sql
-- Geographic hierarchy
CREATE TABLE districts (
  code VARCHAR(10) PRIMARY KEY,
  name VARCHAR(100),
  geometry GEOMETRY(MultiPolygon, 4326)
);

CREATE TABLE municipalities (
  code VARCHAR(10) PRIMARY KEY,
  district_code VARCHAR(10) REFERENCES districts(code),
  name VARCHAR(100),
  geometry GEOMETRY(MultiPolygon, 4326)
);

CREATE TABLE parishes (
  code VARCHAR(10) PRIMARY KEY,
  municipality_code VARCHAR(10) REFERENCES municipalities(code),
  name VARCHAR(100),
  population INTEGER,
  area_km2 NUMERIC,
  geometry GEOMETRY(MultiPolygon, 4326)
);

-- Points of interest
CREATE TABLE pois (
  id SERIAL PRIMARY KEY,
  osm_id BIGINT,
  name VARCHAR(200),
  category VARCHAR(50),
  subcategory VARCHAR(50),
  brand VARCHAR(100),
  geometry GEOMETRY(Point, 4326),
  parish_code VARCHAR(10) REFERENCES parishes(code)
);

-- Real estate
CREATE TABLE properties (
  id SERIAL PRIMARY KEY,
  idealista_id BIGINT UNIQUE,
  price NUMERIC,
  area_m2 NUMERIC,
  price_per_m2 NUMERIC,
  property_type VARCHAR(50),
  bedrooms INTEGER,
  bathrooms INTEGER,
  floor VARCHAR(20),
  latitude NUMERIC,
  longitude NUMERIC,
  parish_code VARCHAR(10) REFERENCES parishes(code),
  listing_date DATE
);
```

---

### 6.3 Data Extraction Strategy

**Phase 1: Foundation (Week 1-2)**
1. Download CAOP shapefiles (parish boundaries)
2. Import to PostGIS
3. Load INE parish-level population data
4. Create geographic hierarchy tables

**Phase 2: Open Data Integration (Week 3-4)**
1. Extract E-REDES economic activity data
2. Download OSM POI data (Overpass API)
3. Load school and healthcare facility data
4. Build spatial joins with parishes

**Phase 3: Real Estate (Week 5-6)**
1. Set up Idealista scraper (Apify or custom)
2. Run initial scrape (target 50,000+ listings)
3. Geocode to parish level
4. Build price aggregates

**Phase 4: Transportation (Week 7-8)**
1. Download GTFS feeds (Lisbon, Porto)
2. Import stops to PostGIS
3. Calculate coverage metrics
4. Build accessibility indices

**Phase 5: Enrichment (Week 9-10)**
1. Build composite indices (accessibility, market segments)
2. Create data quality checks
3. Build dashboards
4. Document data lineage

---

### 6.4 Automation
**Recommended Tools:**
- **Apache Airflow** or **Prefect** (you already use Prefect!)
- **Python scripts** for data extraction
- **Cron jobs** for daily/weekly updates

**Schedules:**
- **Daily:** Real estate prices (Idealista)
- **Weekly:** OSM updates
- **Monthly:** INE data updates (when available)
- **Quarterly:** Census-related updates

---

## 7. DATA QUALITY CONSIDERATIONS

### 7.1 Common Issues
- **Missing coordinates:** Some datasets only have parish codes, not precise locations
- **Outdated boundaries:** CAOP updates annually, verify latest version
- **Inconsistent codes:** Different sources may use different coding schemes
- **Duplicate records:** POI data often has duplicates

### 7.2 Validation Rules
```sql
-- Check for missing geometry
SELECT COUNT(*) FROM parishes WHERE geometry IS NULL;

-- Check for population outliers
SELECT parish_code, population 
FROM parishes 
WHERE population < 0 OR population > 100000;

-- Check for coordinate validity
SELECT COUNT(*) FROM pois 
WHERE ST_X(geometry) < -10 OR ST_X(geometry) > -6 
   OR ST_Y(geometry) < 36 OR ST_Y(geometry) > 42;

-- Check for duplicate POIs
SELECT osm_id, name, COUNT(*) 
FROM pois 
GROUP BY osm_id, name 
HAVING COUNT(*) > 1;
```

---

## 8. SOCIAL MEDIA INSIGHTS

### 8.1 Reddit Discussions (r/opendata_pt, r/portugal, r/PortugalExpats)

**Key Findings:**
- INE is widely respected as the authoritative source
- Many users recommend INE for housing price data
- DGT (Direção Geral do Território) is preferred for geographic data
- OpenStreetMap is well-maintained for Portugal
- Real estate data from Idealista is used for market analysis

**Challenges Mentioned:**
- Some INE data only available as PDF or Excel exports
- No public API for Pordata
- INE APIs have limited documentation
- Real estate data requires scraping (no official API)

---

## 9. COST ESTIMATES

### 9.1 Free Sources
- INE data: FREE
- dados.gov.pt: FREE
- CAOP boundaries: FREE
- OpenStreetMap: FREE
- Pordata: FREE (web only)

### 9.2 Paid Sources (Optional)
- Idealista scraping: $5-50/month depending on volume
- Commercial POI databases: $100-500/month
- Company registry access: Varies

---

## 10. NEXT STEPS FOR JUNIOR DATA ENGINEERS

### Immediate Actions (First 2 Weeks)
1. **Set up PostgreSQL with PostGIS**
2. **Download CAOP 2024 boundaries** (parish level)
3. **Load INE population data** (latest census 2021)
4. **Create geographic hierarchy** (District → Municipality → Parish)

### Learning Projects
1. **McDonald's Mapping Project:**
   - Extract McDonald's from OSM
   - Count per parish
   - Visualize on map
   - Calculate density per capita

2. **Real Estate Price Analysis:**
   - Scrape 1,000 Idealista listings
   - Geocode to parishes
   - Build parish-level price aggregates
   - Create heatmap

3. **Accessibility Index:**
   - Load school locations
   - Calculate distance to parish centroids
   - Build composite index
   - Identify underserved areas

### Skill Development
- **PostGIS:** Spatial joins, buffering, distance calculations
- **Python:** pandas, geopandas, sqlalchemy
- **ETL:** Airflow or Prefect for automation
- **Visualization:** Streamlit, Folium, Kepler.gl
- **Web Scraping:** BeautifulSoup, Selenium, or commercial tools

---

## 11. REFERENCE LINKS

### Official Portuguese Data Sources
- INE: https://www.ine.pt/
- dados.gov.pt: https://dados.gov.pt/en/
- CAOP: https://www2.gov.pt/en/servicos/consultar-a-carta-administrativa-oficial-de-portugal-caop-
- DGT: https://www.dgterritorio.gov.pt/
- SNS: https://www.sns.gov.pt/
- IPMA: http://www.ipma.pt/

### Community Data
- OpenStreetMap: https://www.openstreetmap.org/
- Overpass API: https://overpass-api.de/
- Pordata: https://www.pordata.pt/en/

### Tools & APIs
- Geofabrik OSM extracts: http://download.geofabrik.de/
- OSMPoisPbf: https://wiki.openstreetmap.org/wiki/OsmPoisPbf
- Transportes Portugal API: https://github.com/AndreVarandas/transportes-portugal-api

### Scraping Tools
- Apify Idealista Scraper: https://apify.com/igolaizola/idealista-scraper/api/openapi
- Scrapfly Guide: https://scrapfly.io/blog/posts/how-to-scrape-idealista
- GitHub scrapers: https://github.com/FlowExtractAPI/idealista-scraper-api

### Geographic Data
- GeoPostcodes: https://www.geopostcodes.com/country/portugal/shapefile/
- IGISMap: https://www.igismap.com/download-portugal-administrative-boundary-gis-data/

---

## 12. CONCLUSION

Portugal has excellent data infrastructure for building a comprehensive geographical database. Starting with INE, dados.gov.pt, and CAOP will give you a solid foundation at parish-level granularity. Enriching with OpenStreetMap POIs and real estate data will provide business insights.

The key advantage: Most core data is **free and official** from government sources, making this an ideal project for junior data engineers to learn data engineering concepts while building something valuable.

**Recommended First Project:** Start with McDonald's mapping using OSM data - it's free, has clear deliverables, and demonstrates the power of spatial joins with parish boundaries.

---

*Document prepared by Billie - 2026-02-13*
