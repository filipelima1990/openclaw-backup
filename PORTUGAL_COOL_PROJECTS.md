# Top 10 Cool Projects Using Portugal Open Data

**Research Date:** 2026-02-13  
**Sources:** GitHub, Reddit (r/devpt, r/opendata_pt), dados.gov.pt, Central de Dados

---

## 1. 😷 COVID-19 Portugal Data (DSSG-PT)
**Repository:** https://github.com/dssg-pt/covid19pt-data  
**Data Source:** DGS (Direcção Geral de Saúde), ESRI Portugal  
**Stars:** Popular and widely referenced

**What it does:**
- Daily scraping and standardization of COVID-19 data from DGS reports
- Provided clean CSV files during the pandemic (2020-2022)
- Created a reliable data source for analysis and visualization
- Included notebooks for data loading and visualization examples
- Built in collaboration with VOST Portugal to create a public API

**Cool factor:**
- Critical community effort when official data wasn't easily accessible
- Enabled dozens of dashboards and visualizations
- Featured in major Portuguese newspapers (Público)
- Became the de facto standard for COVID-19 data in Portugal

---

## 2. 🔥 Incêndios em Portugal (Central de Dados)
**Repository:** https://github.com/centraldedados/incendios  
**Data Source:** ICFN - Instituto da Conservação da Natureza e Florestas  
**Stars:** 14, Forks: 7

**What it does:**
- Aggregates historical forest fire data from multiple CSV files
- Cleans and standardizes the data (dates in ISO 8601, UTF-8 encoding)
- Provides merged dataset for easy analysis
- Includes scripts for data processing and merging
- Documents all data transformations transparently

**Cool factor:**
- Turns messy government spreadsheets into clean, usable data
- Essential for fire risk analysis and environmental research
- Cites related datasets: air quality, water points, fire risk, fire stations
- Community-driven data cleanup

---

## 3. 🏠 Códigos Postais em Portugal (Central de Dados)
**Repository:** https://github.com/centraldedados/codigos_postais  
**Data Source:** CTT (Correios de Portugal)  
**Stars:** 92, Forks: 38 ⭐ **Most Popular**

**What it does:**
- Complete list of postal codes in Portugal (300,000+ entries)
- Includes mainland and autonomous regions
- Three types: CTT customers with codes, localities, street segments
- Provides goodtables.io validation
- Converted from CTT's text files to clean CSV

**Cool factor:**
- Essential building block for geospatial applications
- Used by countless startups and projects
- Highest starred repository in the Central de Dados ecosystem
- Shows how to convert legacy formats to modern open data

---

## 4. 👪 Gerador de Nomes (Central de Dados)
**Repository:** https://github.com/centraldedados/gerador-nomes  
**Data Source:** INE (Instituto Nacional de Estatística)  
**Stars:** 53, Forks: 13

**What it does:**
- Generates Portuguese names based on real data
- Uses INE's official name databases
- Provides gender-appropriate names
- Useful for testing and generating fake data

**Cool factor:**
- Fun, creative use of official data
- Popular for developers testing Portuguese applications
- Shows that open data doesn't have to be "serious" to be useful
- Web interface at gerador-nomes.centraldedados.pt (probably)

---

## 5. 💀 Óbitos em Portugal (Central de Dados)
**Repository:** https://github.com/centraldedados/obitos  
**Data Source:** Sistema de Informação dos Certificados de Óbito, Ministério da Saúde  
**Coverage:** November 15, 2012 - October 19, 2014

**What it does:**
- Lists death records from Portugal's Death Certificate System
- Provides mortality data by municipality, age, cause
- Uses SQLite for data storage
- Updates daily while data was available

**Cool factor:**
- Important public health dataset
- ODbL license ensures proper attribution
- Enables demographic and epidemiological research
- Rare example of mortality data being made open

---

## 6. 📊 "Como achatar a curva?" (Público)
**Project:** https://www.publico.pt/interactivo/coronavirus-como-achatar-curva-que-revelam-experiencias-paises  
**Data Source:** DGS + COVID-19 Portugal Data (dssg-pt)  
**Creators:** Rui Barros and Dinis Correia (Público)

**What it does:**
- Interactive visualization of COVID-19 spread in Portugal
- Compares Portugal's curve with other countries' experiences
- Real-time updates during the pandemic
- Used the DSSG-PT data repository

**Cool factor:**
- Major newspaper building on open data
- Influenced public policy discussions
- Demonstrates how open data empowers journalism
- Beautiful, accessible interactive visualization

---

## 7. 📈 "Ainda há COVID-19 amanhã?"
**Project:** https://aquelemiguel.github.io/ainda-ha-covid-19-amanha/  
**Creator:** Miguel Mano  
**Data Source:** DSSG-PT COVID-19 data

**What it does:**
- Predictive modeling dashboard for COVID-19 in Portugal
- Uses machine learning to forecast future cases
- Interactive visualization of trends
- Explains uncertainty in predictions

**Cool factor:**
- Advanced ML applied to Portuguese public data
- Helped people understand what "flattening the curve" meant
- Community-driven analytics when official forecasting was limited
- GitHub repository shows the full analysis pipeline

---

## 8. 🗳️ Faltas no Parlamento (Labs Tretas)
**Project:** https://labs.tretas.org/attendance/index/  
**Data Source:** Assembleia da República  
**Organization:** Central de Dados references

**What it does:**
- Tracks attendance of Portuguese deputies in parliamentary sessions
- Visualizes which deputies are most/least present
- Provides raw data and interactive dashboard
- Promotes government transparency

**Cool factor:**
- Holds elected officials accountable
- Uses open data to inform citizens
- Clever use of parliamentary records
- Shows the political impact of transparency initiatives

---

## 9. 🚨 Proteção Civil (Central de Dados)
**Repository:** https://github.com/centraldedados/protecao_civil  
**Data Source:** Autoridade Nacional de Proteção Civil  
**Stars:** 18, Forks: 6

**What it does:**
- Real-time civil protection data and occurrences
- Filters events by nature (e.g., "Incêndios Rurais")
- Scrapes and standardizes emergency data
- Provides API access for emergency monitoring

**Cool factor:**
- Real-time data for emergency response
- Can be filtered for fire incidents, floods, etc.
- Enables citizen safety applications
- Example of live open data feeds

---

## 10. 📋 Exames Nacionais (Data Exams)
**Repository:** https://github.com/glima93/data_exams_06_18_PT  
**Data Source:** Ministério da Educação  
**Coverage:** 2006-2018

**What it does:**
- Contains data on all students who took national exams
- Includes grades, subjects, schools, demographics
- Enables analysis of education trends
- Historical perspective on Portuguese education

**Cool factor:**
- Massive dataset with 12+ years of exam data
- Enables research on educational inequality
- Could identify schools with best/worst performance
- Rare example of individual-level educational data being open

---

## Honorable Mentions

### 📍 GEO API PT (geoapi.pt)
**URL:** https://geoapi.pt  
**Data Source:** Administrative regions, geocoding, postal codes

**What it does:**
- Free open data for Portugal's administrative regions
- Geocoding and reverse geocoding
- Census data integration
- Postal code lookup

**Cool factor:**
- Essential infrastructure for geospatial applications
- Used by hundreds of Portuguese startups
- Documentation and API are well-designed
- Solves a fundamental problem elegantly

---

### 📊 Central de Dados (Organization)
**URL:** https://github.com/centraldedados  
**Repositories:** 49 projects

**What it does:**
- Community-driven open data initiative
- Curates, cleans, and publishes Portuguese datasets
- Covers diverse topics: postal codes, fires, deaths, addresses
- Provides tools for data processing

**Cool factor:**
- Grassroots movement for data transparency
- Shows the power of community curation
- Created foundational datasets used by thousands
- Inspiration for other countries' open data movements

---

### 📰 Public-API-Portugal (DevPT)
**Repository:** https://github.com/devpt-org/public-data-portugal  
**Stars:** 259, Forks: 56

**What it does:**
- Aggregator of public and semi-public Portuguese APIs
- Categorized by sector (Government, Health, Transport, Media)
- Documents authentication requirements
- Community-maintained list

**Cool factor:**
- One-stop shop for Portuguese developers
- Saves hundreds of hours of research
- Shows the vibrancy of Portugal's tech community
- Continuously updated by volunteers

---

## Common Themes Across Projects

### 1. **Data Cleaning & Standardization**
Most projects start by cleaning government data (ISO 8601 dates, UTF-8, removing NULLs)
- Central de Dados is excellent at this (incendios, códigos postais)
- Shows the importance of data engineering before analysis

### 2. **Community-Driven Innovation**
When official sources were insufficient, communities stepped up:
- DSSG-PT: COVID-19 data when DGS didn't provide it
- Central de Dados: Curating datasets government forgot
- DevPT: Aggregating APIs scattered across agencies

### 3. **Journalism + Open Data**
Major newspapers used open data to tell important stories:
- Público's "Como achatar a curva?" on COVID-19
- Likely other interactive pieces on election results, forest fires

### 4. **Building Blocks for Startups**
Postal codes, geocoding, and administrative boundaries became infrastructure:
- Códigos postais: 92 stars, used by countless startups
- GEO API PT: Essential for geospatial applications
- Addresses database: Central de Dados project

### 5. **Civic Accountability**
Projects using open data to promote transparency:
- Faltas no Parlamento: Track deputy attendance
- Proteção Civil: Real-time emergency data for citizen safety
- Óbitos: Mortality data for public health research

---

## Technical Insights

### Popular Tools
- **Python:** pandas, geopandas, sqlalchemy
- **Dashboards:** Power BI, Tableau, Streamlit, D3.js
- **Data Formats:** CSV, JSON, Shapefile, GeoJSON
- **Visualization:** Plotly, Leaflet, Kepler.gl
- **Infrastructure:** GitHub Pages, AWS EC2

### Data Sources
- **Government APIs:** DGS, INE, ICNF, Ministério da Saúde, Ministério da Educação
- **Open Data Portals:** dados.gov.pt, lisboaaberta.cm-lisboa.pt, opendata.porto.digital
- **Legacy Files:** CTT text files, PDF reports, Excel exports
- **Scraper-Based:** When no API exists (Central de Dados approach)

### Licensing
- **ODbL (Open Database License):** Common for databases (obitos)
- **PDDL (Public Domain Dedication and License):** Códigos postais
- **No license specified:** Often the case for scraped data

---

## What Makes These Projects "Cool"?

### 1. **Impact on Society**
- COVID-19 dashboards informed public policy during crisis
- Parliament attendance promotes accountability
- Fire data aids environmental research

### 2. **Technical Excellence**
- Cleaning messy government data
- Building real-time feeds from static sources
- Creating APIs where none existed

### 3. **Community Building**
- Central de Dados: 49 repositories, hundreds of contributors
- DevPT: 259 stars for API aggregator
- DSSG-PT: Became de facto standard during pandemic

### 4. **Democratizing Data**
- Making complex data accessible to everyone
- Providing visualizations instead of raw numbers
- Enabling journalists to tell important stories

### 5. **Foundational Infrastructure**
- Postal codes used by startups as building blocks
- Geocoding APIs powering location-based services
- Address databases powering delivery and logistics

---

## Lessons for Junior Data Engineers

### 1. **Start with a Problem, Not a Dataset**
- Don't just download data; ask: "What question can I answer?"
- Ex: "How can I predict COVID-19 spread?" → Dashboard

### 2. **Clean Data First**
- Most government data is messy
- Invest time in standardization (dates, encoding, missing values)
- Central de Dados excels at this

### 3. **Build Something Useful**
- Don't just visualize; create a tool
- Ex: Gerador de Nomes is simple but widely used
- Códigos postais solved a real problem for developers

### 4. **Give Back to Community**
- Publish your code on GitHub
- Document your data transformations
- Others can build on your work

### 5. **Use What's Available**
- No API? Scrape it (respectfully)
- No shapefiles? Convert the coordinates yourself
- Be resourceful

---

## Where to Find More Projects

### GitHub Organizations
- **centraldedados:** 49 repositories of Portuguese open data
- **dssg-pt:** Data Science for Social Good Portugal
- **devpt-org:** Public data aggregator
- **amagovpt:** Government open data portal (dados.gov.pt)

### Reddit Communities
- **r/opendata_pt:** Portuguese open data discussions
- **r/devpt:** Portuguese developer community
- **r/portugal:** General discussions about data and news

### Data Portals
- **dados.gov.pt:** Official open data portal (20,000+ datasets)
- **centraldedados.pt:** (domain may be for sale now)
- **pordata.pt:** Socioeconomic indicators
- **geoapi.pt:** Geospatial data and API

---

## Conclusion

These 10 projects showcase the incredible creativity and civic engagement of Portugal's data community. From pandemic response to forest fire monitoring, from postal code databases to parliamentary accountability, open data has enabled remarkable innovations.

The key insight: **When government data is open, communities build amazing things.** Whether it's cleaning messy spreadsheets, scraping APIs, or building interactive dashboards, these projects demonstrate the power of data to inform, educate, and hold power accountable.

For junior data engineers, these projects serve as inspiration and practical examples of what's possible with Portugal's rich open data ecosystem.

---

*Document prepared by Billie - 2026-02-13*
