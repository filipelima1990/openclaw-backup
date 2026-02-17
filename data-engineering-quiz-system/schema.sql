-- Data Engineering Quiz System - PostgreSQL Schema
-- Run this to initialize the database

-- Extensions (if needed)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table: stores quiz participant state
CREATE TABLE IF NOT EXISTS users (
    user_id VARCHAR(255) PRIMARY KEY,
    username VARCHAR(255),
    current_difficulty INTEGER NOT NULL DEFAULT 2 CHECK (current_difficulty BETWEEN 1 AND 4),
    current_streak INTEGER NOT NULL DEFAULT 0 CHECK (current_streak >= 0),
    consecutive_correct INTEGER NOT NULL DEFAULT 0 CHECK (consecutive_correct >= 0),
    total_questions_answered INTEGER NOT NULL DEFAULT 0 CHECK (total_questions_answered >= 0),
    total_correct_answers INTEGER NOT NULL DEFAULT 0 CHECK (total_correct_answers >= 0),
    timezone VARCHAR(50) DEFAULT 'UTC',
    opt_in_daily_quiz BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Questions table: question bank (static and LLM-generated)
CREATE TABLE IF NOT EXISTS questions (
    id VARCHAR(255) PRIMARY KEY,
    question_text TEXT NOT NULL,
    options JSONB NOT NULL CHECK (jsonb_array_length(options) = 4),
    correct_option TEXT NOT NULL CHECK (correct_option = ANY(options)),
    explanation TEXT NOT NULL,
    difficulty_level INTEGER NOT NULL CHECK (difficulty_level BETWEEN 1 AND 4),
    topic VARCHAR(100),
    is_static BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_by VARCHAR(255)
);

-- Indexes for efficient question filtering
CREATE INDEX IF NOT EXISTS idx_questions_difficulty ON questions(difficulty_level);
CREATE INDEX IF NOT EXISTS idx_questions_topic ON questions(topic);
CREATE INDEX IF NOT EXISTS idx_questions_static ON questions(is_static);

-- UserQuestions table: tracks questions sent to each user
CREATE TABLE IF NOT EXISTS user_questions (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    question_id VARCHAR(255) NOT NULL REFERENCES questions(id),
    telegram_message_id INTEGER NOT NULL,
    sent_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    answered_at TIMESTAMP WITH TIME ZONE,
    answer_received BOOLEAN NOT NULL DEFAULT FALSE,
    UNIQUE (user_id, sent_at::date)
);

CREATE INDEX IF NOT EXISTS idx_user_questions_user_date ON user_questions(user_id, sent_at::date);
CREATE INDEX IF NOT EXISTS idx_user_questions_answered ON user_questions(answered_at) WHERE answered_at IS NULL;

-- UserAnswers table: detailed answer records
CREATE TABLE IF NOT EXISTS user_answers (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    question_id VARCHAR(255) NOT NULL REFERENCES questions(id),
    user_question_id INTEGER NOT NULL REFERENCES user_questions(id) ON DELETE CASCADE,
    selected_option TEXT NOT NULL,
    is_correct BOOLEAN NOT NULL,
    time_taken_seconds INTEGER,
    answered_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    difficulty_level INTEGER NOT NULL CHECK (difficulty_level BETWEEN 1 AND 4),
    streak_before INTEGER NOT NULL CHECK (streak_before >= 0),
    streak_after INTEGER NOT NULL CHECK (streak_after >= 0)
);

CREATE INDEX IF NOT EXISTS idx_user_answers_user ON user_answers(user_id);
CREATE INDEX IF NOT EXISTS idx_user_answers_correctness ON user_answers(is_correct);
CREATE INDEX IF NOT EXISTS idx_user_answers_date ON user_answers(answered_at::date);

-- StreakHistory table: tracks streak changes (for analytics)
CREATE TABLE IF NOT EXISTS streak_history (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    streak_date DATE NOT NULL,
    streak_value INTEGER NOT NULL CHECK (streak_value >= 0),
    streak_action VARCHAR(20) NOT NULL CHECK (streak_action IN ('increment', 'reset', 'maintain')),
    reason VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, streak_date)
);

CREATE INDEX IF NOT EXISTS idx_streak_history_user ON streak_history(user_id, streak_date);

-- TopicPerformance table: tracks performance per topic
CREATE TABLE IF NOT EXISTS topic_performance (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    topic VARCHAR(100) NOT NULL,
    questions_attempted INTEGER NOT NULL DEFAULT 0 CHECK (questions_attempted >= 0),
    questions_correct INTEGER NOT NULL DEFAULT 0 CHECK (questions_correct >= 0),
    last_attempted_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, topic)
);

CREATE INDEX IF NOT EXISTS idx_topic_performance_user ON topic_performance(user_id);

-- Views for analytics
CREATE OR REPLACE VIEW user_quiz_summary AS
SELECT 
    u.user_id,
    u.username,
    u.current_difficulty,
    u.current_streak,
    COUNT(DISTINCT ua.question_id) as total_answers,
    SUM(CASE WHEN ua.is_correct THEN 1 ELSE 0 END) as correct_answers,
    ROUND(SUM(CASE WHEN ua.is_correct THEN 1 ELSE 0 END)::numeric / 
          NULLIF(COUNT(DISTINCT ua.question_id), 0) * 100, 2) as accuracy_pct
FROM users u
LEFT JOIN user_answers ua ON u.user_id = ua.user_id
WHERE u.opt_in_daily_quiz = TRUE
GROUP BY u.user_id, u.username, u.current_difficulty, u.current_streak;

CREATE OR REPLACE VIEW daily_question_stats AS
SELECT 
    DATE(sent_at) as quiz_date,
    COUNT(DISTINCT user_id) as questions_sent,
    COUNT(DISTINCT CASE WHEN answered_at IS NOT NULL THEN user_id END) as answered,
    COUNT(DISTINCT CASE WHEN answered_at IS NULL THEN user_id END) as unanswered,
    ROUND(
        COUNT(DISTINCT CASE WHEN answered_at IS NOT NULL THEN user_id END)::numeric /
        NULLIF(COUNT(DISTINCT user_id), 0) * 100, 2
    ) as response_rate_pct
FROM user_questions
GROUP BY DATE(sent_at)
ORDER BY quiz_date DESC;

-- Functions and triggers
CREATE OR REPLACE FUNCTION update_user_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS users_update_timestamp ON users;
CREATE TRIGGER users_update_timestamp
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_user_timestamp();

DROP TRIGGER IF EXISTS topic_performance_update_timestamp ON topic_performance;

-- Function to get next question (avoiding repeats)
CREATE OR REPLACE FUNCTION get_next_adaptive_question(
    p_user_id VARCHAR,
    p_difficulty INTEGER,
    p_excluded_ids VARCHAR[] DEFAULT NULL
) RETURNS TABLE (
    question_id VARCHAR,
    question_text TEXT,
    options JSONB,
    correct_option TEXT,
    explanation TEXT,
    topic VARCHAR,
    difficulty_level INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT q.id, q.question_text, q.options, q.correct_option, q.explanation, q.topic, q.difficulty_level
    FROM questions q
    WHERE q.difficulty_level = p_difficulty
      AND (p_excluded_ids IS NULL OR NOT (q.id = ANY(p_excluded_ids)))
      AND NOT EXISTS (
          SELECT 1
          FROM user_answers ua
          WHERE ua.user_id = p_user_id AND ua.question_id = q.id
      )
    ORDER BY RANDOM()
    LIMIT 1;
END;
$$ LANGUAGE plpgsql STABLE;

-- Function to update topic performance
CREATE OR REPLACE FUNCTION update_topic_performance(
    p_user_id VARCHAR,
    p_question_id VARCHAR,
    p_is_correct BOOLEAN
) RETURNS VOID AS $$
DECLARE
    v_topic VARCHAR(100);
BEGIN
    SELECT topic INTO v_topic
    FROM questions
    WHERE id = p_question_id;
    
    IF v_topic IS NULL THEN
        RETURN;
    END IF;
    
    INSERT INTO topic_performance (user_id, topic, questions_attempted, questions_correct, last_attempted_at)
    VALUES (p_user_id, v_topic, 1, CASE WHEN p_is_correct THEN 1 ELSE 0 END, NOW())
    ON CONFLICT (user_id, topic) DO UPDATE
    SET 
        questions_attempted = topic_performance.questions_attempted + 1,
        questions_correct = topic_performance.questions_correct + 
            CASE WHEN p_is_correct THEN 1 ELSE 0 END,
        last_attempted_at = NOW(),
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql;

-- Seed data: Sample static questions (expand this to at least 10 per difficulty/topic)
-- BEGINNER (1)
INSERT INTO questions (id, question_text, options, correct_option, explanation, difficulty_level, topic, is_static, created_by) VALUES
('b_sql_001', 'Which SQL clause is used to filter rows in a SELECT statement?', 
 '["WHERE", "GROUP BY", "HAVING", "ORDER BY"]', 
 'WHERE',
 'WHERE clause filters individual rows before aggregation. HAVING filters after GROUP BY, while GROUP BY aggregates and ORDER BY sorts.',
 1, 'sql_performance', TRUE, 'system'),
('b_data_model_001', 'What is the primary purpose of a foreign key in a database?', 
 '["Ensure referential integrity", "Improve query performance", "Create indexes", "Encrypt data"]', 
 'Ensure referential integrity',
 'Foreign keys enforce relationships between tables, ensuring that referenced values exist. They can impact performance negatively but are essential for data consistency.',
 1, 'data_modeling', TRUE, 'system');

-- INTERMEDIATE (2)
INSERT INTO questions (id, question_text, options, correct_option, explanation, difficulty_level, topic, is_static, created_by) VALUES
('i_sql_001', 'Which index type is most effective for equality comparisons on a column with high cardinality?', 
 '["B-Tree", "Hash", "GIN", "BRIN"]', 
 'B-Tree',
 'B-Tree indexes are optimized for equality and range queries. Hash indexes only support equality, GIN for array/json, and BRIN for very large tables with sorted data.',
 2, 'sql_performance', TRUE, 'system'),
('i_streaming_001', 'In Apache Kafka, what determines message ordering guarantees within a partition?', 
 '["Producer timestamp", "Consumer offset", "Message key", "Broker ID"]', 
 'Message key',
 'Messages with the same key are written to the same partition in order. Within a partition, messages are strictly ordered by offset.',
 2, 'streaming', TRUE, 'system'),
('i_etl_001', 'What is the main advantage of ELT over ETL in modern data warehouses?', 
 '["Faster data loading", "Leverages warehouse compute for transformations", "Better data quality", "Simpler error handling"]', 
 'Leverages warehouse compute for transformations',
 'ELT loads data first, then transforms within the warehouse using its powerful compute engine, reducing ETL infrastructure complexity.',
 2, 'etl_vs_elt', TRUE, 'system'),
('i_orchestration_001', 'In Prefect, what is the primary difference between a Flow and a Task?', 
 '["Tasks can run independently, Flows orchestrate Tasks", "Flows are parallel, Tasks are sequential", "Tasks have state, Flows don''t", "No difference - they''re the same"]', 
 'Tasks can run independently, Flows orchestrate Tasks',
 'Tasks are units of work that can be executed independently. Flows are orchestrations that define the dependency graph between tasks and manage their execution.',
 2, 'orchestration', TRUE, 'system'),
('i_data_quality_001', 'Which data quality dimension refers to the conformity of data to defined rules and standards?', 
 '["Accuracy", "Completeness", "Consistency", "Validity"]', 
 'Validity',
 'Validity checks if data conforms to defined formats, types, and rules (e.g., email format, age range). Accuracy is about correctness, completeness about missing values, and consistency across sources.',
 2, 'data_quality', TRUE, 'system'),
('i_observability_001', 'What is the primary purpose of structured logging in data pipelines?', 
 '["Reduce log file size", "Enable automated log parsing and analysis", "Improve write performance", "Replace monitoring tools"]', 
 'Enable automated log parsing and analysis',
 'Structured logging (JSON) allows tools to parse, search, and analyze logs programmatically. This enables alerting, debugging, and metrics extraction from logs.',
 2, 'observability', TRUE, 'system');

-- ADVANCED (3)
INSERT INTO questions (id, question_text, options, correct_option, explanation, difficulty_level, topic, is_static, created_by) VALUES
('a_sql_001', 'In PostgreSQL, which index type would be best for a JSONB column containing arrays for fast containment searches?', 
 '["B-Tree", "GIN", "BRIN", "Hash"]', 
 'GIN',
 'GIN (Generalized Inverted Index) is designed for array and JSONB containment operations (@>, &&). B-Tree doesn''t support containment, BRIN is for sorted ranges, Hash only supports equality.',
 3, 'sql_performance', TRUE, 'system'),
('a_distributed_001', 'In a distributed hash-partitioned database, what happens when a node fails during a query?', 
 '["Query fails completely", "Only affected partitions are unavailable", "Query continues using data from replicas", "All nodes must be restarted"]', 
 'Query continues using data from replicas',
 'With replication, queries can read from replicas if the primary is down. Without replicas, only partitions on the failed node become unavailable (partial results).',
 3, 'distributed_systems', TRUE, 'system'),
('a_lakehouse_001', 'What is the key architectural innovation of the Lakehouse pattern over traditional Data Lakes?', 
 '["Cheaper storage", "ACID transactions on object storage", "Better compression", "Faster ingestion"]', 
 'ACID transactions on object storage',
 'Lakehouses add a metadata layer (Delta Lake, Iceberg, Hudi) that provides ACID transactions, time travel, and schema enforcement on top of cheap object storage.',
 3, 'data_warehouse_lakehouse', TRUE, 'system'),
('a_streaming_001', 'In stream processing, what is ''exactly-once'' semantics?', 
 '["Each message processed exactly one time", "Each message processed at least once", "Each message processed at most once", "No guarantee about processing"]', 
 'Each message processed exactly one time',
 'Exactly-once ensures each message affects downstream state exactly once, achieved through idempotent operations, transaction logs, and coordination (e.g., Kafka Streams with KTable).',
 3, 'streaming', TRUE, 'system'),
('a_data_quality_001', 'What is the primary challenge with implementing data validation in distributed ETL pipelines?', 
 '["Performance overhead", "Coordination across workers", "Complexity of rules", "Storage cost"]', 
 'Coordination across workers',
 'Validation that requires global state (e.g., uniqueness across all data) is expensive in distributed systems. Worker-local validations are fast but may miss cross-partition issues.',
 3, 'data_quality', TRUE, 'system'),
('a_orchestration_001', 'What is the benefit of Prefect''s dynamic task mapping over traditional loops?', 
 '["No performance difference", "Parallel execution with dependency tracking", "Simpler syntax", "Only works locally"]', 
 'Parallel execution with dependency tracking',
 'Dynamic mapping (e.g., .map()) creates independent task runs for each input, enabling parallel execution with proper dependency tracking and retry semantics per mapped task.',
 3, 'orchestration', TRUE, 'system');

-- EXPERT (4)
INSERT INTO questions (id, question_text, options, correct_option, explanation, difficulty_level, topic, is_static, created_by) VALUES
('e_distributed_001', 'In Raft consensus, what ensures that only one leader can be elected per term?', 
 '["Unique term numbers", "Leader lease timeout", "Heartbeats from candidates", "Majority vote requirement"]', 
 'Majority vote requirement',
 'A candidate needs majority votes to become leader. Since there can only be one majority in a partitioned network, this prevents split-brain. Term numbers ensure old leaders step down.',
 4, 'distributed_systems', TRUE, 'system'),
('e_lakehouse_001', 'How do Delta Lake''s Z-order clustering and Apache Iceberg''s partition evolution differ?', 
 '["Z-order is for clustering, partition evolution for schema changes", "Delta requires manual partitioning, Iceberg is automatic", "No difference - same feature", "Delta doesn''t support partitioning"]', 
 'Z-order is for clustering, partition evolution for schema changes',
 'Z-order (Delta) clusters data across multiple columns for faster filtering. Partition evolution (Iceberg) allows changing partition layout without rewriting data - different optimizations.',
 4, 'data_warehouse_lakehouse', TRUE, 'system'),
('e_observability_001', 'When implementing distributed tracing, what is the trade-off between sampling rate and observability?', 
 '["No trade-off - always 100%", "High sampling = more data but higher cost", "Low sampling = faster traces", "Tracing requires no storage"]', 
 'High sampling = more data but higher cost',
 '100% sampling gives complete visibility but is expensive (ingestion, storage). Probabilistic sampling (e.g., 1%) balances cost while preserving signal for critical traces.',
 4, 'observability', TRUE, 'system'),
('e_data_model_001', 'In a multi-tenant SaaS system, what are the trade-offs between shared-schema and separate-database tenant isolation?', 
 '["Shared schema: better performance, harder migration; Separate DB: easier migration, higher cost", "Shared schema: cheaper, simpler; Separate DB: no benefits", "No difference - same pattern", "Separate DB always better"]', 
 'Shared schema: better performance, harder migration; Separate DB: easier migration, higher cost',
 'Shared schema pools resources efficiently but requires row-level security and careful migrations. Separate databases provide true isolation but are expensive and complex to manage at scale.',
 4, 'data_modeling', TRUE, 'system'),
('e_sql_001', 'How does PostgreSQL''s parallel query execution decide when to use parallel workers?', 
 '["Always enabled for large tables", "Based on cost estimates and configuration (max_parallel_workers)", "Manual hint required", "Never uses parallelism"]', 
 'Based on cost estimates and configuration (max_parallel_workers)',
 'The planner compares parallel vs serial costs. It uses parallel workers if parallel cost is lower, table is large enough, and max_parallel_workers_per_gather allows it. Not all plans support parallelism.',
 4, 'sql_performance', TRUE, 'system'),
('e_streaming_001', 'What is the correctness issue with using event time processing without watermarks in streaming systems?', 
 '["No issue - always correct", "Late data can cause incorrect results if not handled", "Watermarks only affect latency", "Event time is impossible"]', 
 'Late data can cause incorrect results if not handled',
 'Without watermarks, the system can''t distinguish late data from missing data, potentially triggering early/wrong aggregations. Watermarks define a threshold for considering data late.',
 4, 'streaming', TRUE, 'system');

-- Grant permissions (adjust as needed)
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO quiz_app;
-- GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO quiz_app;
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO quiz_app;

-- Add comments for documentation
COMMENT ON TABLE users IS 'Quiz participants with state for adaptive difficulty';
COMMENT ON TABLE questions IS 'Question bank with static and LLM-generated questions';
COMMENT ON TABLE user_questions IS 'Questions sent to users (one per day)';
COMMENT ON TABLE user_answers IS 'Detailed answer records for analytics';
COMMENT ON TABLE streak_history IS 'Historical streak changes for analysis';
COMMENT ON TABLE topic_performance IS 'Per-topic performance metrics per user';

COMMENT ON COLUMN users.current_difficulty IS '1=Beginner, 2=Intermediate, 3=Advanced, 4=Expert';
COMMENT ON COLUMN users.consecutive_correct IS 'Consecutive correct answers (resets on incorrect)';
COMMENT ON COLUMN questions.is_static IS 'True for hardcoded questions, False for LLM-generated';
