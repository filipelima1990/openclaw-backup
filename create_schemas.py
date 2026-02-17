#!/usr/bin/env python3
"""
Create database schemas for dev and prod environments.
"""

import subprocess
import sys

FOOTBALL_SCHEMA_SQL = """
DROP TABLE IF EXISTS raw_pl_matches CASCADE;

CREATE TABLE raw_pl_matches (
    id SERIAL PRIMARY KEY,
    league_division VARCHAR(10) NOT NULL,
    match_date DATE NOT NULL,
    kickoff_time TIME,
    home_team VARCHAR(100) NOT NULL,
    away_team VARCHAR(100) NOT NULL,
    ft_home_goals INTEGER,
    ft_away_goals INTEGER,
    ft_result VARCHAR(1),
    ht_home_goals INTEGER,
    ht_away_goals INTEGER,
    ht_result VARCHAR(1),
    referee VARCHAR(100),
    home_shots INTEGER,
    away_shots INTEGER,
    home_shots_on_target INTEGER,
    away_shots_on_target INTEGER,
    home_corners INTEGER,
    away_corners INTEGER,
    home_fouls INTEGER,
    away_fouls INTEGER,
    home_yellow_cards INTEGER,
    away_yellow_cards INTEGER,
    home_red_cards INTEGER,
    away_red_cards INTEGER,
    bet365_home_odds DECIMAL(5, 2),
    bet365_draw_odds DECIMAL(5, 2),
    bet365_away_odds DECIMAL(5, 2),
    bet365_over_2_5 DECIMAL(5, 2),
    bet365_under_2_5 DECIMAL(5, 2),
    asian_handicap DECIMAL(4, 1),
    bet365_ah_home_odds DECIMAL(5, 2),
    bet365_ah_away_odds DECIMAL(5, 2),
    season VARCHAR(10) DEFAULT '2526',
    data_source VARCHAR(50) DEFAULT 'football-data.co.uk',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_raw_pl_matches_date ON raw_pl_matches(match_date);
CREATE INDEX idx_raw_pl_matches_home ON raw_pl_matches(home_team);
CREATE INDEX idx_raw_pl_matches_away ON raw_pl_matches(away_team);
CREATE INDEX idx_raw_pl_matches_league ON raw_pl_matches(league_division);
"""

HOUSING_SCHEMA_SQL = """
CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS marts;

GRANT ALL PRIVILEGES ON SCHEMA raw TO dataeng;
GRANT ALL PRIVILEGES ON SCHEMA staging TO dataeng;
GRANT ALL PRIVILEGES ON SCHEMA marts TO dataeng;

CREATE TABLE IF NOT EXISTS raw.listings (
    listing_id VARCHAR(50) NOT NULL,
    url TEXT NOT NULL,
    title TEXT,
    property_type VARCHAR(50),
    typology VARCHAR(10),
    price_eur NUMERIC(12, 2),
    price_per_m2 NUMERIC(10, 2),
    area_m2 NUMERIC(10, 2),
    full_address TEXT,
    city VARCHAR(200),
    province VARCHAR(200),
    district VARCHAR(100),
    agency_name VARCHAR(200),
    scraped_at TIMESTAMP NOT NULL,
    inserted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_raw_listings PRIMARY KEY (listing_id, scraped_at)
);

CREATE INDEX IF NOT EXISTS idx_raw_listings_scraped_at ON raw.listings(scraped_at DESC);
CREATE INDEX IF NOT EXISTS idx_raw_listings_city ON raw.listings(city);
CREATE INDEX IF NOT EXISTS idx_raw_listings_province ON raw.listings(province);
CREATE INDEX IF NOT EXISTS idx_raw_listings_price ON raw.listings(price_eur) WHERE price_eur IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_raw_listings_url ON raw.listings(url);

CREATE OR REPLACE VIEW raw.listings_latest AS
SELECT DISTINCT ON (listing_id)
    listing_id, url, title, property_type, typology,
    price_eur, price_per_m2, area_m2,
    full_address, city, province, district, agency_name,
    scraped_at, inserted_at
FROM raw.listings
ORDER BY listing_id, scraped_at DESC;

CREATE TABLE IF NOT EXISTS staging.price_history (
    id SERIAL PRIMARY KEY,
    listing_id VARCHAR(50) NOT NULL,
    url TEXT NOT NULL,
    price_eur NUMERIC(12, 2),
    price_per_m2 NUMERIC(10, 2),
    scraped_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_price_history UNIQUE (listing_id, scraped_at)
);

CREATE INDEX IF NOT EXISTS idx_price_history_listing ON staging.price_history(listing_id);

COMMENT ON SCHEMA raw IS 'Raw data as ingested from Imovirtual';
COMMENT ON SCHEMA staging IS 'Intermediate transformations via dbt';
COMMENT ON SCHEMA marts IS 'Final analytics-ready tables via dbt';
COMMENT ON TABLE raw.listings IS 'All listing snapshots - one row per listing per scrape date';
COMMENT ON VIEW raw.listings_latest IS 'Latest snapshot of each listing';
"""


def execute_sql(database: str, sql: str):
    """Execute SQL in a PostgreSQL database."""
    cmd = [
        "docker", "exec", "postgres",
        "psql", "-U", "postgres", "-d", database,
        "-c", sql
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"❌ Error in {database}: {result.stderr}")
        return False
    return True


def main():
    """Create all schemas."""
    print("🔧 Creating database schemas...")

    # Football Data schemas
    print("\n📊 Football Data:")
    for env in ["dev", "prod"]:
        db = f"football_data_{env}"
        print(f"  Creating schema in {db}...")
        success = execute_sql(db, FOOTBALL_SCHEMA_SQL)
        if success:
            print(f"  ✅ {db} schema created")
        else:
            print(f"  ❌ {db} schema failed")
            sys.exit(1)

    # Housing schemas
    print("\n🏠 Housing Market:")
    for env in ["dev", "prod"]:
        db = f"portugal_houses_{env}"
        print(f"  Creating schema in {db}...")
        success = execute_sql(db, HOUSING_SCHEMA_SQL)
        if success:
            print(f"  ✅ {db} schema created")
        else:
            print(f"  ❌ {db} schema failed")
            sys.exit(1)

    print("\n✅ All schemas created successfully!")


if __name__ == "__main__":
    main()
